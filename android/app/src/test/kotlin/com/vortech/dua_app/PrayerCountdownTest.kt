package com.vortech.dua_app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.view.View
import android.widget.Chronometer
import android.widget.FrameLayout
import android.widget.TextView
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
            "titlePrefix" to "Next", "remainingLabel" to "Remaining",
            "sinceLabel" to "Since adhan"))
    }

    private fun posted(): Notification? = shadowOf(notifications).getNotification(98123)

    /** The body as System UI would inflate it. */
    private fun body(notification: Notification): View =
        notification.contentView.apply(context, FrameLayout(context))

    private fun clock(notification: Notification): Chronometer =
        body(notification).findViewById(R.id.countdown_clock)

    private fun label(notification: Notification): String =
        body(notification).findViewById<TextView>(R.id.countdown_label).text.toString()

    private fun timeOf(index: Int, now: Date): Long =
        PrayerWidget.compute(context, now).times!![index].time

    @Test fun optInPostsOneSilentExpiringCountdownAndOneBoundaryAlarm() {
        enable()
        val now = at(13)
        PrayerCountdown.refresh(context, now)
        val expected = PrayerWidget.compute(context, now).nextTime!!.time
        val notification = posted()!!
        assertEquals(expected, notification.`when`)
        // Runs on past the adhan only for that prayer's 20-minute count-up.
        assertEquals(expected + 20 * 60_000L - now.time, notification.timeoutAfter)
        // The count sits in the body beside its label, not in the header.
        assertFalse(notification.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertEquals("Remaining", label(notification))
        assertEquals(View.VISIBLE, clock(notification).visibility)
        assertTrue(clock(notification).isCountDown)
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

    @Test fun aDeferredBoundaryRefreshTurnsTheCountdownIntoTheCountUp() {
        enable()
        PrayerCountdown.refresh(context, at(13))
        val adhan = posted()!!.`when`
        val deliveredAt = Date(adhan + 15 * 60_000L)
        PrayerCountdown.refresh(context, deliveredAt)
        assertEquals(adhan, posted()!!.`when`)
        assertFalse(clock(posted()!!).isCountDown)
        assertEquals(1, shadowOf(alarms).scheduledAlarms.size)
        // Delivered after the window too: straight to the next prayer.
        val later = Date(adhan + 25 * 60_000L)
        PrayerCountdown.refresh(context, later)
        assertTrue(posted()!!.`when` > later.time)
        assertTrue(clock(posted()!!).isCountDown)
    }

    @Test fun afterAnAdhanCountsUpThroughTheIqamahDelayThenDownToTheNextPrayer() {
        PrayerWidget.prefs(context).edit().putString("since_minutes_asr", "15").commit()
        enable()
        val asr = timeOf(2, at(13))
        val maghrib = timeOf(3, at(13))
        val during = Date(asr + 5 * 60_000L)
        PrayerCountdown.refresh(context, during)
        val since = posted()!!
        assertEquals("Asr", since.extras.getString(Notification.EXTRA_TITLE))
        assertEquals("Since adhan", label(since))
        assertEquals(asr, since.`when`)
        assertEquals(View.VISIBLE, clock(since).visibility)
        assertFalse(clock(since).isCountDown)
        // A count-up must not outlive the next adhan.
        assertEquals(maghrib - during.time, since.timeoutAfter)
        assertEquals(asr + 15 * 60_000L, shadowOf(alarms).scheduledAlarms.single().triggerAtMs)

        val after = Date(asr + 15 * 60_000L)
        PrayerCountdown.refresh(context, after)
        assertEquals("Next: Maghrib", posted()!!.extras.getString(Notification.EXTRA_TITLE))
        assertEquals(maghrib, posted()!!.`when`)
        assertTrue(clock(posted()!!).isCountDown)
        assertEquals(maghrib, shadowOf(alarms).scheduledAlarms.single().triggerAtMs)
    }

    @Test fun aLongIqamahDelayStillTurnsAtTheNextAdhan() {
        // Umm al-Qura calls Isha a fixed ninety minutes after Maghrib.
        PrayerWidget.prefs(context).edit().putString("since_minutes_maghrib", "120").commit()
        enable()
        val maghrib = timeOf(3, at(13))
        val isha = timeOf(4, at(13))
        assertTrue(isha - maghrib < 120 * 60_000L)
        PrayerCountdown.refresh(context, Date(maghrib + 60_000L))
        assertEquals(isha, shadowOf(alarms).scheduledAlarms.single().triggerAtMs)
    }

    @Test fun readsRightToLeftWhenTheAppIsInArabic() {
        PrayerWidget.prefs(context).edit().putString("lang", "ar")
            .putString("am", "ص").putString("pm", "م").commit()
        enable()
        PrayerCountdown.refresh(context, at(13))
        // Direction resolves only once the body is laid out in a parent.
        val parent = FrameLayout(context)
        val root = posted()!!.contentView.apply(context, parent)
        parent.addView(root)
        parent.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
        assertEquals(View.LAYOUT_DIRECTION_RTL, root.layoutDirection)
        assertTrue(posted()!!.extras.getCharSequence(Notification.EXTRA_TEXT)!!.endsWith(" م"))
    }

    @Test fun showsTheHijriDateAndTurnsAtMidnightForIt() {
        PrayerWidget.prefs(context).edit()
            .putString("hijri_months", (1..12).joinToString("|") { "Month$it" })
            .putString("hijri_suffix", "AH").commit()
        enable()
        val late = at(23)
        PrayerCountdown.refresh(context, late)
        val hijri = body(posted()!!).findViewById<TextView>(R.id.countdown_hijri).text.toString()
        assertTrue(hijri, Regex("""\d+ Month\d+ \d{4} AH""").matches(hijri))
        val midnight = Calendar.getInstance().apply {
            time = late
            add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
        }.timeInMillis
        assertEquals(midnight, shadowOf(alarms).scheduledAlarms.single().triggerAtMs)
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
        val face = PrayerCountdown.faceAt(context,
            PrayerWidget.compute(context, instant), instant.time)!!
        assertEquals(face.at, posted()!!.`when`)
        assertEquals(face.turnAt, shadowOf(alarms).scheduledAlarms.single().triggerAtMs)
        assertTrue(face.turnAt > instant.time)
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
        // Next or since, depending on the hour the test runs at.
        assertTrue(posted()!!.extras.getString(Notification.EXTRA_TITLE)!!.endsWith("Localized prayer"))
        assertEquals(1, shadowOf(alarms).scheduledAlarms.size)
    }

    @Test @Config(sdk = [24]) fun android7ShowsStaticPrayerTimeWithoutAnUnexpiringChronometer() {
        enable()
        PrayerCountdown.refresh(context, at(13))
        val notification = posted()!!
        assertEquals(View.GONE, clock(notification).visibility)
        assertTrue(notification.extras.getCharSequence(Notification.EXTRA_TEXT).toString()
            .matches(Regex("""Remaining · \d{1,2}:\d{2}( [AP]M)?""")))
    }
}
