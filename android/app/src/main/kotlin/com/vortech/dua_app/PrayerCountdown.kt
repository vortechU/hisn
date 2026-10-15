package com.vortech.dua_app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.text.format.DateFormat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import java.util.Date

/** One optional silent notification; System UI owns the ticking chronometer. */
object PrayerCountdown {
    private const val PREFS = "prayer_countdown"
    private const val CHANNEL = "next_prayer_countdown"
    private const val NOTIFICATION_ID = 98123
    private const val ALARM_REQUEST = 98124
    const val ACTION_BOUNDARY = "com.vortech.dua_app.PRAYER_COUNTDOWN_BOUNDARY"

    private val configKeys = listOf(
        "lat", "lng", "method", "madhab", "name_fajr", "name_dhuhr",
        "name_asr", "name_maghrib", "name_isha", "am", "pm",
    )

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Called by hisn/prayer_countdown:update. No permission requests here. */
    @Synchronized
    fun update(context: Context, arguments: Map<*, *>?): Map<String, Any> {
        val values = requireNotNull(arguments) { "configuration is required" }
        require(values["enabled"] is Boolean) { "enabled must be a boolean" }
        val p = prefs(context)
        val editor = p.edit().putBoolean("enabled", values["enabled"] as Boolean)
        for (key in listOf("titlePrefix", "remainingLabel", "channelName", "channelDescription")) {
            (values[key] as? String)?.takeIf { it.isNotBlank() }?.let {
                editor.putString(key, it)
            }
        }
        editor.apply()
        refresh(context)
        return mapOf(
            "enabled" to p.getBoolean("enabled", false),
            "notificationsAllowed" to notificationsAllowed(context),
        )
    }

    /** Called after PrayerWidget.save; counter/theme pushes cause no work. */
    @Synchronized
    fun onPrayerConfigChanged(context: Context) {
        val source = PrayerWidget.prefs(context)
        val fingerprint = JSONArray(configKeys.map { source.getString(it, null) }).toString()
        val p = prefs(context)
        if (p.getString("prayerConfig", null) == fingerprint) return
        p.edit().putString("prayerConfig", fingerprint).apply()
        if (p.getBoolean("enabled", false)) refresh(context)
    }

    /** Recompute from coordinates on a boundary, clock/zone change or reboot. */
    @Synchronized
    fun refresh(context: Context, now: Date = Date()) {
        val p = prefs(context)
        if (!p.getBoolean("enabled", false)) {
            cancel(context)
            return
        }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                CHANNEL,
                p.getString("channelName", "Next prayer countdown"),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = p.getString("channelDescription", "Silent countdown to the next prayer")
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            })
        }
        if (!notificationsAllowed(context)) {
            cancel(context)
            return
        }
        val data = try { PrayerWidget.compute(context, now) } catch (_: Exception) {
            cancel(context)
            return
        }
        val next = data.nextTime
        if (next == null || next.time <= now.time || data.times == null) {
            cancel(context)
            return
        }
        // One prayer-boundary wakeup (five per day), never a ticking worker.
        // Android can defer the inexact fallback. Expiry removes an obsolete
        // countdown while that alarm is waiting for delivery.
        if (!scheduleBoundary(context, next.time)) {
            cancel(context)
            return
        }
        val name = data.names[data.nextIndex]
        val time = DateFormat.getTimeFormat(context).format(next)
        val prefix = p.getString("titlePrefix", "Next") ?: "Next"
        val remaining = p.getString("remainingLabel", "Remaining") ?: "Remaining"
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("$prefix: $name")
            .setContentText("$remaining · $time")
            .setWhen(next.time)
            .setShowWhen(true)
            // Android 7 cannot expire a notification. Keep its prayer time
            // static, so a deferred boundary never displays a negative count.
            .setUsesChronometer(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            .setChronometerCountDown(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            .setTimeoutAfter(next.time - now.time)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setLocalOnly(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .apply {
                WidgetChrome.open(context, WidgetChrome.ROUTE_PRAYER)?.let { setContentIntent(it) }
            }
            .build()
        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            cancel(context)
        }
    }

    private fun notificationsAllowed(context: Context): Boolean {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL)?.importance == NotificationManager.IMPORTANCE_NONE) {
                return false
            }
        }
        return true
    }

    private fun boundaryIntent(context: Context, flags: Int): PendingIntent? =
        PendingIntent.getBroadcast(
            context, ALARM_REQUEST,
            Intent(context, PrayerCountdownReceiver::class.java).setAction(ACTION_BOUNDARY),
            flags or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun scheduleBoundary(context: Context, at: Long): Boolean {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        val pending = boundaryIntent(context, PendingIntent.FLAG_UPDATE_CURRENT) ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !manager.canScheduleExactAlarms()) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            } else {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            }
            true
        } catch (_: SecurityException) {
            // A grant can be revoked between checking and scheduling.
            try {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
                true
            } catch (_: SecurityException) { false }
        }
    }

    private fun cancel(context: Context) {
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .cancel(NOTIFICATION_ID)
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        boundaryIntent(context, PendingIntent.FLAG_NO_CREATE)?.let { manager.cancel(it) }
    }
}
