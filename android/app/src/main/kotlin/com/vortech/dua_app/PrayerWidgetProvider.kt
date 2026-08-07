package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * The larger widget: the five daily prayer times with the next one marked.
 *
 * Times are computed natively (see [PrayerWidget.compute]) so it stays correct
 * on its own — Android re-runs [onUpdate] every ~30 min, and the app / adhan
 * alarm nudge it on changes.
 *
 * The next prayer is marked the way the app marks an active choice: a wash of
 * the rubric behind the cell and a rule under it, rather than a filled pill.
 * Colour alone would not survive a colour-blind reader or a busy wallpaper;
 * the rule carries the same information as a shape.
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
        val ms = WidgetTheme.of(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)

        WidgetChrome.applySheet(views, ms)
        WidgetChrome.open(context, WidgetChrome.ROUTE_PRAYER)?.let {
            views.setOnClickPendingIntent(R.id.widget_root, it)
        }

        views.setTextViewText(R.id.widget_location, data.label)
        views.setTextColor(R.id.widget_location, ms.ink)
        views.setTextViewText(R.id.widget_hijri, data.hijri)
        views.setTextColor(R.id.widget_hijri, ms.muted)
        views.setInt(R.id.widget_header_rule, "setBackgroundColor", ms.rule)

        for (i in NAME_IDS.indices) {
            views.setTextViewText(NAME_IDS[i], data.names[i])
        }

        val times = data.times
        if (times == null) {
            // No location yet: draw the table empty rather than guessing, and
            // leave every cell unmarked so nothing reads as "next".
            for (i in NAME_IDS.indices) {
                views.setTextViewText(TIME_IDS[i], EM_DASH)
                views.setTextColor(NAME_IDS[i], ms.muted)
                views.setTextColor(TIME_IDS[i], ms.muted)
                views.setInt(CELL_IDS[i], "setBackgroundColor", TRANSPARENT)
                views.setInt(MARK_IDS[i], "setBackgroundColor", TRANSPARENT)
            }
            return views
        }

        val formatter = SimpleDateFormat("h:mm", Locale.US)
        val wash = WidgetTheme.fade(ms.rubric, 0.10f)
        for (i in times.indices) {
            views.setTextViewText(TIME_IDS[i], format(times[i], formatter, data.am, data.pm))
            val next = i == data.nextIndex
            views.setInt(CELL_IDS[i], "setBackgroundColor", if (next) wash else TRANSPARENT)
            views.setInt(MARK_IDS[i], "setBackgroundColor", if (next) ms.rubric else TRANSPARENT)
            views.setTextColor(NAME_IDS[i], if (next) ms.rubric else ms.muted)
            views.setTextColor(TIME_IDS[i], if (next) ms.rubric else ms.ink)
        }
        return views
    }

    private fun format(date: Date, fmt: SimpleDateFormat, am: String, pm: String): String {
        val c = Calendar.getInstance().apply { time = date }
        val marker = if (c.get(Calendar.HOUR_OF_DAY) < 12) am else pm
        return "${fmt.format(date)} $marker"
    }

    private companion object {
        const val TRANSPARENT = 0x00000000
        const val EM_DASH = "—"

        val NAME_IDS = intArrayOf(
            R.id.name_fajr, R.id.name_dhuhr, R.id.name_asr,
            R.id.name_maghrib, R.id.name_isha,
        )
        val TIME_IDS = intArrayOf(
            R.id.time_fajr, R.id.time_dhuhr, R.id.time_asr,
            R.id.time_maghrib, R.id.time_isha,
        )
        val CELL_IDS = intArrayOf(
            R.id.cell_fajr, R.id.cell_dhuhr, R.id.cell_asr,
            R.id.cell_maghrib, R.id.cell_isha,
        )
        val MARK_IDS = intArrayOf(
            R.id.mark_fajr, R.id.mark_dhuhr, R.id.mark_asr,
            R.id.mark_maghrib, R.id.mark_isha,
        )
    }
}
