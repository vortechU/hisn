package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.text.Layout
import android.view.View
import android.widget.RemoteViews
import java.util.Date

/**
 * The set of adhkar that belongs to this part of the day, how far through it
 * you are, and whether the morning and evening sets are done.
 *
 * Which set that is turns over natively, from the prayer times this widget
 * already computes — the same rule `RecommendedAdhkar` follows in the app,
 * where morning adhkar are tied to Fajr and evening to Asr rather than to the
 * clock. Doing it here rather than pushing an answer from Flutter means the
 * widget still moves from morning to evening on a phone whose app has not been
 * opened all day; the turn alarm moves it at the adhan itself.
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
        PrayerWidget.turnAt(context, PrayerWidget.compute(context), System.currentTimeMillis())
            ?.let { WidgetChrome.scheduleTurn(context, it) }
    }

    override fun onDisabled(context: Context) = WidgetChrome.cancelTurnIfUnused(context)

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
        val inks = WidgetTheme.inks(context)
        val p = PrayerWidget.prefs(context)
        val views = RemoteViews(context.packageName, R.layout.adhkar_widget)
        val rtl = WidgetChrome.isRtlUi(context)

        WidgetChrome.applyGround(views, inks) { it.sheet }
        WidgetChrome.applyDirection(context, views, R.id.adhkar_root)

        val set = currentSet(context)
        // The category travels in the route, so opening the widget lands on the
        // set it was actually showing rather than on whichever one the app
        // would pick a moment later.
        WidgetChrome.open(context, "${WidgetChrome.ROUTE_ADHKAR}:$set")?.let {
            views.setOnClickPendingIntent(R.id.adhkar_root, it)
        }

        val height = WidgetChrome.heightDp(manager, widgetId, FALLBACK_HEIGHT_DP)
        views.setViewVisibility(
            R.id.adhkar_sessions,
            if (height < SESSIONS_FROM_DP) View.GONE else View.VISIBLE,
        )
        views.setViewVisibility(
            R.id.adhkar_subtitle,
            if (height < SUBTITLE_FROM_DP) View.GONE else View.VISIBLE,
        )

        val (done, total) = tally(p, set)
        val complete = total > 0 && done >= total

        views.setTextViewText(R.id.adhkar_label, WidgetChrome.label(context, "adhkar_label", ""))
        WidgetChrome.textColor(views, R.id.adhkar_label, inks) { it.muted }
        views.setTextViewText(
            R.id.adhkar_tally,
            if (total > 0) {
                WidgetChrome.tally(
                    "${WidgetChrome.digits(context, done)} / ${WidgetChrome.digits(context, total)}",
                )
            } else {
                ""
            },
        )
        // Completion is the one thing brass marks; on paper it is deepened toward
        // the ink so it still reads as text.
        WidgetChrome.textColor(views, R.id.adhkar_tally, inks) {
            if (complete) WidgetTheme.mix(it.gilt, it.ink, 0.3f) else it.rubric
        }

        views.setTextViewText(
            R.id.adhkar_title,
            WidgetChrome.ui(context, p.getString("adhkar_${set}_title", "") ?: ""),
        )
        WidgetChrome.textColor(views, R.id.adhkar_title, inks) { it.ink }
        views.setTextViewText(
            R.id.adhkar_subtitle,
            WidgetChrome.ui(context, p.getString("adhkar_${set}_sub", "") ?: ""),
        )
        WidgetChrome.textColor(views, R.id.adhkar_subtitle, inks) { it.muted }
        setArabicName(context, views, inks, p.getString("adhkar_${set}_ar", "") ?: "")

        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
            WidgetChrome.dp(context, 36f)
        WidgetChrome.tint(views, R.id.adhkar_progress_track, inks) { it.stone }
        WidgetChrome.mask(
            views,
            R.id.adhkar_progress,
            WidgetOrnament.progressRun(
                widthPx = width.coerceAtLeast(64),
                heightPx = WidgetChrome.dp(context, 6f).coerceAtLeast(4),
                fraction = if (total <= 0) 0f else done.toFloat() / total,
                rtl = rtl,
            ),
            inks,
        ) { if (complete) it.gilt else it.rubric }

        setChip(context, views, inks, p, MORNING, R.id.chip_morning_bg, R.id.chip_morning_icon,
            R.id.chip_morning_label)
        setChip(context, views, inks, p, EVENING, R.id.chip_evening_bg, R.id.chip_evening_icon,
            R.id.chip_evening_label)
        return views
    }

    /**
     * One of the two fortifying sets as a chip: a brass check once it is
     * complete, an open ring until then.
     */
    private fun setChip(
        context: Context,
        views: RemoteViews,
        inks: WidgetInks,
        p: android.content.SharedPreferences,
        set: String,
        bg: Int,
        icon: Int,
        label: Int,
    ) {
        val (done, total) = tally(p, set)
        val complete = total > 0 && done >= total
        WidgetChrome.tint(views, bg, inks) { it.stone }
        views.setTextViewText(label, WidgetChrome.label(context, "adhkar_${set}_short", set))
        WidgetChrome.textColor(views, label, inks) { it.ink }
        if (complete) {
            views.setImageViewResource(icon, R.drawable.ic_widget_check)
            views.setViewPadding(icon, 0, 0, 0, 0)
            WidgetChrome.tint(views, icon, inks) { it.gilt }
        } else {
            val inset = WidgetChrome.dp(context, 2f)
            views.setImageViewResource(icon, R.drawable.widget_ring)
            views.setViewPadding(icon, inset, inset, inset, inset)
            WidgetChrome.tint(views, icon, inks) { if (done > 0) it.rubric else it.muted }
        }
    }

    private fun tally(p: android.content.SharedPreferences, set: String): Pair<Int, Int> {
        val done = p.getString("adhkar_${set}_done", "0")?.toIntOrNull() ?: 0
        val total = p.getString("adhkar_${set}_total", "0")?.toIntOrNull() ?: 0
        return done to total
    }

    /**
     * The set's Arabic name across from its title, in the app's Arabic face —
     * as the app sets it. Skipped in an Arabic interface, where the title is
     * already the Arabic name.
     */
    private fun setArabicName(
        context: Context,
        views: RemoteViews,
        inks: WidgetInks,
        name: String,
    ) {
        val drawn = if (WidgetChrome.isArabicUi(context)) {
            null
        } else {
            WidgetArabic.render(
                context = context,
                text = name,
                fontId = WidgetChrome.arabicFont(context),
                textSizePx = context.resources.displayMetrics.scaledDensity * 22f,
                color = Color.WHITE,
                maxWidthPx = WidgetChrome.dp(context, 130f),
                maxLines = 1,
                align = Layout.Alignment.ALIGN_NORMAL,
            )
        }
        if (drawn != null) {
            WidgetChrome.mask(views, R.id.adhkar_title_arabic, drawn, inks) { it.rubric }
            views.setViewVisibility(R.id.adhkar_title_arabic, View.VISIBLE)
        } else {
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
        const val FALLBACK_HEIGHT_DP = 170

        /** Heights below which the bottom lines are dropped, in that order. */
        const val SESSIONS_FROM_DP = 150
        const val SUBTITLE_FROM_DP = 118
    }
}
