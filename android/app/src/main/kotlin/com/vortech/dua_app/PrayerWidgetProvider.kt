package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

/**
 * The horizontal prayer widget: a one-row timetable, with the day track and
 * countdown revealed as the user gives it more vertical space.
 *
 * Times are computed natively (see [PrayerWidget.compute]) so it stays correct
 * on its own. Android re-runs [onUpdate] every ~30 min, which walks the "now"
 * bar along the track; the turn alarm (see [WidgetChrome.scheduleTurn]) redraws
 * it at the moment the next prayer changes; and the app and adhan alarm nudge
 * it on any change of their own.
 *
 * Built per instance, because the track is drawn to the width of the widget it
 * is going into.
 */
class PrayerWidgetProvider : AppWidgetProvider() {

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

    override fun onDisabled(context: Context) = WidgetChrome.cancelTurnIfUnused(context)

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: PrayerWidgetData,
    ): RemoteViews {
        val inks = WidgetTheme.inks(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)
        val rtl = WidgetChrome.isRtlUi(context)
        val now = System.currentTimeMillis()

        WidgetChrome.applyGround(views, inks) { it.field }
        WidgetChrome.tint(views, R.id.prayer_ornament, inks) {
            WidgetTheme.over(it.onField, 0.18f, it.field)
        }
        WidgetChrome.applyDirection(context, views, R.id.widget_root)
        WidgetChrome.open(context, WidgetChrome.ROUTE_PRAYER)?.let {
            views.setOnClickPendingIntent(R.id.widget_root, it)
        }

        // Spend a single launcher row on the five times. Larger sizes reveal
        // the track, then the countdown and context, without shrinking type.
        val height = WidgetChrome.heightDp(manager, widgetId, FALLBACK_HEIGHT_DP)
        val fontScale = context.resources.configuration.fontScale.coerceAtLeast(1f)
        val showHead = height >= (EXPANDED_FROM_DP * fontScale).toInt()
        val showTrack = height >= (TRACK_FROM_DP * fontScale).toInt()
        views.setViewVisibility(
            R.id.prayer_head,
            if (showHead) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(R.id.prayer_head_gap, if (showHead) View.VISIBLE else View.GONE)
        for (id in TRACK_IDS) {
            views.setViewVisibility(id, if (showTrack) View.VISIBLE else View.GONE)
        }
        views.setViewPadding(
            R.id.prayer_content,
            WidgetChrome.dp(context, 12f),
            WidgetChrome.dp(context, if (showHead) 14f else 2f),
            WidgetChrome.dp(context, 12f),
            WidgetChrome.dp(context, if (showHead) 10f else 2f),
        )

        views.setTextViewText(R.id.prayer_hijri, WidgetChrome.ui(context, data.hijri))
        WidgetChrome.textColor(views, R.id.prayer_hijri, inks) { it.onField }
        views.setTextViewText(R.id.prayer_place, WidgetChrome.ui(context, data.label))
        WidgetChrome.textColor(views, R.id.prayer_place, inks) { it.fieldQuiet }
        WidgetChrome.textColor(views, R.id.prayer_countdown, inks) { it.onField }
        WidgetChrome.textColor(views, R.id.prayer_countdown_static, inks) { it.onField }
        WidgetChrome.textColor(views, R.id.prayer_lead, inks) { it.fieldQuiet }

        for (i in NAME_IDS.indices) {
            views.setTextViewText(NAME_IDS[i], WidgetChrome.ui(context, data.names[i]))
            WidgetChrome.tint(views, LIFT_IDS[i], inks) { it.fieldWash }
        }

        val times = data.times
        val shown = PrayerWidget.countdown(context, data, now)
        if (times == null || shown == null) {
            // No location yet: draw the timeline empty rather than guessing,
            // and leave every column unmarked so nothing reads as "next".
            views.setViewVisibility(R.id.prayer_countdown, View.GONE)
            views.setViewVisibility(R.id.prayer_countdown_static, View.VISIBLE)
            views.setTextViewText(R.id.prayer_countdown_static, EM_DASH)
            views.setTextViewText(R.id.prayer_lead, "")
            for (i in NAME_IDS.indices) {
                views.setTextViewText(TIME_IDS[i], EM_DASH)
                WidgetChrome.textColor(views, NAME_IDS[i], inks) { it.fieldQuiet }
                WidgetChrome.textColor(views, TIME_IDS[i], inks) { it.fieldQuiet }
                views.setViewVisibility(LIFT_IDS[i], View.INVISIBLE)
            }
            drawTrack(context, manager, widgetId, views, inks,
                List(NAME_IDS.size) { WidgetOrnament.Mark.LATER }, null, rtl)
            return views
        }

        WidgetChrome.setCountdown(
            context, views, R.id.prayer_countdown, R.id.prayer_countdown_static, shown, now,
        )
        val lead = if (shown.since) {
            WidgetChrome.label(context, "since_label", "Since adhan")
        } else {
            WidgetChrome.label(context, "next_label", "Next")
        }
        views.setTextViewText(
            R.id.prayer_lead,
            WidgetChrome.ui(
                context,
                "$lead · ${data.names[shown.index]} ${WidgetChrome.clock(shown.at, data.am, data.pm)}",
            ),
        )

        // The next prayer is only marked on today's track while it is today's:
        // after Isha the next is tomorrow's Fajr, and every node has passed.
        val nextToday = data.nextTime?.let { next -> times.any { it.time == next.time } } == true
        val lifted = if (nextToday) data.nextIndex else -1
        val marks = times.mapIndexed { i, t ->
            when {
                i == lifted -> WidgetOrnament.Mark.NEXT
                t.time <= now -> WidgetOrnament.Mark.PASSED
                else -> WidgetOrnament.Mark.LATER
            }
        }
        for (i in times.indices) {
            views.setTextViewText(
                TIME_IDS[i],
                WidgetChrome.ui(context, WidgetChrome.clock(times[i], data.am, data.pm)),
            )
            when (marks[i]) {
                WidgetOrnament.Mark.NEXT -> {
                    WidgetChrome.textColor(views, NAME_IDS[i], inks) { it.onField }
                    WidgetChrome.textColor(views, TIME_IDS[i], inks) { it.onField }
                }
                WidgetOrnament.Mark.PASSED -> {
                    val passed = { p: WidgetPalette -> WidgetTheme.over(p.onField, 0.8f, p.field) }
                    WidgetChrome.textColor(views, NAME_IDS[i], inks, passed)
                    WidgetChrome.textColor(views, TIME_IDS[i], inks, passed)
                }
                WidgetOrnament.Mark.LATER -> {
                    WidgetChrome.textColor(views, NAME_IDS[i], inks) { it.fieldQuiet }
                    WidgetChrome.textColor(views, TIME_IDS[i], inks) { it.onField }
                }
            }
            views.setViewVisibility(LIFT_IDS[i], if (i == lifted) View.VISIBLE else View.INVISIBLE)
        }
        drawTrack(context, manager, widgetId, views, inks, marks,
            PrayerWidget.nowOnTrack(data, now), rtl)
        return views
    }

    /**
     * Draw the day track to this widget's width and hand each column its own
     * slice, so every node lands over its own name.
     */
    private fun drawTrack(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        views: RemoteViews,
        inks: WidgetInks,
        marks: List<WidgetOrnament.Mark>,
        nowAt: Float?,
        rtl: Boolean,
    ) {
        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
            WidgetChrome.dp(context, 24f)
        val column = (width / marks.size).coerceAtLeast(8)
        val strip = WidgetOrnament.dayTrack(
            widthPx = column * marks.size,
            heightPx = WidgetChrome.dp(context, 18f),
            density = context.resources.displayMetrics.density,
            marks = marks,
            nowAt = nowAt,
            rtl = rtl,
        )
        for (i in marks.indices) {
            // The strip is drawn already mirrored for RTL, and the row of
            // columns is mirrored by the layout: column i is at slice 4 - i.
            val slice = if (rtl) marks.size - 1 - i else i
            WidgetChrome.mask(
                views, TRACK_IDS[i],
                Bitmap.createBitmap(strip, slice * column, 0, column, strip.height),
                inks,
            ) { it.onField }
        }
        // Each slice is a copy; the whole strip is not sent anywhere.
        strip.recycle()
    }

    private companion object {
        const val EM_DASH = "—"
        const val FALLBACK_WIDTH_DP = 250
        const val FALLBACK_HEIGHT_DP = 50

        const val TRACK_FROM_DP = 88
        const val EXPANDED_FROM_DP = 160

        val NAME_IDS = intArrayOf(
            R.id.name_fajr, R.id.name_dhuhr, R.id.name_asr,
            R.id.name_maghrib, R.id.name_isha,
        )
        val TIME_IDS = intArrayOf(
            R.id.time_fajr, R.id.time_dhuhr, R.id.time_asr,
            R.id.time_maghrib, R.id.time_isha,
        )
        val LIFT_IDS = intArrayOf(
            R.id.lift_fajr, R.id.lift_dhuhr, R.id.lift_asr,
            R.id.lift_maghrib, R.id.lift_isha,
        )
        val TRACK_IDS = intArrayOf(
            R.id.track_fajr, R.id.track_dhuhr, R.id.track_asr,
            R.id.track_maghrib, R.id.track_isha,
        )
    }
}
