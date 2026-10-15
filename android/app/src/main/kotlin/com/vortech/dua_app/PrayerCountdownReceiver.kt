package com.vortech.dua_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Re-arms one next-prayer boundary without starting Flutter or a service. */
class PrayerCountdownReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            PrayerCountdown.ACTION_BOUNDARY,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
            Intent.ACTION_CONFIGURATION_CHANGED,
            AlarmPermissionChanged -> PrayerCountdown.refresh(context)
        }
    }

    private companion object {
        // Existing exact-alarm settings can change without an app resume.
        const val AlarmPermissionChanged = "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED"
    }
}
