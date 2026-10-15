package com.vortech.dua_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class PrayerSilenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // AlarmManager alarms vanish at reboot and may change with clock/timezone.
        // Recompute from persisted coordinates, never replay yesterday's start.
        if (Build.VERSION.SDK_INT >= 24) PrayerSilencer.refresh(context, resetAlarms = true)
    }
}
