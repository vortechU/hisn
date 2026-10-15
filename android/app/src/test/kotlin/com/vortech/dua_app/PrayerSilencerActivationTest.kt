package com.vortech.dua_app

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.service.notification.Condition
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowAlarmManager
import org.robolectric.shadows.ShadowNotificationManager
import java.util.Calendar
import java.util.TimeZone

/** Observe the Android boundary while executing the production silencer unchanged.
 * The shadow supplies the OS-owned rule-state endpoint; it does not calculate
 * prayer windows, register end protection, or decide when to activate.
 */
@Implements(NotificationManager::class)
class SilenceRecordingNotificationManager : ShadowNotificationManager() {
    data class Alarm(val action: String?, val deadline: Long, val window: Long)
    data class Publication(val id: String, val state: Int, val guards: List<Alarm>)

    @Implementation(minSdk = 29)
    public override fun setAutomaticZenRuleState(id: String, condition: Condition) {
        val context: Context = RuntimeEnvironment.getApplication()
        val alarms = context.getSystemService(AlarmManager::class.java)
        val guards = shadowOf(alarms).scheduledAlarms.map {
            Alarm(it.operation?.let { operation -> shadowOf(operation).savedIntent.action },
                it.triggerAtMs, it.windowLengthMs)
        }
        publications.add(Publication(id, condition.state, guards))
        super.setAutomaticZenRuleState(id, condition)
    }

    companion object { val publications = mutableListOf<Publication>() }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [31], shadows = [SilenceRecordingNotificationManager::class],
    instrumentedPackages = ["com.vortech.dua_app"])
class PrayerSilencerActivationTest {
    private lateinit var context: Context
    private lateinit var manager: NotificationManager
    private lateinit var alarms: AlarmManager
    private lateinit var originalZone: TimeZone
    private var fajr = 0L
    private val publications get() = SilenceRecordingNotificationManager.publications
    private val store get() = context.getSharedPreferences("prayer_silence_native", Context.MODE_PRIVATE)
    private val deadline get() = fajr + 50 * 60_000L

    @Before fun setup() {
        originalZone = TimeZone.getDefault()
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Riyadh"))
        context = RuntimeEnvironment.getApplication()
        manager = context.getSystemService(NotificationManager::class.java)
        alarms = context.getSystemService(AlarmManager::class.java)
        store.edit().clear().commit()
        PrayerWidget.prefs(context).edit().clear().putString("lat", "24.7136")
            .putString("lng", "46.6753").putString("method", "umm_al_qura")
            .putString("madhab", "shafi").commit()
        shadowOf(manager).setNotificationPolicyAccessGranted(true)
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        ShadowAlarmManager.setAutoSchedule(false)
        publications.clear()
        setPlaying(false)
        val day = Calendar.getInstance().apply {
            clear(); set(2026, Calendar.OCTOBER, 15, 0, 0)
        }.time
        SystemClock.setCurrentTimeMillis(day.time)
        fajr = PrayerWidget.prayersOn(context, day).single { it.first == "fajr" }.second
        SystemClock.setCurrentTimeMillis(fajr + 10 * 60_000L)
    }

    @After fun teardown() { setPlaying(false); TimeZone.setDefault(originalZone) }

    private fun setPlaying(value: Boolean) {
        AdhanPlayerService::class.java.getDeclaredField("isPlaying").apply {
            isAccessible = true
        }.setBoolean(null, value)
    }

    private fun update(enabled: Boolean = true, name: String = "Prayer silence") =
        PrayerSilencer.update(context, mapOf("enabled" to enabled, "ruleName" to name,
            "windows" to mapOf("fajr" to mapOf("enabled" to true, "start" to 0, "end" to 50))))

    private fun endGuardIds() = shadowOf(alarms).scheduledAlarms.mapNotNull {
        it.operation?.let { operation -> shadowOf(operation).savedIntent.action }
    }.filter { it.endsWith("_74101") || it.endsWith("_74102") }

