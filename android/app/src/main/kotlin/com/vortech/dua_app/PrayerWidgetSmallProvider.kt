package com.vortech.dua_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
 * For the first few minutes after an adhan (that prayer's iqāmah delay, or
 * twenty minutes) it turns to the prayer just called and counts up from it, so the wait for the
 * iqama can be judged from the home screen, as it can in the app's header.
 *
 * The count uses a [android.widget.Chronometer], which ticks on its own inside
 * the launcher (no per-second redraws), down to the next adhan or up from the
 * last. Each draw sets a non-waking alarm for the moment it should next change
 * — the next adhan, or the end of the window — so it turns on time without
 * waiting for the ~30-min update tick. On Android < 7 (no count-down
 * chronometer) it shows a static "Xh Ym" instead.
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
        val data = PrayerWidget.compute(context)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id, data))
        }
        scheduleTurn(context, data)
    }

    override fun onDisabled(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        turnIntent(context, PendingIntent.FLAG_NO_CREATE)?.let { am.cancel(it) }
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
            buildViews(context, appWidgetManager, appWidgetId, PrayerWidget.compute(context)),
        )
    }

    /**
     * Redraw at the next moment the widget's face changes: when the adhan it
     * counts up from leaves the window, or else when the next one is called.
     *
     * The alarm does not wake the phone. A launcher nobody is looking at needs
     * no redraw, and the alarm is delivered as soon as the screen comes on.
     */
    private fun scheduleTurn(context: Context, data: PrayerWidgetData) {
        val next = data.nextTime ?: return
        val now = System.currentTimeMillis()
        val windowEnd = data.lastTime?.time
            ?.plus(PrayerWidget.sinceWindowMillis(context, data.lastIndex))
        val at = if (windowEnd != null && windowEnd > now) windowEnd else next.time
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pi = turnIntent(context, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
                am.set(AlarmManager.RTC, at, pi)
            } else {
                am.setExact(AlarmManager.RTC, at, pi)
            }
        } catch (_: SecurityException) {
            // Left to the ~30-min update tick.
        }
    }

    private fun turnIntent(context: Context, flag: Int): PendingIntent? {
        val ids = AppWidgetManager.getInstance(context)
            ?.getAppWidgetIds(ComponentName(context, PrayerWidgetSmallProvider::class.java))
            ?: IntArray(0)
        val intent = Intent(context, PrayerWidgetSmallProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        return PendingIntent.getBroadcast(
            context, TURN_REQUEST, intent, flag or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: PrayerWidgetData,
    ): RemoteViews {
        val ms = WidgetTheme.of(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_small)

        WidgetChrome.applySheet(views, ms)
        WidgetChrome.open(context, WidgetChrome.ROUTE_PRAYER)?.let {
            views.setOnClickPendingIntent(R.id.widget_root_small, it)
        }

        views.setTextViewText(R.id.small_hijri, data.hijri)
        views.setTextColor(R.id.small_hijri, ms.muted)
        views.setTextViewText(R.id.small_next_label, label(context, "next_label", "NEXT"))
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

        // Just after an adhan, the prayer just called and the time since it;
        // otherwise the next prayer and the time until it.
        val now = System.currentTimeMillis()
        val window = PrayerWidget.sinceWindowMillis(context, data.lastIndex)
        val since = data.lastTime?.takeIf { now - it.time in 0 until window }
        val shownIndex = if (since != null) data.lastIndex else data.nextIndex
        val shownTime = since ?: next
        if (since != null) {
            views.setTextViewText(
                R.id.small_next_label,
                label(context, "since_label", "SINCE ADHAN"),
            )
        }

        setName(context, manager, widgetId, views, ms, data.names[shownIndex])
        val formatter = SimpleDateFormat("h:mm", Locale.US)
        views.setTextViewText(R.id.small_time, format(shownTime, formatter, data.am, data.pm))

        val span = if (since != null) now - since.time else next.time - now
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            views.setViewVisibility(R.id.small_countdown, View.VISIBLE)
            views.setViewVisibility(R.id.small_countdown_static, View.GONE)
            views.setChronometerCountDown(R.id.small_countdown, since == null)
            // A count-down's base is the moment it reaches zero; a count-up's
            // is the moment it started from.
            val base = if (since != null) {
                SystemClock.elapsedRealtime() - span
            } else {
                SystemClock.elapsedRealtime() + span.coerceAtLeast(0)
            }
            views.setChronometer(R.id.small_countdown, base, null, true)
        } else {
            views.setViewVisibility(R.id.small_countdown, View.GONE)
            views.setViewVisibility(R.id.small_countdown_static, View.VISIBLE)
            views.setTextViewText(R.id.small_countdown_static, relative(span))
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

    private fun label(context: Context, key: String, fallback: String): String =
        PrayerWidget.prefs(context).getString(key, fallback) ?: fallback

    private fun format(date: Date, fmt: SimpleDateFormat, am: String, pm: String): String {
        val c = Calendar.getInstance().apply { time = date }
        val marker = if (c.get(Calendar.HOUR_OF_DAY) < 12) am else pm
        return "${fmt.format(date)} $marker"
    }

    private companion object {
        const val EM_DASH = "—"
        const val FALLBACK_WIDTH_DP = 110

        /** Request code of the redraw alarm set by [scheduleTurn]. */
        const val TURN_REQUEST = 0x7E1D
    }
}
