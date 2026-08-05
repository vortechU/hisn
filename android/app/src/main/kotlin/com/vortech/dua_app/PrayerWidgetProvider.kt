package com.vortech.dua_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * The larger widget: the five daily prayer times with the next one highlighted.
 * Times are computed natively (see [PrayerWidget.compute]) so it stays correct
 * on its own — Android re-runs [onUpdate] every ~30 min, and the app / adhan
 * alarm nudge it on changes.
 */
class PrayerWidgetProvider : AppWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)

        views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
        views.setTextViewText(R.id.widget_location, data.label)
        views.setTextViewText(R.id.widget_hijri, data.hijri)

        val nameIds = intArrayOf(
            R.id.name_fajr, R.id.name_dhuhr, R.id.name_asr,
            R.id.name_maghrib, R.id.name_isha,
        )
        val timeIds = intArrayOf(
            R.id.time_fajr, R.id.time_dhuhr, R.id.time_asr,
            R.id.time_maghrib, R.id.time_isha,
        )
        val cellIds = intArrayOf(
            R.id.cell_fajr, R.id.cell_dhuhr, R.id.cell_asr,
            R.id.cell_maghrib, R.id.cell_isha,
        )
        for (i in nameIds.indices) views.setTextViewText(nameIds[i], data.names[i])

        val times = data.times
        if (times == null) {
            for (id in timeIds) views.setTextViewText(id, "—")
            return views
        }

        val formatter = SimpleDateFormat("h:mm", Locale.US)
        for (i in times.indices) {
            views.setTextViewText(timeIds[i], format(times[i], formatter, data.am, data.pm))
            val highlight = i == data.nextIndex
            views.setInt(
                cellIds[i], "setBackgroundResource",
                if (highlight) R.drawable.widget_cell_highlight else 0,
            )
            views.setTextColor(nameIds[i], if (highlight) NAME_ON else NAME_OFF)
            views.setTextColor(timeIds[i], if (highlight) TIME_ON else TIME_OFF)
        }
        return views
    }

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

    private companion object {
        const val NAME_ON = 0xFFFFD98A.toInt()
        const val NAME_OFF = 0xFF9DB9C7.toInt()
        const val TIME_ON = 0xFFFFFFFF.toInt()
        const val TIME_OFF = 0xFFE6F0F4.toInt()
    }
}
