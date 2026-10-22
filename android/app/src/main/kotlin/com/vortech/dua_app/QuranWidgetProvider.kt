package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.text.Layout
import android.view.View
import android.widget.RemoteViews

/**
 * The way back into the mushaf: the sūrah the reader left off in, and one tap
 * to reopen that page.
 *
 * Nothing about it changes with time, only when the reader turns a page in the
 * app — which pushes the new position and redraws it — so it has no update
 * period. Before anything has been read it offers the Qurʾān from its opening.
 */
class QuranWidgetProvider : AppWidgetProvider() {

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
        val p = PrayerWidget.prefs(context)
        val views = RemoteViews(context.packageName, R.layout.quran_widget)

        WidgetChrome.applyGround(views, inks) { it.sheet }
        WidgetChrome.tint(views, R.id.quran_well, inks) { it.field }
        WidgetChrome.tint(views, R.id.quran_icon, inks) { it.onField }
        WidgetChrome.applyDirection(context, views, R.id.quran_root)

        val page = p.getString("quran_page", null)?.toIntOrNull() ?: 1
        WidgetChrome.open(context, "${WidgetChrome.ROUTE_QURAN}:$page")?.let {
            views.setOnClickPendingIntent(R.id.quran_root, it)
        }

        views.setTextViewText(
            R.id.quran_title,
            WidgetChrome.ui(context, p.getString("quran_title", null) ?: "Quran"),
        )
        WidgetChrome.textColor(views, R.id.quran_title, inks) { it.ink }
        views.setTextViewText(R.id.quran_sub, WidgetChrome.ui(context, p.getString("quran_sub", "") ?: ""))
        WidgetChrome.textColor(views, R.id.quran_sub, inks) { it.muted }

        // The Arabic name across from the title, in the app's own face. Skipped
        // in Arabic (the title already is it) and when the widget is too
        // narrow to give it room beside the title.
        val width = WidgetChrome.widthPx(context, manager, widgetId, FALLBACK_WIDTH_DP)
        val roomy = width >= WidgetChrome.dp(context, ARABIC_FROM_DP)
        val arabic = p.getString("quran_ar", "") ?: ""
        val drawn = if (roomy && !WidgetChrome.isArabicUi(context)) {
            WidgetArabic.render(
                context = context,
                text = arabic,
                fontId = WidgetChrome.arabicFont(context),
                textSizePx = context.resources.displayMetrics.scaledDensity * 24f,
                color = Color.WHITE,
                maxWidthPx = WidgetChrome.dp(context, 120f),
                maxLines = 1,
                align = Layout.Alignment.ALIGN_NORMAL,
            )
        } else {
            null
        }
        if (drawn != null) {
            WidgetChrome.mask(views, R.id.quran_arabic, drawn, inks) { it.rubric }
            views.setViewVisibility(R.id.quran_arabic, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.quran_arabic, View.GONE)
        }
        return views
    }

    private companion object {
        const val FALLBACK_WIDTH_DP = 250
        const val ARABIC_FROM_DP = 220f
    }
}
