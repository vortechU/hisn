package com.vortech.dua_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Schedules / cancels the exact alarms that trigger [AdhanAlarmReceiver]. The
 * Flutter side computes the prayer times and passes them down; we persist the
 * full alarm payloads so they can be re-armed after a reboot or app update (see
 * [BootReceiver]) — AlarmManager alarms do not survive a reboot on their own.
 */
object AdhanScheduler {
    private const val TAG = "AdhanScheduler"
    private const val PREFS = "adhan_alarms"
    private const val KEY_ALARMS = "alarms_json"

    /** (Re)schedule the given set of alarms, replacing any previously set. */
    fun schedule(context: Context, alarms: List<Map<String, Any>>) {
        cancelAll(context)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val stored = JSONArray()
        for (a in alarms) {
            val id = (a["id"] as? Number)?.toInt() ?: continue
            val at = (a["at"] as? Number)?.toLong() ?: continue
            val fajr = a["fajr"] as? Boolean ?: false
            val usage = a["usage"] as? String ?: "notification"
            if (setAlarm(context, am, id, at, fajr, usage)) {
                stored.put(
                    JSONObject()
                        .put("id", id)
                        .put("at", at)
                        .put("fajr", fajr)
                        .put("usage", usage)
                )
            }
        }
        prefs(context).edit().putString(KEY_ALARMS, stored.toString()).apply()
    }

    /** Re-arm any persisted alarms still in the future (called after a reboot). */
    fun rearmFuture(context: Context) {
        val raw = prefs(context).getString(KEY_ALARMS, null) ?: return
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        var rearmed = 0
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val at = o.getLong("at")
                if (at <= now) continue
                if (setAlarm(
                        context, am,
                        o.getInt("id"), at,
                        o.optBoolean("fajr", false),
                        o.optString("usage", "notification")
                    )
                ) rearmed++
            }
        } catch (e: Exception) {
            Log.e(TAG, "rearmFuture failed", e)
        }
        Log.i(TAG, "rearmFuture re-armed $rearmed alarm(s)")
    }

    fun cancelAll(context: Context) {
        val raw = prefs(context).getString(KEY_ALARMS, null)
        if (raw != null) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            try {
                val arr = JSONArray(raw)
                for (i in 0 until arr.length()) {
                    val id = arr.getJSONObject(i).getInt("id")
                    val pi = PendingIntent.getBroadcast(
                        context, id,
                        Intent(context, AdhanAlarmReceiver::class.java),
                        PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                    )
                    if (pi != null) am.cancel(pi)
                }
            } catch (_: Exception) {
            }
        }
        prefs(context).edit().remove(KEY_ALARMS).apply()
    }

    /** Sets one exact alarm. Returns true if it was scheduled. */
    private fun setAlarm(
        context: Context,
        am: AlarmManager,
        id: Int,
        at: Long,
        fajr: Boolean,
        usage: String,
    ): Boolean {
        val pi = PendingIntent.getBroadcast(
            context, id,
            Intent(context, AdhanAlarmReceiver::class.java).apply {
                putExtra(AdhanPlayerService.EXTRA_FAJR, fajr)
                putExtra(AdhanPlayerService.EXTRA_USAGE, usage)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !am.canScheduleExactAlarms()
            ) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            } else {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "setAlarm($id) failed", e)
            false
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
