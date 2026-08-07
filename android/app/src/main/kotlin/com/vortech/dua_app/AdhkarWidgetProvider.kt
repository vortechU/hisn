package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.text.Layout
import android.view.View
import android.widget.RemoteViews
import java.util.Date

/**
 * The set of adhkar that belongs to this part of the day, and how far through
 * it you are.
 *
 * Which set that is turns over natively, from the prayer times this widget
 * already computes — the same rule `RecommendedAdhkar` follows in the app,
 * where morning adhkar are tied to Fajr and evening to Asr rather than to the
 * clock. Doing it here rather than pushing an answer from Flutter means the
 * widget still moves from morning to evening on a phone whose app has not been
 * opened all day.
 *
 * Flutter pushes the title, subtitle and tally for all three candidate sets so
 * whichever is chosen has its text ready.
 */
class AdhkarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id))
        }
    }

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
        val ms = WidgetTheme.of(context)
        val p = PrayerWidget.prefs(context)
        val views = RemoteViews(context.packageName, R.layout.adhkar_widget)

        WidgetChrome.applySheet(views, ms)

        val set = currentSet(context)
        // The category travels in the route, so opening the widget lands on the
        // set it was actually showing rather than on whichever one the app
        // would pick a moment later.
        WidgetChrome.open(context, "${WidgetChrome.ROUTE_ADHKAR}:$set")?.let {
            views.setOnClickPendingIntent(R.id.adhkar_root, it)
        }

        val title = p.getString("adhkar_${set}_title", "") ?: ""
        val subtitle = p.getString("adhkar_${set}_sub", "") ?: ""
        val done = p.getString("adhkar_${set}_done", "0")?.toIntOrNull() ?: 0
        val total = p.getString("adhkar_${set}_total", "0")?.toIntOrNull() ?: 0

        views.setTextViewText(R.id.adhkar_label, p.getString("adhkar_label", "") ?: "")
        views.setTextColor(R.id.adhkar_label, ms.gilt)
        views.setTextViewText(
            R.id.adhkar_tally,
            if (total > 0) {
                "${WidgetChrome.digits(context, done)} / ${WidgetChrome.digits(context, total)}"
            } else {
                ""
            },
        )
        views.setTextColor(R.id.adhkar_tally, if (done >= total && total > 0) ms.gilt else ms.muted)

        setTitle(context, manager, widgetId, views, ms, title)

        views.setTextViewText(R.id.adhkar_subtitle, subtitle)
        views.setTextColor(R.id.adhkar_subtitle, ms.muted)

        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
            WidgetChrome.dp(context, 30f)
        views.setImageViewBitmap(
            R.id.adhkar_progress,
            WidgetOrnament.progressRule(
                widthPx = width.coerceAtLeast(64),
                heightPx = WidgetChrome.dp(context, 4f).coerceAtLeast(4),
                fraction = if (total <= 0) 0f else done.toFloat() / total,
                // A finished set is marked in gilt, the app's completion ink.
                color = if (total > 0 && done >= total) ms.gilt else ms.rubric,
                track = ms.rule,
            ),
        )
        return views
    }

    private fun setTitle(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        views: RemoteViews,
        ms: WidgetPalette,
        title: String,
    ) {
        val drawn = if (WidgetChrome.isArabicUi(context)) {
            val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
                WidgetChrome.dp(context, 30f)
            WidgetArabic.render(
                context = context,
                text = title,
                fontId = WidgetChrome.arabicFont(context),
                textSizePx = context.resources.displayMetrics.scaledDensity * 17f,
                color = ms.ink,
                maxWidthPx = width.coerceAtLeast(64),
                maxLines = 1,
                bold = true,
                align = Layout.Alignment.ALIGN_NORMAL,
            )
        } else {
            null
        }

        if (drawn != null) {
            views.setImageViewBitmap(R.id.adhkar_title_arabic, drawn)
            views.setViewVisibility(R.id.adhkar_title_arabic, View.VISIBLE)
            views.setViewVisibility(R.id.adhkar_title, View.GONE)
        } else {
            views.setTextViewText(R.id.adhkar_title, title)
            views.setTextColor(R.id.adhkar_title, ms.ink)
            views.setViewVisibility(R.id.adhkar_title, View.VISIBLE)
            views.setViewVisibility(R.id.adhkar_title_arabic, View.GONE)
        }
    }

    /**
     * Which set belongs to now, by prayer period.
     *
     * Fajr and Dhuhr carry the morning, Asr and Maghrib the evening, Isha the
     * night — and the hours before Fajr belong to the night that has not ended
     * yet. With no location to compute times from, it falls back to the clock,
     * exactly as the app does.
     */
    private fun currentSet(context: Context): String {
        val times = PrayerWidget.compute(context).times
            ?: return byHour()
        val now = Date()
        var current = -1
        for (i in times.indices) {
            if (!times[i].after(now)) current = i
        }
        return when (current) {
            0, 1 -> MORNING
            2, 3 -> EVENING
            else -> SLEEP
        }
    }

    private fun byHour(): String {
        val hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
        return when {
            hour in 3..11 -> MORNING
            hour in 12..18 -> EVENING
            else -> SLEEP
        }
    }

    private companion object {
        const val MORNING = "morning"
        const val EVENING = "evening"
        const val SLEEP = "sleep"
        const val FALLBACK_WIDTH_DP = 250
    }
}
