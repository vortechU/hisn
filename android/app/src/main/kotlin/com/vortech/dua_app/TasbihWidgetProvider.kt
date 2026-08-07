package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.text.Layout
import android.view.View
import android.widget.RemoteViews

/**
 * The tasbih, on the home screen: tap the widget to count.
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
     * it: a tap that reaches the target closes the set, banks a lap and starts
     * the next from zero.
     */
    private fun count(context: Context) {
        val p = PrayerWidget.prefs(context)
        val id = p.getString("tasbih_id", null) ?: return
        val target = p.getString("tasbih_target", "33")?.toIntOrNull() ?: 33

        val next = FlutterPrefs.getInt(context, "$COUNT_KEY$id") + 1
        if (target > 0 && next >= target) {
            FlutterPrefs.putInt(context, "$COUNT_KEY$id", 0)
            FlutterPrefs.putInt(
                context,
                "$LAPS_KEY$id",
                FlutterPrefs.getInt(context, "$LAPS_KEY$id") + 1,
            )
        } else {
            FlutterPrefs.putInt(context, "$COUNT_KEY$id", next)
        }
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ): RemoteViews {
        val ms = WidgetTheme.of(context)
        val p = PrayerWidget.prefs(context)
        val views = RemoteViews(context.packageName, R.layout.tasbih_widget)

        WidgetChrome.applySheet(views, ms)

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

        setPhrase(context, manager, widgetId, views, ms, arabic, translit)

        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP)
        val meter = (width * 0.62f).toInt().coerceIn(120, 260)
        views.setImageViewBitmap(
            R.id.tasbih_meter,
            WidgetOrnament.beadMeter(
                sizePx = meter,
                fraction = if (target <= 0) 0f else count.toFloat() / target,
                color = ms.gilt,
                track = WidgetTheme.fade(ms.rule, 0.9f),
                lobes = 11,
            ),
        )

        views.setTextViewText(R.id.tasbih_count, WidgetChrome.digits(context, count))
        views.setTextColor(R.id.tasbih_count, ms.ink)
        views.setTextViewText(R.id.tasbih_target, tally(context, target, laps))
        views.setTextColor(R.id.tasbih_target, ms.muted)
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
        val of = "⁄ ${WidgetChrome.digits(context, target)}"
        return if (laps > 0) "$of   ×${WidgetChrome.digits(context, laps)}" else of
    }

    private fun setPhrase(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        views: RemoteViews,
        ms: WidgetPalette,
        arabic: String,
        translit: String,
    ) {
        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
            WidgetChrome.dp(context, 24f)
        val drawn = WidgetArabic.render(
            context = context,
            text = arabic,
            fontId = WidgetChrome.arabicFont(context),
            textSizePx = context.resources.displayMetrics.scaledDensity * 15f,
            color = ms.rubric,
            maxWidthPx = width.coerceAtLeast(64),
            maxLines = 1,
            align = Layout.Alignment.ALIGN_CENTER,
        )

        if (drawn != null) {
            views.setImageViewBitmap(R.id.tasbih_phrase, drawn)
            views.setViewVisibility(R.id.tasbih_phrase, View.VISIBLE)
            views.setViewVisibility(R.id.tasbih_phrase_text, View.GONE)
        } else {
            // No Arabic face available: the transliteration says the same thing
            // in a font that is certainly present.
            views.setTextViewText(R.id.tasbih_phrase_text, translit)
            views.setTextColor(R.id.tasbih_phrase_text, ms.rubric)
            views.setViewVisibility(R.id.tasbih_phrase_text, View.VISIBLE)
            views.setViewVisibility(R.id.tasbih_phrase, View.GONE)
        }
    }

    private companion object {
        const val ACTION_COUNT = "com.vortech.dua_app.TASBIH_COUNT"
        const val COUNT_KEY = "tasbih_count_"
        const val LAPS_KEY = "tasbih_laps_"
        const val FALLBACK_WIDTH_DP = 110
    }
}
