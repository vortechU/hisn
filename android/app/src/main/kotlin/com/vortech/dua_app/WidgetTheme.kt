package com.vortech.dua_app

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color

/**
 * The ink roles the home-screen widgets draw with — the same five a scribe
 * works with in the app (see `AppPalette` on the Dart side).
 *
 * The widgets deliberately do *not* keep their own copy of the six palettes.
 * Flutter pushes the resolved colours for both brightnesses down the
 * `hisn/widget` channel and this picks a set, so there is one definition of
 * what "emerald" means and the widget can never drift from the app sitting
 * next to it on the same screen.
 */
data class WidgetPalette(
    /** The page the widget is drawn on. */
    val sheet: Int,
    /** Primary text. */
    val ink: Int,
    /** Secondary text and apparatus — dates, labels, markers. */
    val muted: Int,
    /** The second ink: headings, the active state, the next prayer. */
    val rubric: Int,
    /** Illumination: ornament, counters, completion marks. Never body text. */
    val gilt: Int,
    /** Ruled frames and dividers. */
    val rule: Int,
    val night: Boolean,
)

object WidgetTheme {

    /**
     * The palette to draw with right now.
     *
     * Falls back to Emerald — the app's default scheme — for the window
     * between the widget being dropped on the home screen and the app first
     * pushing its settings down.
     */
    fun of(context: Context): WidgetPalette {
        val p = PrayerWidget.prefs(context)
        val night = isNight(context, p.getString("theme_mode", MODE_SYSTEM))
        val key = if (night) "n" else "l"

        fun role(name: String, fallback: Int): Int =
            parse(p.getString("c_${key}_$name", null), fallback)

        return if (night) {
            WidgetPalette(
                sheet = role("sheet", 0xFF161B19.toInt()),
                ink = role("ink", 0xFFE8E1D1.toInt()),
                muted = role("muted", 0xFF9A968B.toInt()),
                rubric = role("rubric", 0xFF58C3AB.toInt()),
                gilt = role("gilt", 0xFFCDA84E.toInt()),
                rule = role("rule", 0x57A0B5AE.toInt()),
                night = true,
            )
        } else {
            WidgetPalette(
                sheet = role("sheet", 0xFFF7F2E6.toInt()),
                ink = role("ink", 0xFF221E18.toInt()),
                muted = role("muted", 0xFF6B6459.toInt()),
                rubric = role("rubric", 0xFF0C5A4C.toInt()),
                gilt = role("gilt", 0xFF9C7B2E.toInt()),
                rule = role("rule", 0x6640453F.toInt()),
                night = false,
            )
        }
    }

    /**
     * Whether to draw the night page.
     *
     * "system" is resolved against the launcher's own configuration rather
     * than against anything stored, so the widget turns over with the rest of
     * the home screen at dusk without the app having to be running.
     */
    private fun isNight(context: Context, mode: String?): Boolean = when (mode) {
        MODE_DARK -> true
        MODE_LIGHT -> false
        else -> (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    }

    /** Parse the `AARRGGBB` form Flutter pushes; fall back on anything odd. */
    private fun parse(hex: String?, fallback: Int): Int {
        if (hex.isNullOrBlank()) return fallback
        return try {
            Color.parseColor(if (hex.startsWith("#")) hex else "#$hex")
        } catch (_: IllegalArgumentException) {
            fallback
        }
    }

    /** [color] at [fraction] of its opacity — for washes and inactive rails. */
    fun fade(color: Int, fraction: Float): Int = Color.argb(
        (Color.alpha(color) * fraction).toInt().coerceIn(0, 255),
        Color.red(color),
        Color.green(color),
        Color.blue(color),
    )

    const val MODE_LIGHT = "light"
    const val MODE_DARK = "dark"
    const val MODE_SYSTEM = "system"
}
