package com.vortech.dua_app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.text.format.DateFormat
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * What the notification shows at one moment, and when that changes.
 *
 * Like the compact widget: for that prayer's iqāmah window after an adhan it
 * counts up from the prayer just called, otherwise down to the next one.
 */
internal data class CountdownFace(
    /** Counting up from the adhan of [index], rather than down to it. */
    val since: Boolean,
    /** The prayer shown (0..4, Fajr to Isha). */
    val index: Int,
    /** That prayer's adhan, the chronometer's base. */
    val at: Long,
    /** When the face next changes: the window's end, the adhan, or midnight. */
    val turnAt: Long,
    /** When the face is no longer true, should the turn be delivered late. */
    val expireAt: Long,
)

/** One optional silent notification; System UI owns the ticking chronometer. */
object PrayerCountdown {
    private const val PREFS = "prayer_countdown"
    private const val CHANNEL = "next_prayer_countdown"
    private const val NOTIFICATION_ID = 98123
    private const val ALARM_REQUEST = 98124
    const val ACTION_BOUNDARY = "com.vortech.dua_app.PRAYER_COUNTDOWN_BOUNDARY"

    private val configKeys = listOf(
        "lat", "lng", "method", "madhab", "name_fajr", "name_dhuhr",
        "name_asr", "name_maghrib", "name_isha", "am", "pm", "lang",
        "since_minutes_fajr", "since_minutes_dhuhr", "since_minutes_asr",
        "since_minutes_maghrib", "since_minutes_isha",
        "hijri", "hijri_months", "hijri_suffix", "hijri_offset",
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
        for (key in listOf("titlePrefix", "remainingLabel", "sinceLabel", "channelName", "channelDescription")) {
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
        val face = faceAt(context, data, now.time)
        if (face == null) {
            cancel(context)
            return
        }
        // One wakeup per turn (about eleven a day), never a ticking worker.
        // Android can defer the inexact fallback; expiry removes the face
        // once it would be wrong, while that alarm waits for delivery.
        if (!scheduleBoundary(context, face.turnAt)) {
            cancel(context)
            return
        }
        val name = data.names[face.index]
        val time = clockTime(context, data, face.at)
        val title = if (face.since) name else {
            "${p.getString("titlePrefix", "Next") ?: "Next"}: $name"
        }
        val label = (if (face.since) {
            p.getString("sinceLabel", "Since adhan") ?: "Since adhan"
        } else {
            p.getString("remainingLabel", "Remaining") ?: "Remaining"
        }).replaceFirstChar { it.titlecase() }
        // A count-up never runs negative, so every version may show one. A
        // count-down needs Android 8 to expire it: Android 7 keeps the prayer
        // time static instead, so a deferred turn never shows a negative count.
        val ticking = face.since || Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
        // The system template can only tick in the header, small and beside
        // the app name; this puts the count in the body, next to its label.
        val body = RemoteViews(context.packageName, R.layout.prayer_countdown_notification).apply {
            // The app's language, not the phone's, decides which way it reads.
            WidgetChrome.applyDirection(context, this, R.id.countdown_root)
            setTextViewText(R.id.countdown_title, title)
            setTextViewText(R.id.countdown_hijri, data.hijri)
            setTextViewText(R.id.countdown_label, label)
            setTextViewText(R.id.countdown_time, " · $time")
            if (ticking) {
                // Zero at the adhan: a count-down reaches it, a count-up leaves it.
                setChronometer(R.id.countdown_clock,
                    SystemClock.elapsedRealtime() + (face.at - now.time), null, true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    setChronometerCountDown(R.id.countdown_clock, !face.since)
                }
            } else {
                setViewVisibility(R.id.countdown_clock, View.GONE)
            }
        }
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            // Still given plainly, for screen readers, watches and the
            // redacted lock screen, which do not read the custom body.
            .setContentTitle(title)
            .setContentText("$label · $time")
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(body)
            .setWhen(face.at)
            .setShowWhen(false)
            .setTimeoutAfter(face.expireAt - now.time)
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

    /**
     * The face for [now], or null when there is no prayer to show.
     *
     * A count-down runs on past its adhan only for as long as that prayer's
     * count-up would: should the turn be late, "−4:10" against the prayer
     * just called reads as the time since it, which is what the turn would
     * show. A count-up must not outlive the next adhan. Midnight is a turn
     * of its own, for the Hijri date.
     */
    internal fun faceAt(context: Context, data: PrayerWidgetData, now: Long): CountdownFace? {
        val next = data.nextTime?.time ?: return null
        if (next <= now || data.times == null) return null
        val shown = PrayerWidget.countdown(context, data, now) ?: return null
        val at = shown.at.time
        val midnight = nextMidnight(now)
        return if (shown.since) {
            CountdownFace(true, shown.index, at, minOf(
                at + PrayerWidget.sinceWindowMillis(context, shown.index), next, midnight,
            ), next)
        } else {
            CountdownFace(false, shown.index, at, minOf(next, midnight),
                next + PrayerWidget.sinceWindowMillis(context, shown.index))
        }
    }

    /**
     * [at] on the phone's 12- or 24-hour clock, with the AM/PM markers of the
     * app's language (pushed for the widgets) rather than the phone's.
     */
    private fun clockTime(context: Context, data: PrayerWidgetData, at: Long): String {
        if (DateFormat.is24HourFormat(context)) {
            return SimpleDateFormat("H:mm", Locale.US).format(Date(at))
        }
        val c = Calendar.getInstance().apply { timeInMillis = at }
        val marker = if (c.get(Calendar.HOUR_OF_DAY) < 12) data.am else data.pm
        return "${SimpleDateFormat("h:mm", Locale.US).format(Date(at))} $marker"
    }

    private fun nextMidnight(now: Long): Long = Calendar.getInstance().apply {
        timeInMillis = now
        add(Calendar.DAY_OF_MONTH, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

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
