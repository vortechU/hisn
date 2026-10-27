package com.vortech.dua_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import android.view.View

/**
 * The chrome every Hisn widget shares: the ground it is drawn on, the intents
 * that open the app at the right place, and the size arithmetic the drawn
 * marks need.
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
    const val ROUTE_QURAN = "quran"

    /**
     * Call [method] on view [id] with the colour [role] picks from the
     * palette — both palettes' colours where the launcher chooses between day
     * and night itself (see [WidgetInks]), so the widget turns with the home
     * screen without being redrawn.
     */
    fun color(
        views: RemoteViews,
        id: Int,
        method: String,
        inks: WidgetInks,
        role: (WidgetPalette) -> Int,
    ) {
        if (inks.follows && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColorInt(id, method, role(inks.day), role(inks.night))
        } else {
            views.setInt(id, method, role(inks.now))
        }
    }

    fun textColor(views: RemoteViews, id: Int, inks: WidgetInks, role: (WidgetPalette) -> Int) =
        color(views, id, "setTextColor", inks, role)

    /**
     * Recolour an ImageView — a shape, an icon, or a drawn mask — to the
     * colour [role] picks.
     *
     * `setColorFilter` is the one recolouring hook RemoteViews offers on every
     * API level this app supports (see widget_sheet.xml), and as a filter it
     * also wins over the XML tints some views carry for the picker's preview.
     */
    fun tint(views: RemoteViews, id: Int, inks: WidgetInks, role: (WidgetPalette) -> Int) =
        color(views, id, "setColorFilter", inks, role)

    /** Lay the ground: the field or the paper. */
    fun applyGround(views: RemoteViews, inks: WidgetInks, role: (WidgetPalette) -> Int) =
        tint(views, R.id.widget_ground, inks, role)

    /**
     * Show [drawn] — drawn in white — as a mask tinted to [role].
     *
     * Drawn marks carry no colour of their own, so they turn day to night
     * with the tint like everything else. Kept as alpha only, which is also a
     * quarter of the bytes against the ~1 MB the whole update may use.
     */
    fun mask(
        views: RemoteViews,
        id: Int,
        drawn: android.graphics.Bitmap,
        inks: WidgetInks,
        role: (WidgetPalette) -> Int,
    ) {
        val alpha = drawn.extractAlpha()
        if (alpha !== drawn) drawn.recycle()
        views.setImageViewBitmap(id, alpha)
        tint(views, id, inks, role)
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

    /**
     * How tall this widget currently is, in dp, as laid out in portrait.
     *
     * Layouts hide their secondary lines below a height rather than letting a
     * launcher's smallest cell squeeze them into each other.
     */
    fun heightDp(manager: AppWidgetManager, widgetId: Int, fallbackDp: Int): Int = try {
        manager.getAppWidgetOptions(widgetId)
            ?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
            ?.takeIf { it > 0 }
            ?: fallbackDp
    } catch (_: Exception) {
        fallbackDp
    }

    /** "7:21 PM", with the 12-hour markers the app pushed for its language. */
    fun clock(date: java.util.Date, am: String, pm: String): String {
        val c = java.util.Calendar.getInstance().apply { time = date }
        val marker = if (c.get(java.util.Calendar.HOUR_OF_DAY) < 12) am else pm
        val formatted = java.text.SimpleDateFormat("h:mm", java.util.Locale.US).format(date)
        return "$formatted $marker"
    }

    /**
     * Run [chrono] for [shown]: down to its adhan, or up from it.
     *
     * A [android.widget.Chronometer] ticks on its own inside the launcher, so
     * there are no per-second redraws. Before Android 7 (no count-down
     * chronometer) the static [fallback] shows "Xh Ym" instead.
     */
    fun setCountdown(
        context: Context,
        views: RemoteViews,
        chrono: Int,
        fallback: Int,
        shown: Countdown,
        now: Long,
    ) {
        val span = if (shown.since) now - shown.at.time else shown.at.time - now
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            views.setViewVisibility(chrono, View.VISIBLE)
            views.setViewVisibility(fallback, View.GONE)
            views.setChronometerCountDown(chrono, !shown.since)
            // A count-down's base is the moment it reaches zero; a count-up's
            // is the moment it started from.
            val base = if (shown.since) {
                android.os.SystemClock.elapsedRealtime() - span
            } else {
                android.os.SystemClock.elapsedRealtime() + span.coerceAtLeast(0)
            }
            views.setChronometer(chrono, base, null, true)
        } else {
            views.setViewVisibility(chrono, View.GONE)
            views.setViewVisibility(fallback, View.VISIBLE)
            views.setTextViewText(fallback, relative(context, span))
        }
    }

    private fun relative(context: Context, millis: Long): String {
        val mins = (millis / 60000).coerceAtLeast(0)
        val h = mins / 60
        val m = mins % 60
        val code = PrayerWidget.prefs(context).getString("lang", "en")
        val template = if (h > 0) {
            NativeLocalizations.text(context, code, "durationHoursMinutes", "${h}h ${m}m")
        } else {
            NativeLocalizations.text(context, code, "durationMinutes", "${m}m")
        }
        return template.replace("\${hours}", h.toString()).replace("\$hours", h.toString())
            .replace("\${minutes}", m.toString()).replace("\$minutes", m.toString())
    }

    /** A pushed label, or [fallback] before the app has pushed one. */
    fun label(context: Context, key: String, fallback: String): CharSequence =
        ui(context, PrayerWidget.prefs(context).getString(key, fallback) ?: fallback)

    /** Applies the registered native font when the bundled UI face lacks a script. */
    fun ui(context: Context, text: String): CharSequence {
        val font = language(context).opt("fontFamily") as? String ?: return text
        if (font.isEmpty() || text.isEmpty()) return text
        return android.text.SpannableString(text).apply {
            setSpan(
                android.text.style.TypefaceSpan(font),
                0, length, android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
        }
    }

    private fun language(context: Context): org.json.JSONObject =
        NativeLocalizations.language(context, PrayerWidget.prefs(context).getString("lang", "en"))

    /** dp → px, for ornament geometry that should match the app's metrics. */
    fun dp(context: Context, value: Float): Int =
        (value * context.resources.displayMetrics.density).toInt()

    /** The Arabic face chosen in Display settings, as pushed by Flutter. */
    fun arabicFont(context: Context): String =
        PrayerWidget.prefs(context).getString("arabic_font", "amiri") ?: "amiri"

    /** Whether the interface language is Arabic. */
    fun isArabicUi(context: Context): Boolean =
        language(context).optBoolean("isArabic")

    fun isRtlUi(context: Context): Boolean =
        language(context).optBoolean("rtl")

    fun applyDirection(context: Context, views: RemoteViews, root: Int) {
        views.setInt(root, "setLayoutDirection",
            if (isRtlUi(context)) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
    }

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
        if (!language(context).optBoolean("arabicDigits")) return plain
        val out = StringBuilder(plain.length)
        for (ch in plain) {
            out.append(if (ch in '0'..'9') ARABIC_DIGITS[ch - '0'] else ch)
        }
        return out.toString()
    }

    /**
     * A tally ("3 / 12", "/ 33 · ×2") held left to right in any interface.
     *
     * Arabic-Indic digits count as right-to-left to the separators between
     * them (Unicode bidi rule N1), so "٣ / ١٢" comes out as "١٢ / ٣" even inside
     * a left-to-right isolate. A left-to-right mark either side of every
     * separator anchors it between the numbers.
     */
    fun tally(text: String): String = buildString {
        for (ch in text) {
            if (ch.isDigit()) append(ch) else append(LRM).append(ch).append(LRM)
        }
    }

    private const val LRM = '\u200E'

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

    /**
     * Redraw every widget that turns over with the prayers at [at]: the next
     * adhan, or the end of the minutes counted up after one.
     *
     * One alarm serves them all — the timeline, the countdown and the adhkar
     * set all change at the same moments. It does not wake the phone: a
     * launcher nobody is looking at needs no redraw, and the alarm is delivered
     * as soon as the screen comes on.
     */
    fun scheduleTurn(context: Context, at: Long) {
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

    /** Drop the turn alarm, once the last widget that needed it is removed. */
    fun cancelTurnIfUnused(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val inUse = TURNING.any {
            manager.getAppWidgetIds(android.content.ComponentName(context, it)).isNotEmpty()
        }
        if (inUse) return
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        turnIntent(context, PendingIntent.FLAG_NO_CREATE)?.let { am.cancel(it) }
    }

    private fun turnIntent(context: Context, flag: Int): PendingIntent? {
        val intent = Intent(context, WidgetTurnReceiver::class.java)
        return PendingIntent.getBroadcast(
            context, TURN_REQUEST, intent, flag or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** The providers whose face changes at a prayer boundary. */
    val TURNING: List<Class<*>> = listOf(
        PrayerWidgetProvider::class.java,
        PrayerWidgetSmallProvider::class.java,
        AdhkarWidgetProvider::class.java,
    )

    /** Request code of the redraw alarm set by [scheduleTurn]. */
    private const val TURN_REQUEST = 0x7E1D
}

/** Where the turn alarm lands: redraw everything that turns with the prayers. */
class WidgetTurnReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        for (provider in WidgetChrome.TURNING) WidgetChrome.refresh(context, provider)
    }
}
