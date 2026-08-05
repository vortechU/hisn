package com.vortech.dua_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fired by AlarmManager at a prayer time. Starts the foreground service that
 * plays the adhan. (An exact alarm grants a brief allow-list window so starting
 * a foreground service from the background is permitted here.)
 */
class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val fajr = intent.getBooleanExtra(AdhanPlayerService.EXTRA_FAJR, false)
        val usage = intent.getStringExtra(AdhanPlayerService.EXTRA_USAGE) ?: "notification"
        AdhanPlayerService.start(context, fajr, usage)
        // A prayer just began — advance the home-screen widget's highlight.
        PrayerWidget.refresh(context)
    }
}
