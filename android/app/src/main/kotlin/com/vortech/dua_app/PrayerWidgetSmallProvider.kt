package com.vortech.dua_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * The compact widget: the next prayer's name + time and a live countdown.
 *
 * The countdown uses a [android.widget.Chronometer] in count-down mode, which
 * ticks on its own inside the launcher (no per-second redraws). It's advanced to
 * the following prayer by the ~30-min update tick and the adhan alarm; on
 * Android < 7 (no count-down chronometer) it shows a static "Xh Ym" instead.
 */
class PrayerWidgetSmallProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val views = buildViews(context)
        for (id in appWidgetIds) appWidgetManager.updateAppWidget(id, views)
    }

    private fun buildViews(context: Context): RemoteViews {
        val data = PrayerWidget.compute(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_small)

        views.setOnClickPendingIntent(R.id.widget_root_small, launchIntent(context))
        views.setTextViewText(R.id.small_hijri, data.hijri)
        views.setTextViewText(R.id.small_next_label, prefsNextLabel(context))

        val next = data.nextTime
        if (next == null) {
            views.setTextViewText(R.id.small_name, data.names.getOrElse(0) { "—" })
            views.setTextViewText(R.id.small_time, "—")
            views.setViewVisibility(R.id.small_countdown, View.GONE)
            views.setViewVisibility(R.id.small_countdown_static, View.GONE)
            return views
        }

        views.setTextViewText(R.id.small_name, data.names[data.nextIndex])
        val formatter = SimpleDateFormat("h:mm", Locale.US)
        views.setTextViewText(R.id.small_time, format(next, formatter, data.am, data.pm))

        val remaining = next.time - System.currentTimeMillis()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Live count-down to the next prayer.
            views.setViewVisibility(R.id.small_countdown, View.VISIBLE)
            views.setViewVisibility(R.id.small_countdown_static, View.GONE)
            views.setChronometerCountDown(R.id.small_countdown, true)
            views.setChronometer(
                R.id.small_countdown,
                SystemClock.elapsedRealtime() + remaining.coerceAtLeast(0),
                null,
                true,
            )
        } else {
            views.setViewVisibility(R.id.small_countdown, View.GONE)
            views.setViewVisibility(R.id.small_countdown_static, View.VISIBLE)
            views.setTextViewText(R.id.small_countdown_static, relative(remaining))
        }
        return views
    }

    private fun relative(millis: Long): String {
        val mins = (millis / 60000).coerceAtLeast(0)
        val h = mins / 60
        val m = mins % 60
        return if (h > 0) "${h}h ${m}m" else "${m}m"
    }

    private fun prefsNextLabel(context: Context): String =
        PrayerWidget.prefs(context).getString("next_label", "NEXT") ?: "NEXT"

    private fun format(date: Date, fmt: SimpleDateFormat, am: String, pm: String): String {
        val c = Calendar.getInstance().apply { time = date }
        val marker = if (c.get(Calendar.HOUR_OF_DAY) < 12) am else pm
        return "${fmt.format(date)} $marker"
    }

    private fun launchIntent(context: Context): PendingIntent? {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: return null
        return PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
