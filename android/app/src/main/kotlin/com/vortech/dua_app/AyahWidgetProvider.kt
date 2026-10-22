package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.text.Layout
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar
import org.json.JSONArray

/**
 * One verse or supplication, changing with the day.
 *
 * Flutter pushes a pool of items rather than today's pick, and the day is
 * chosen here — so the widget keeps turning over on a phone whose app has not
 * been opened in a fortnight. The index is derived from the date rather than
 * drawn at random, so the same item shows all day however often the launcher
 * asks for a redraw.
 */
class AyahWidgetProvider : AppWidgetProvider() {

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
        val inks = WidgetTheme.inks(context)
        val views = RemoteViews(context.packageName, R.layout.ayah_widget)

        WidgetChrome.applyGround(views, inks) { it.sheet }
        WidgetChrome.tint(views, R.id.ayah_mark, inks) { it.rubric }
        WidgetChrome.applyDirection(context, views, R.id.ayah_root)
        WidgetChrome.open(context, WidgetChrome.ROUTE_HOME)?.let {
            views.setOnClickPendingIntent(R.id.ayah_root, it)
        }

        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP) -
            WidgetChrome.dp(context, 36f)
        val box = width.coerceAtLeast(96)

        val item = today(context)
        if (item == null) {
            // Nothing pushed yet. Leave the panel ruled but empty rather than
            // inventing a verse.
            views.setViewVisibility(R.id.ayah_arabic, View.GONE)
            views.setViewVisibility(R.id.ayah_arabic_text, View.GONE)
            views.setTextViewText(R.id.ayah_translation, "")
            views.setTextViewText(R.id.ayah_source, "")
            return views
        }

        val drawn = WidgetArabic.render(
            context = context,
            text = item.arabic,
            fontId = WidgetChrome.arabicFont(context),
            textSizePx = context.resources.displayMetrics.scaledDensity * 20f,
            color = Color.WHITE,
            maxWidthPx = box,
            maxLines = 2,
            align = Layout.Alignment.ALIGN_CENTER,
        )

        if (drawn != null) {
            WidgetChrome.mask(views, R.id.ayah_arabic, drawn, inks) { it.ink }
            views.setViewVisibility(R.id.ayah_arabic, View.VISIBLE)
            views.setViewVisibility(R.id.ayah_arabic_text, View.GONE)
        } else {
            views.setTextViewText(R.id.ayah_arabic_text, item.arabic)
            WidgetChrome.textColor(views, R.id.ayah_arabic_text, inks) { it.ink }
            views.setViewVisibility(R.id.ayah_arabic_text, View.VISIBLE)
            views.setViewVisibility(R.id.ayah_arabic, View.GONE)
        }

        views.setTextViewText(R.id.ayah_translation, WidgetChrome.ui(context, item.translation))
        // An Arabic reader has the meaning in the line above; the pool carries
        // an English rendering for them, which would only be noise here.
        views.setViewVisibility(
            R.id.ayah_translation,
            if (WidgetChrome.isArabicUi(context) || item.translation.isBlank()) View.GONE else View.VISIBLE,
        )
        WidgetChrome.textColor(views, R.id.ayah_translation, inks) { it.muted }
        views.setTextViewText(R.id.ayah_source, WidgetChrome.ui(context, item.source))
        WidgetChrome.textColor(views, R.id.ayah_source, inks) { it.rubric }
        return views
    }

    /** Today's item from the pushed pool, or null if there is no pool yet. */
    private fun today(context: Context): Item? {
        val raw = PrayerWidget.prefs(context).getString("ayah_pool", null)
        if (raw.isNullOrBlank()) return null
        return try {
            val pool = JSONArray(raw)
            if (pool.length() == 0) return null
            val entry = pool.getJSONObject(dayIndex() % pool.length())
            Item(
                arabic = entry.optString("a"),
                translation = entry.optString("t"),
                source = entry.optString("s"),
            )
        } catch (_: Exception) {
            null
        }
    }

    /**
     * A number that advances once per local day.
     *
     * Built from the calendar rather than from epoch milliseconds so it turns
     * over at the reader's midnight, not at UTC's.
     */
    private fun dayIndex(): Int {
        val c = Calendar.getInstance()
        return c.get(Calendar.YEAR) * 366 + c.get(Calendar.DAY_OF_YEAR)
    }

    private data class Item(
        val arabic: String,
        val translation: String,
        val source: String,
    )

    private companion object {
        const val FALLBACK_WIDTH_DP = 250
    }
}
