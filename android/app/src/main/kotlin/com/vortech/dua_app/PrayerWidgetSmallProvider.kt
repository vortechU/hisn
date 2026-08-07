package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.text.Layout
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
 *
 * Unlike the larger widget this builds per instance rather than once, because
 * the prayer name may be drawn as Arabic type and needs the width of the
 * particular widget it is going into.
 */
class PrayerWidgetSmallProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id))
        }
    }

    /** Redraw on resize: the Arabic name is drawn to the widget's own width. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildViews(context, appWidgetManager, appWidgetId),
        )
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ): RemoteViews {
        val data = PrayerWidget.compute(context)
        val ms = WidgetTheme.of(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_small)

        WidgetChrome.applySheet(views, ms)
        WidgetChrome.open(context, WidgetChrome.ROUTE_PRAYER)?.let {
            views.setOnClickPendingIntent(R.id.widget_root_small, it)
        }

        views.setTextViewText(R.id.small_hijri, data.hijri)
        views.setTextColor(R.id.small_hijri, ms.muted)
        views.setTextViewText(R.id.small_next_label, nextLabel(context))
        views.setTextColor(R.id.small_next_label, ms.gilt)
        views.setTextColor(R.id.small_name, ms.rubric)
        views.setTextColor(R.id.small_time, ms.muted)
        views.setTextColor(R.id.small_countdown, ms.ink)
        views.setTextColor(R.id.small_countdown_static, ms.ink)

        val next = data.nextTime
        if (next == null) {
            // Nothing to count down to until the app has pushed a location.
            setName(context, manager, widgetId, views, ms, data.names.getOrElse(0) { EM_DASH })
            views.setTextViewText(R.id.small_time, EM_DASH)
            views.setViewVisibility(R.id.small_countdown, View.GONE)
            views.setViewVisibility(R.id.small_countdown_static, View.GONE)
            return views
        }

        setName(context, manager, widgetId, views, ms, data.names[data.nextIndex])
        val formatter = SimpleDateFormat("h:mm", Locale.US)
        views.setTextViewText(R.id.small_time, format(next, formatter, data.am, data.pm))

        val remaining = next.time - System.currentTimeMillis()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
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

    /**
     * Put the prayer's name in whichever slot suits the interface language.
     *
     * In Arabic it is drawn in the app's own face; the plain TextView is kept
     * as the fallback so a font that will not load leaves a correct widget
     * rather than an empty one.
     */
    private fun setName(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        views: RemoteViews,
        ms: WidgetPalette,
        name: String,
    ) {
        val drawn = if (WidgetChrome.isArabicUi(context)) {
            val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
                WidgetChrome.dp(context, 28f)
            WidgetArabic.render(
                context = context,
                text = name,
                fontId = WidgetChrome.arabicFont(context),
                textSizePx = context.resources.displayMetrics.scaledDensity * 19f,
                color = ms.rubric,
                maxWidthPx = width.coerceAtLeast(64),
                maxLines = 1,
                bold = true,
                align = Layout.Alignment.ALIGN_NORMAL,
            )
        } else {
            null
        }

        if (drawn != null) {
            views.setImageViewBitmap(R.id.small_name_arabic, drawn)
            views.setViewVisibility(R.id.small_name_arabic, View.VISIBLE)
            views.setViewVisibility(R.id.small_name, View.GONE)
        } else {
            views.setTextViewText(R.id.small_name, name)
            views.setViewVisibility(R.id.small_name, View.VISIBLE)
            views.setViewVisibility(R.id.small_name_arabic, View.GONE)
        }
    }

    private fun relative(millis: Long): String {
        val mins = (millis / 60000).coerceAtLeast(0)
        val h = mins / 60
        val m = mins % 60
        return if (h > 0) "${h}h ${m}m" else "${m}m"
    }

    private fun nextLabel(context: Context): String =
        PrayerWidget.prefs(context).getString("next_label", "NEXT") ?: "NEXT"

    private fun format(date: Date, fmt: SimpleDateFormat, am: String, pm: String): String {
        val c = Calendar.getInstance().apply { time = date }
        val marker = if (c.get(Calendar.HOUR_OF_DAY) < 12) am else pm
        return "${fmt.format(date)} $marker"
    }

    private companion object {
        const val EM_DASH = "—"
        const val FALLBACK_WIDTH_DP = 110
    }
}
