package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Layout
import android.view.View
import android.widget.RemoteViews

/**
 * The tasbih, on the home screen: tap the widget to count.
 *
 * Drawn on the field with the Tasbih screen's own ring, so the widget and the
 * screen it opens read as the same counter.
 *
 * This is the only widget that writes. The count it keeps is the app's own
 * count — same preference keys, same rollover rule — because a separate tally
 * that had to be reconciled later would be a worse answer than no widget at
 * all. See [FlutterPrefs] for how that store is reached and why the app reloads
 * on resume.
 *
 * There is no reset here on purpose; a stray tap on a home screen should not be
 * able to discard eighty repetitions. Reset lives in the app, and tapping the
 * phrase goes there.
 */
class TasbihWidgetProvider : AppWidgetProvider() {

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

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_COUNT) {
            count(context)
            WidgetChrome.refresh(context, TasbihWidgetProvider::class.java)
        }
        super.onReceive(context, intent)
    }

    /**
     * One repetition, applied exactly as `TasbihController.increment` applies
     * it: a tap that reaches the target banks a lap and keeps the target visible.
     * The next recitation starts the following set at one.
     */
    private fun count(context: Context) {
        val p = PrayerWidget.prefs(context)
        val id = p.getString("tasbih_id", null) ?: return
        val target = p.getString("tasbih_target", "33")?.toIntOrNull() ?: 33

        if (target < 1) return
        val current = FlutterPrefs.getInt(context, "$COUNT_KEY$id")
        val next = if (current >= target) 1 else current + 1
        FlutterPrefs.putInt(context, "$COUNT_KEY$id", next)
        if (next == target) {
            FlutterPrefs.putInt(
                context,
                "$LAPS_KEY$id",
                FlutterPrefs.getInt(context, "$LAPS_KEY$id") + 1,
            )
        }
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ): RemoteViews {
        val inks = WidgetTheme.inks(context)
        val p = PrayerWidget.prefs(context)
        val views = RemoteViews(context.packageName, R.layout.tasbih_widget)

        WidgetChrome.applyGround(views, inks) { it.field }
        WidgetChrome.applyDirection(context, views, R.id.tasbih_root)

        val id = p.getString("tasbih_id", null)
        val arabic = p.getString("tasbih_arabic", "") ?: ""
        val translit = p.getString("tasbih_translit", "") ?: ""
        val target = p.getString("tasbih_target", "33")?.toIntOrNull() ?: 33
        val count = if (id == null) 0 else FlutterPrefs.getInt(context, "$COUNT_KEY$id")
        val laps = if (id == null) 0 else FlutterPrefs.getInt(context, "$LAPS_KEY$id")

        // The whole face counts; the phrase alone opens the screen. A child's
        // click intent wins over its parent's, so the two do not collide.
        views.setOnClickPendingIntent(
            R.id.tasbih_root,
            WidgetChrome.broadcast(context, TasbihWidgetProvider::class.java, ACTION_COUNT, widgetId),
        )
        WidgetChrome.open(context, WidgetChrome.ROUTE_TASBIH)?.let {
            views.setOnClickPendingIntent(R.id.tasbih_phrase, it)
            views.setOnClickPendingIntent(R.id.tasbih_phrase_text, it)
        }

        setPhrase(context, manager, widgetId, views, inks, arabic, translit)

        // The ring fills the space under the phrase, drawn to its size so the
        // beads stay crisp: the smaller of the widget's width and what is left
        // of its height.
        val widthDp = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) /
            context.resources.displayMetrics.density
        val heightDp = WidgetChrome.heightDp(manager, widgetId, FALLBACK_HEIGHT_DP)
        val ringDp = minOf(widthDp - 24f, heightDp - 58f).coerceIn(72f, 220f)
        // Brass warms the ring only once the set is complete, as on the
        // Tasbih screen.
        val complete = target > 0 && count >= target
        val ring = WidgetOrnament.ring(
            sizePx = WidgetChrome.dp(context, ringDp),
            fraction = if (target <= 0) 0f else count.toFloat() / target,
            lobes = 11,
        )
        WidgetChrome.mask(views, R.id.tasbih_meter, ring.track, inks) { it.fieldTrack }
        WidgetChrome.mask(views, R.id.tasbih_meter_run, ring.run, inks) {
            if (complete) it.lamp else WidgetTheme.over(it.onField, 0.9f, it.field)
        }

        views.setTextViewText(R.id.tasbih_count, WidgetChrome.digits(context, count))
        WidgetChrome.textColor(views, R.id.tasbih_count, inks) { if (complete) it.lamp else it.onField }
        views.setTextViewText(R.id.tasbih_target, tally(context, target, laps))
        WidgetChrome.textColor(views, R.id.tasbih_target, inks) { it.fieldQuiet }
        return views
    }

    /**
     * The line under the meter: the target, and completed sets when there are
     * any.
     *
     * Built from numerals and a multiplication sign rather than a translated
     * phrase, because the lap count changes on a tap while the app is closed —
     * a string pushed from Flutter would be a set behind by the time it showed.
     */
    private fun tally(context: Context, target: Int, laps: Int): String {
        val of = "/ ${WidgetChrome.digits(context, target)}"
        return WidgetChrome.tally(
            if (laps > 0) "$of  ·  ×${WidgetChrome.digits(context, laps)}" else of,
        )
    }

    private fun setPhrase(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        views: RemoteViews,
        inks: WidgetInks,
        arabic: String,
        translit: String,
    ) {
        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
            WidgetChrome.dp(context, 24f)
        val drawn = WidgetArabic.render(
            context = context,
            text = arabic,
            fontId = WidgetChrome.arabicFont(context),
            textSizePx = context.resources.displayMetrics.scaledDensity * 17f,
            color = Color.WHITE,
            maxWidthPx = width.coerceAtLeast(64),
            maxLines = 1,
            align = Layout.Alignment.ALIGN_CENTER,
        )

        if (drawn != null) {
            WidgetChrome.mask(views, R.id.tasbih_phrase, drawn, inks) { it.onField }
            views.setViewVisibility(R.id.tasbih_phrase, View.VISIBLE)
            views.setViewVisibility(R.id.tasbih_phrase_text, View.GONE)
        } else {
            // No Arabic face available: the transliteration says the same thing
            // in a font that is certainly present.
            views.setTextViewText(R.id.tasbih_phrase_text, translit)
            WidgetChrome.textColor(views, R.id.tasbih_phrase_text, inks) { it.onField }
            views.setViewVisibility(R.id.tasbih_phrase_text, View.VISIBLE)
            views.setViewVisibility(R.id.tasbih_phrase, View.GONE)
        }
    }

    private companion object {
        const val ACTION_COUNT = "com.vortech.dua_app.TASBIH_COUNT"
        const val COUNT_KEY = "tasbih_count_"
        const val LAPS_KEY = "tasbih_laps_"
        const val FALLBACK_WIDTH_DP = 110
        const val FALLBACK_HEIGHT_DP = 160
    }
}
