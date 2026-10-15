package com.vortech.dua_app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAlarmManager
import java.util.Calendar
import java.util.Date
import java.util.TimeZone
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/** Exercise the actual Android posting/alarm path without a Flutter engine. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [31])
class PrayerCountdownTest {
    private lateinit var context: Context
    private lateinit var notifications: NotificationManager
    private lateinit var alarms: AlarmManager
    private lateinit var originalZone: TimeZone

    @Before fun setUp() {
        context = RuntimeEnvironment.getApplication()
        notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        originalZone = TimeZone.getDefault()
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Riyadh"))
        context.getSharedPreferences("prayer_countdown", 0).edit().clear().commit()
        PrayerWidget.prefs(context).edit().clear().putString("lat", "24.7136")
            .putString("lng", "46.6753").putString("method", "umm_al_qura")
            .putString("madhab", "shafi").commit()
        shadowOf(notifications).setNotificationsEnabled(true)
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
    }

    @After fun tearDown() { TimeZone.setDefault(originalZone) }

    private fun at(hour: Int, minute: Int = 0): Date = Calendar.getInstance().apply {
        clear()
        set(2026, Calendar.OCTOBER, 15, hour, minute)
    }.time

    private fun enable() {
        PrayerCountdown.update(context, mapOf("enabled" to true,
            "titlePrefix" to "Next", "remainingLabel" to "Remaining"))
    }

    private fun posted(): Notification? = shadowOf(notifications).getNotification(98123)

    @Test fun optInPostsOneSilentExpiringCountdownAndOneBoundaryAlarm() {
        enable()
        val now = at(12)
        PrayerCountdown.refresh(context, now)
        val expected = PrayerWidget.compute(context, now).nextTime!!.time
        val notification = posted()!!
        assertEquals(expected, notification.`when`)
        assertEquals(expected - now.time, notification.timeoutAfter)
        assertTrue(notification.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertTrue(notification.extras.getBoolean(Notification.EXTRA_CHRONOMETER_COUNT_DOWN))
        assertTrue(notification.flags and Notification.FLAG_ONGOING_EVENT != 0)
        val channel = notifications.getNotificationChannel(notification.channelId)
        assertEquals(NotificationManager.IMPORTANCE_LOW, channel.importance)
        assertNull(channel.sound)
        assertFalse(channel.shouldVibrate())
        val scheduled = shadowOf(alarms).scheduledAlarms
        assertEquals(1, scheduled.size)
        assertEquals(expected, scheduled.single().triggerAtMs)
        assertEquals(AlarmManager.RTC_WAKEUP, scheduled.single().type)
        assertEquals(0L, scheduled.single().intervalMs)
    }

    @Test fun noExactAlarmGrantUsesInexactBoundaryWithoutOpeningPermissionUi() {
        enable()
        val alarm = shadowOf(alarms).scheduledAlarms.single()
        assertNotEquals(ShadowAlarmManager.WINDOW_EXACT.toLong(), alarm.windowLengthMs)
        assertTrue(alarm.isAllowWhileIdle)
        assertNull(shadowOf(context as android.app.Application).nextStartedActivity)
        assertNotNull(posted())
    }

    @Test fun anExistingExactAlarmGrantUsesOneExactBoundary() {
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        enable()
        assertEquals(ShadowAlarmManager.WINDOW_EXACT.toLong(),
            shadowOf(alarms).scheduledAlarms.single().windowLengthMs)
    }

    @Test fun denialCancelsNotificationAndAlarmButKeepsOptIn() {
        enable()
        shadowOf(notifications).setNotificationsEnabled(false)
        PrayerCountdown.refresh(context)
        assertNull(posted())
        assertTrue(shadowOf(alarms).scheduledAlarms.isEmpty())
        assertTrue(context.getSharedPreferences("prayer_countdown", 0).getBoolean("enabled", false))
        shadowOf(notifications).setNotificationsEnabled(true)
        PrayerCountdown.refresh(context)
        assertNotNull(posted())
    }

    @Test fun disableCancelsAndAStaleBoundaryCannotResurrectNotification() {
        enable()
        PrayerCountdown.update(context, mapOf("enabled" to false))
        PrayerCountdownReceiver().onReceive(context, Intent(PrayerCountdown.ACTION_BOUNDARY))
        assertNull(posted())
        assertTrue(shadowOf(alarms).scheduledAlarms.isEmpty())
    }

    @Test fun disablingWaitsForAnInFlightWidgetRefreshAndCancelsItsResult() {
        enable()
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val blockedContext = object : ContextWrapper(context) {
            override fun getSystemService(name: String): Any? {
                if (name == Context.NOTIFICATION_SERVICE) {
                    entered.countDown()
                    check(release.await(5, TimeUnit.SECONDS))
                }
                return super.getSystemService(name)
            }
        }
        val executor = Executors.newFixedThreadPool(2)
        try {
            val refresh = executor.submit { PrayerCountdown.refresh(blockedContext) }
            assertTrue(entered.await(5, TimeUnit.SECONDS))
            val disable = executor.submit {
                PrayerCountdown.update(context, mapOf("enabled" to false))
            }
            try {
                disable.get(100, TimeUnit.MILLISECONDS)
                fail("Disable must wait for the refresh to finish before canceling it")
            } catch (_: TimeoutException) {
                // The preference change and cancellation share the refresh lock.
            }
            release.countDown()
            refresh.get(5, TimeUnit.SECONDS)
            disable.get(5, TimeUnit.SECONDS)
            assertNull(posted())
            assertTrue(shadowOf(alarms).scheduledAlarms.isEmpty())
        } finally {
            release.countDown()
            executor.shutdownNow()
        }
    }

    @Test fun afterIshaCountsToTomorrowFajrAndMidnightKeepsTheSameFajr() {
        enable()
        val late = at(23, 59)
        PrayerCountdown.refresh(context, late)
        val fajr = posted()!!.`when`
        assertEquals(0, PrayerWidget.compute(context, late).nextIndex)
        val tomorrow = Calendar.getInstance().apply { time = late; add(Calendar.DAY_OF_MONTH, 1) }
        val target = Calendar.getInstance().apply { timeInMillis = fajr }
        assertEquals(tomorrow.get(Calendar.DAY_OF_YEAR), target.get(Calendar.DAY_OF_YEAR))
        tomorrow.set(Calendar.HOUR_OF_DAY, 0)
        tomorrow.set(Calendar.MINUTE, 1)
        PrayerCountdown.refresh(context, tomorrow.time)
        assertEquals(fajr, posted()!!.`when`)
        assertTrue(posted()!!.timeoutAfter > 0)
    }

    @Test fun repeatedNativeCalculationKeepsStableWholeSecondPrayerBoundaries() {
        val late = at(23, 59)
        val first = PrayerWidget.compute(context, late)
        repeat(3) {
            val again = PrayerWidget.compute(context, late)
            assertEquals(first.times, again.times)
            assertEquals(first.nextTime, again.nextTime)
            assertEquals(first.lastTime, again.lastTime)
            val daily = PrayerWidget.prayersOn(context, late).map { it.second }
            assertEquals(first.times!!.map { it.time }, daily)
            assertTrue(daily.all { it % 1_000L == 0L })
            assertEquals(0L, again.nextTime!!.time % 1_000L)
            assertEquals(0L, again.lastTime!!.time % 1_000L)
        }
        val beforeFajr = PrayerWidget.compute(context, at(0, 1))
        assertEquals(0L, beforeFajr.lastTime!!.time % 1_000L)
    }

    @Test fun aDeferredBoundaryRefreshReplacesExpiredPrayerWithAFutureOne() {
        enable()
        PrayerCountdown.refresh(context, at(12))
        val expiredAt = posted()!!.`when`
        val deliveredAt = Date(expiredAt + 15 * 60_000L)
        PrayerCountdown.refresh(context, deliveredAt)
        assertTrue(posted()!!.`when` > deliveredAt.time)
        // Timeout equals the remaining duration exactly; no negative grace time.
        assertEquals(posted()!!.`when` - deliveredAt.time, posted()!!.timeoutAfter)
        assertEquals(1, shadowOf(alarms).scheduledAlarms.size)
    }

    @Test fun closedAppBootTimeAndLocaleBroadcastsRecoverWithoutFlutter() {
        enable()
        val receiver = PrayerCountdownReceiver()
        for (action in listOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED, Intent.ACTION_CONFIGURATION_CHANGED)) {
            notifications.cancel(98123)
            receiver.onReceive(context, Intent(action))
            assertNotNull(action, posted())
            assertEquals(action, 1, shadowOf(alarms).scheduledAlarms.size)
        }
    }

    @Test fun timezoneChangeRecomputesNextPrayerAndReplacesOldAlarm() {
        enable()
        val instant = at(23)
        PrayerCountdown.refresh(context, instant)
        TimeZone.setDefault(TimeZone.getTimeZone("America/New_York"))
        PrayerCountdown.refresh(context, instant)
        val expected = PrayerWidget.compute(context, instant).nextTime!!.time
        assertEquals(expected, posted()!!.`when`)
        assertEquals(expected, shadowOf(alarms).scheduledAlarms.single().triggerAtMs)
        assertTrue(expected > instant.time)
    }

    @Test fun missingAndInvalidLocationRemovePreviouslyPostedCountdown() {
        enable()
        PrayerWidget.prefs(context).edit().remove("lat").commit()
        PrayerCountdown.refresh(context)
        assertNull(posted())
        assertTrue(shadowOf(alarms).scheduledAlarms.isEmpty())
        PrayerWidget.prefs(context).edit().putString("lat", "NaN").commit()
        PrayerCountdown.refresh(context)
        assertNull(posted())
    }

    @Test fun prayerConfigChangeRefreshesLabelsButAnUnrelatedWidgetCounterDoesNot() {
        enable()
        PrayerCountdown.onPrayerConfigChanged(context)
        val previous = posted()!!
        PrayerWidget.prefs(context).edit().putString("tasbih_count", "15").commit()
        PrayerCountdown.onPrayerConfigChanged(context)
        assertSame(previous, posted())
        for (key in listOf("name_fajr", "name_dhuhr", "name_asr", "name_maghrib", "name_isha")) {
            PrayerWidget.prefs(context).edit().putString(key, "Localized prayer").commit()
        }
        PrayerCountdown.onPrayerConfigChanged(context)
        assertEquals("Next: Localized prayer", posted()!!.extras.getString(Notification.EXTRA_TITLE))
        assertEquals(1, shadowOf(alarms).scheduledAlarms.size)
    }

    @Test @Config(sdk = [24]) fun android7ShowsStaticPrayerTimeWithoutAnUnexpiringChronometer() {
        enable()
        val notification = posted()!!
        assertFalse(notification.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertFalse(notification.extras.getBoolean(Notification.EXTRA_CHRONOMETER_COUNT_DOWN))
    }
}
