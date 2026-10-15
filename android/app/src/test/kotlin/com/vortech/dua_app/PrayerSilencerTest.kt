package com.vortech.dua_app

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** Safety behavior of Android-owned scheduling without a Flutter engine. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class PrayerSilencerTest {
    private lateinit var context: Context
    private lateinit var manager: NotificationManager

    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        manager = context.getSystemService(NotificationManager::class.java)
        context.getSharedPreferences("prayer_silence_native", Context.MODE_PRIVATE).edit().clear().commit()
        PrayerWidget.prefs(context).edit().clear().commit()
        shadowOf(manager).setNotificationPolicyAccessGranted(true)
    }

    @Test fun disabledConfigPreservesForeignRuleAndManualDnd() {
        val owner = ComponentName(context.packageName, "ForeignConditionProvider")
        val foreign = manager.addAutomaticZenRule(AutomaticZenRule("Other schedule", owner,
            Uri.parse("condition://other/meeting"), NotificationManager.INTERRUPTION_FILTER_NONE, true))
        manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
        val result = PrayerSilencer.update(context, mapOf("enabled" to false))
        assertEquals("disabled", result["reason"])
        assertNotNull(manager.getAutomaticZenRule(foreign))
        assertEquals(NotificationManager.INTERRUPTION_FILTER_PRIORITY, manager.currentInterruptionFilter)
        assertNull(context.getSharedPreferences("prayer_silence_native", Context.MODE_PRIVATE)
            .getString("owned_rule", null))
        assertTrue(shadowOf(context.getSystemService(AlarmManager::class.java)).scheduledAlarms.isEmpty())
    }

    @Test fun missingPolicyAccessCreatesNoRuleOrAlarm() {
        shadowOf(manager).setNotificationPolicyAccessGranted(false)
        val result = PrayerSilencer.update(context, mapOf("enabled" to true,
            "windows" to mapOf("fajr" to mapOf("enabled" to true, "start" to 0, "end" to 50))))
        assertEquals("permission", result["reason"])
        assertNull(result["activeUntil"])
        assertTrue(shadowOf(context.getSystemService(AlarmManager::class.java)).scheduledAlarms.isEmpty())
    }

    @Test fun absentLocationCreatesNoRuleOrAlarm() {
        val result = PrayerSilencer.update(context, mapOf("enabled" to true,
            "windows" to mapOf("fajr" to mapOf("enabled" to true, "start" to 0, "end" to 50))))
        assertEquals("location", result["reason"])
        assertNull(result["activeUntil"])
        assertTrue(manager.automaticZenRules.isEmpty())
        assertTrue(shadowOf(context.getSystemService(AlarmManager::class.java)).scheduledAlarms.isEmpty())
    }
}