    @Test fun actualActivationArmsDistinctExactAndBackupEndsBeforePublishingTrue() {
        val result = update()
        assertEquals("active", result["reason"])
        assertEquals(deadline, result["activeUntil"])
        val active = publications.single { it.state == Condition.STATE_TRUE }
        assertEquals(store.getString("owned_rule", null), active.id)
        val exact = active.guards.single { it.action?.endsWith("_74101") == true }
        val backup = active.guards.single { it.action?.endsWith("_74102") == true }
        assertEquals(deadline, exact.deadline)
        assertEquals(deadline, backup.deadline)
        assertEquals(0L, exact.window)
        assertNotEquals(0L, backup.window)
    }

    @Test fun actualEndAndDelayedDuplicateBroadcastCannotReactivateExpiredWindow() {
        update()
        SystemClock.setCurrentTimeMillis(deadline)
        PrayerSilenceReceiver().onReceive(context, Intent("end"))
        assertEquals(Condition.STATE_FALSE, publications.last().state)
        assertNull(PrayerSilencer.status(context)["activeUntil"])
        assertTrue(endGuardIds().isEmpty())
        publications.clear()
        SystemClock.setCurrentTimeMillis(deadline + 60_000L)
        PrayerSilenceReceiver().onReceive(context, Intent("late-start"))
        assertTrue(publications.none { it.state == Condition.STATE_TRUE })
        assertTrue(shadowOf(alarms).scheduledAlarms.all { it.triggerAtMs > System.currentTimeMillis() })
    }

    @Test fun disableRemovesOnlyHisnRuleAndPreservesManualAndForeignDnd() {
        val foreign = manager.addAutomaticZenRule(AutomaticZenRule("Meeting",
            ComponentName(context.packageName, "ForeignConditionProvider"),
            Uri.parse("condition://other/meeting"), NotificationManager.INTERRUPTION_FILTER_NONE, true))
        manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
        update()
        val owned = store.getString("owned_rule", null)!!
        assertNotEquals(foreign, owned)
        assertEquals(NotificationManager.INTERRUPTION_FILTER_PRIORITY, manager.currentInterruptionFilter)
        update(false)
        assertNull(manager.getAutomaticZenRule(owned))
        assertNotNull(manager.getAutomaticZenRule(foreign))
        assertEquals(NotificationManager.INTERRUPTION_FILTER_PRIORITY, manager.currentInterruptionFilter)
        assertTrue(shadowOf(alarms).scheduledAlarms.isEmpty())
        assertEquals(Condition.STATE_FALSE, publications.last().state)
    }

    @Test fun exactAccessLossDeactivatesAnExistingRuleAndLeavesNoStartAlarm() {
        update()
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        PrayerSilencer.refresh(context)
        assertEquals("exactAlarm", PrayerSilencer.status(context)["reason"])
        assertEquals(Condition.STATE_FALSE, publications.last().state)
        assertNull(PrayerSilencer.status(context)["activeUntil"])
        assertTrue(shadowOf(alarms).scheduledAlarms.isEmpty())
    }

    @Test fun skipCurrentSurvivesLocaleUpdateAndClosedAppRecovery() {
        update()
        PrayerSilencer.skipCurrent(context)
        publications.clear()
        update(name = "الصامت وقت الصلاة")
        PrayerSilenceReceiver().onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
        assertTrue(publications.none { it.state == Condition.STATE_TRUE })
        assertNull(PrayerSilencer.status(context)["activeUntil"])
        assertTrue(endGuardIds().isEmpty())
        assertEquals(deadline, store.getLong("skip_until", 0))
    }

    @Test fun adhanWaitsAndFinishingAfterDeadlineDoesNotActivate() {
        setPlaying(true)
        val result = update()
        assertEquals("waiting", result["reason"])
        assertTrue(publications.none { it.state == Condition.STATE_TRUE })
        assertTrue(endGuardIds().isEmpty())
        SystemClock.setCurrentTimeMillis(deadline + 1)
        setPlaying(false)
        PrayerSilencer.refresh(context)
        assertTrue(publications.none { it.state == Condition.STATE_TRUE })
        assertNull(PrayerSilencer.status(context)["activeUntil"])
    }
}
