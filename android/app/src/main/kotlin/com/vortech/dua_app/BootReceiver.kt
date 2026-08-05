package com.vortech.dua_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms the persisted adhan alarms after the device reboots or the app is
 * updated. AlarmManager clears all alarms on reboot, so without this the adhan
 * would stop firing until the user next opened the app.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON" ->
                AdhanScheduler.rearmFuture(context)
        }
    }
}
