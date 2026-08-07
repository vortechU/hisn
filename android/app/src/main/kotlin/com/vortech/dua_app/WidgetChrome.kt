package com.vortech.dua_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

/**
 * The chrome every Hisn widget shares: the ruled page it is drawn on, the
 * intents that open the app at the right place, and the size arithmetic the
 * drawn ornaments need.
 */
object WidgetChrome {

    /** Extra carrying the in-app destination a widget wants opened. */
    const val EXTRA_ROUTE = "hisn.route"

    // Destinations the widgets can ask for. Mirrored in Dart by
    // WidgetRoutes — keep the two lists in step.
    const val ROUTE_PRAYER = "prayer"
    const val ROUTE_TASBIH = "tasbih"
    const val ROUTE_ADHKAR = "adhkar"
    const val ROUTE_HOME = "home"

    /**
     * Lay the page: tint the sheet and its jadwal to the active palette.
     *
     * Both are ImageViews rather than backgrounds because `setColorFilter` is
     * the one recolouring hook RemoteViews offers on every API level this app
     * supports — see widget_sheet.xml.
     */
    fun applySheet(views: RemoteViews, palette: WidgetPalette) {
        views.setInt(R.id.widget_ground, "setColorFilter", palette.sheet)
        views.setInt(R.id.widget_frame, "setColorFilter", palette.rule)
    }

    /**
     * A PendingIntent that opens the app at [route].
     *
     * The route is both an extra and the request code's source, because two
     * PendingIntents that differ only by extras are considered equal — without
     * distinct request codes every widget would end up sharing whichever
     * destination was registered first.
     */
    fun open(context: Context, route: String): PendingIntent? {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: return null
        launch.putExtra(EXTRA_ROUTE, route)
        launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context,
            route.hashCode(),
            launch,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /**
     * A PendingIntent that broadcasts [action] back to [provider] — how the
     * tasbih widget counts without opening the app.
     */
    fun broadcast(
        context: Context,
        provider: Class<*>,
        action: String,
        widgetId: Int,
    ): PendingIntent {
        val intent = Intent(context, provider).apply {
            this.action = action
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            // Mutable-flagged PendingIntents aside, two intents differing only
            // in extras compare equal; the data URI makes each widget's button
            // genuinely distinct.
            data = android.net.Uri.parse("hisn://$action/$widgetId")
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /**
     * How wide this widget currently is, in pixels.
     *
     * Used to size drawn ornaments and Arabic text to the space they will
     * actually occupy. Falls back to the minimum declared width when the
     * launcher reports nothing, which is what happens on the very first draw.
     */
    fun widthPx(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        fallbackDp: Int,
    ): Int {
        val dp = try {
            manager.getAppWidgetOptions(widgetId)
                ?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
                ?.takeIf { it > 0 }
                ?: fallbackDp
        } catch (_: Exception) {
            fallbackDp
        }
        return (dp * context.resources.displayMetrics.density).toInt()
            .coerceIn(120, 1200)
    }

    /** dp → px, for ornament geometry that should match the app's metrics. */
    fun dp(context: Context, value: Float): Int =
        (value * context.resources.displayMetrics.density).toInt()

    /** The Arabic face chosen in Display settings, as pushed by Flutter. */
    fun arabicFont(context: Context): String =
        PrayerWidget.prefs(context).getString("arabic_font", "amiri") ?: "amiri"

    /** Whether the interface language is Arabic. */
    fun isArabicUi(context: Context): Boolean =
        PrayerWidget.prefs(context).getString("lang", "en") == "ar"

    /**
     * [value] in the digits the interface reads in — Arabic-Indic when the app
     * is in Arabic, Western otherwise.
     *
     * Counts and tallies on the widgets are built here rather than pushed from
     * Flutter, because they change while the app is not running and a
     * pre-rendered string would go stale on the first tap.
     */
    fun digits(context: Context, value: Int): String {
        val plain = value.toString()
        if (!isArabicUi(context)) return plain
        val out = StringBuilder(plain.length)
        for (ch in plain) {
            out.append(if (ch in '0'..'9') ARABIC_DIGITS[ch - '0'] else ch)
        }
        return out.toString()
    }

    private val ARABIC_DIGITS = charArrayOf(
        '٠', '١', '٢', '٣', '٤',
        '٥', '٦', '٧', '٨', '٩',
    )

    /**
     * Ask every instance of [provider] to redraw.
     *
     * Sent as a broadcast rather than calling into AppWidgetManager directly so
     * it works identically from the app, from the adhan alarm, and from a
     * widget's own button handler.
     */
    fun refresh(context: Context, provider: Class<*>) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val ids = manager.getAppWidgetIds(
            android.content.ComponentName(context, provider),
        )
        if (ids.isEmpty()) return
        context.sendBroadcast(
            Intent(context, provider).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
        )
    }

    /** True on the versions where a launcher rounds widget corners for us. */
    val launcherRoundsCorners: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
}
