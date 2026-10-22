package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

/**
 * The compact widget: the next prayer, a live countdown to it, and the day as
 * five dots.
 *
 * For the first few minutes after an adhan (that prayer's iqāmah delay, or
 * twenty minutes) it turns to the prayer just called and counts up from it, so
 * the wait for the iqama can be judged from the home screen, as it can in the
 * app's header. The turn alarm (see [WidgetChrome.scheduleTurn]) redraws it at
 * the moment either changes, without waiting for the ~30-min update tick.
 */
class PrayerWidgetSmallProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = PrayerWidget.compute(context)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id, data))
        }
        PrayerWidget.turnAt(context, data, System.currentTimeMillis())
            ?.let { WidgetChrome.scheduleTurn(context, it) }
    }

    override fun onDisabled(context: Context) = WidgetChrome.cancelTurnIfUnused(context)

    /** Redraw on resize: lines are dropped as the widget gets shorter. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildViews(context, appWidgetManager, appWidgetId, PrayerWidget.compute(context)),
        )
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: PrayerWidgetData,
    ): RemoteViews {
        val inks = WidgetTheme.inks(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_small)
        val now = System.currentTimeMillis()

        WidgetChrome.applyGround(views, inks) { it.field }
        WidgetChrome.tint(views, R.id.widget_star, inks) { WidgetTheme.over(it.onField, 0.08f, it.field) }
        WidgetChrome.applyDirection(context, views, R.id.widget_root_small)
        WidgetChrome.open(context, WidgetChrome.ROUTE_PRAYER)?.let {
            views.setOnClickPendingIntent(R.id.widget_root_small, it)
        }

        val height = WidgetChrome.heightDp(manager, widgetId, FALLBACK_HEIGHT_DP)
        views.setViewVisibility(R.id.small_dots, if (height < DOTS_FROM_DP) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.small_time, if (height < TIME_FROM_DP) View.GONE else View.VISIBLE)

        WidgetChrome.textColor(views, R.id.small_name, inks) { it.onField }
        WidgetChrome.textColor(views, R.id.small_countdown, inks) { it.onField }
        WidgetChrome.textColor(views, R.id.small_countdown_static, inks) { it.onField }
        WidgetChrome.textColor(views, R.id.small_time, inks) { it.fieldQuiet }

        val shown = PrayerWidget.countdown(context, data, now)
        if (shown == null) {
            // Nothing to count down to until the app has pushed a location.
            views.setTextViewText(R.id.small_name, WidgetChrome.ui(context, data.names[0]))
            views.setViewVisibility(R.id.small_countdown, View.GONE)
            views.setViewVisibility(R.id.small_countdown_static, View.VISIBLE)
            views.setTextViewText(R.id.small_countdown_static, EM_DASH)
            views.setTextViewText(R.id.small_time, "")
            for (id in DOT_IDS) setDot(views, id, ring = false, inks) { it.fieldTrack }
            return views
        }

        views.setTextViewText(R.id.small_name, WidgetChrome.ui(context, data.names[shown.index]))
        WidgetChrome.setCountdown(
            context, views, R.id.small_countdown, R.id.small_countdown_static, shown, now,
        )
        val lead = if (shown.since) {
            WidgetChrome.label(context, "since_label", "Since adhan")
        } else {
            WidgetChrome.label(context, "next_label", "Next")
        }
        views.setTextViewText(
            R.id.small_time,
            WidgetChrome.ui(context, "$lead · ${WidgetChrome.clock(shown.at, data.am, data.pm)}"),
        )

        // The day as five dots, read the same way as the timeline's nodes:
        // passed solid, the next an open ring, the rest faint.
        val times = data.times
        val nextToday = times != null && times.any { it.time == data.nextTime?.time }
        for (i in DOT_IDS.indices) {
            val time = times?.getOrNull(i)?.time
            when {
                nextToday && i == data.nextIndex -> setDot(views, DOT_IDS[i], ring = true, inks) { it.onField }
                time != null && time <= now -> setDot(views, DOT_IDS[i], ring = false, inks) { it.onField }
                else -> setDot(views, DOT_IDS[i], ring = false, inks) {
                    WidgetTheme.over(it.onField, 0.45f, it.field)
                }
            }
        }
        return views
    }

    private fun setDot(
        views: RemoteViews,
        id: Int,
        ring: Boolean,
        inks: WidgetInks,
        role: (WidgetPalette) -> Int,
    ) {
        views.setImageViewResource(id, if (ring) R.drawable.widget_ring else R.drawable.widget_dot_inset)
        WidgetChrome.tint(views, id, inks, role)
    }

    private companion object {
        const val EM_DASH = "—"
        const val FALLBACK_HEIGHT_DP = 160

        /** Heights below which the bottom lines are dropped, in that order. */
        const val DOTS_FROM_DP = 128
        const val TIME_FROM_DP = 104

        val DOT_IDS = intArrayOf(
            R.id.dot_fajr, R.id.dot_dhuhr, R.id.dot_asr, R.id.dot_maghrib, R.id.dot_isha,
        )
    }
}
