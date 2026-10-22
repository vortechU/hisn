package com.vortech.dua_app

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color

/**
 * The colours the home-screen widgets draw with — the same roles the app uses
 * (see `AppPalette` and `ManuscriptTheme` on the Dart side).
 *
 * The widgets deliberately do *not* keep their own copy of the palettes.
 * Flutter pushes the resolved colours for both brightnesses down the
 * `hisn/widget` channel and this picks a set, so there is one definition of
 * what "qibla" means and the widget can never drift from the app sitting next
 * to it on the same screen.
 *
 * Two surfaces, as in the app. The **field** is the deep accent ink of the
 * mihrab, carrying the one thing a screen is about — the prayer widgets and the
 * tasbih stand on it. The **paper** carries reading: the adhkar, the verse,
 * the Qurʾān. Every colour that sits on a surface is derived here as an opaque
 * blend over it, because RemoteViews recolours with filters that do not thin a
 * translucent tint the way Flutter's alpha does.
 */
data class WidgetPalette(
    /** The paper a reading widget is drawn on. */
    val sheet: Int,
    /** Primary text on paper. */
    val ink: Int,
    /** Secondary text on paper. */
    val muted: Int,
    /** The accent ink: the active state, links, the next prayer on paper. */
    val rubric: Int,
    /** Brass: completion, and nothing else. */
    val gilt: Int,
    /** Hairlines and empty tracks on paper. */
    val rule: Int,
    /** A soft accent-tinted fill on paper, for wells and grouped rows. */
    val stone: Int,
    /** The mihrab's ink: the ground of the focal widgets. */
    val field: Int,
    /** Text and marks on the field. */
    val onField: Int,
    /** Secondary text on the field. */
    val fieldQuiet: Int,
    /** Tracks and passed marks on the field. */
    val fieldTrack: Int,
    /** A faint wash on the field, for ornament and the lifted row. */
    val fieldWash: Int,
    /** Brass warmed toward the field's text, so completion still reads there. */
    val lamp: Int,
    val night: Boolean,
)

/**
 * The palettes a widget is coloured with: the day one, the night one, and
 * whether the launcher should choose between them itself.
 *
 * When the app follows the system theme, Android 12+ lets a widget hand over a
 * colour for each and swaps them the moment the home screen turns dark, with no
 * redraw — so every colour a widget sets goes through [WidgetChrome.color] as a
 * pair, and everything drawn is drawn as a mask and tinted. Earlier versions,
 * and a theme fixed to light or dark, get the one palette for now.
 */
class WidgetInks(
    val day: WidgetPalette,
    val night: WidgetPalette,
    /** Whether the launcher picks between [day] and [night] by its own mode. */
    val follows: Boolean,
    /** The palette for right now, where the launcher does not choose. */
    val now: WidgetPalette,
)

object WidgetTheme {

    /** Both palettes, and who chooses between them. See [WidgetInks]. */
    fun inks(context: Context): WidgetInks {
        val mode = PrayerWidget.prefs(context).getString("theme_mode", MODE_SYSTEM)
        val day = palette(context, night = false)
        val night = palette(context, night = true)
        return WidgetInks(
            day = day,
            night = night,
            follows = mode != MODE_LIGHT && mode != MODE_DARK &&
                android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S,
            now = if (isNight(context, mode)) night else day,
        )
    }

    /**
     * One brightness of the active palette.
     *
     * Falls back to Qibla & Brass — the app's default scheme — for the window
     * between the widget being dropped on the home screen and the app first
     * pushing its settings down.
     */
    private fun palette(context: Context, night: Boolean): WidgetPalette {
        val p = PrayerWidget.prefs(context)
        val key = if (night) "n" else "l"

        fun role(name: String, fallback: Long): Int =
            parse(p.getString("c_${key}_$name", null), fallback.toInt())

        val sheet: Int
        val ink: Int
        val rubric: Int
        val gilt: Int
        val field: Int
        val onField: Int
        if (night) {
            sheet = role("sheet", 0xFF15313A)
            ink = role("ink", 0xFFE9E5DB)
            rubric = role("rubric", 0xFF86C5CC)
            gilt = role("gilt", 0xFFD4A85A)
            field = role("field", 0xFF1B4A58)
            onField = role("onfield", 0xFFF4F1E8)
        } else {
            sheet = role("sheet", 0xFFFBFAF7)
            ink = role("ink", 0xFF161A1C)
            rubric = role("rubric", 0xFF0F3D4C)
            gilt = role("gilt", 0xFF93681D)
            field = role("field", 0xFF0F3D4C)
            onField = role("onfield", 0xFFF4F1E8)
        }
        return WidgetPalette(
            sheet = sheet,
            ink = ink,
            muted = role("muted", if (night) 0xFFA7A49C else 0xFF5F6263),
            rubric = rubric,
            gilt = gilt,
            rule = role("rule", if (night) 0xFF2A3134 else 0xFFE8E7E3),
            stone = over(rubric, if (night) 0.14f else 0.08f, sheet),
            field = field,
            onField = onField,
            fieldQuiet = over(onField, 0.88f, field),
            fieldTrack = over(onField, 0.22f, field),
            fieldWash = over(onField, 0.10f, field),
            lamp = mix(gilt, onField, 0.7f),
            night = night,
        )
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

    /** [top] at [alpha] laid over the opaque [ground], as an opaque colour. */
    fun over(top: Int, alpha: Float, ground: Int): Int = mix(ground, top, alpha)

    /** Straight sRGB interpolation from [a] to [b], as Flutter's Color.lerp. */
    fun mix(a: Int, b: Int, t: Float): Int {
        fun ch(x: Int, y: Int) = (x + (y - x) * t).toInt().coerceIn(0, 255)
        return Color.argb(
            ch(Color.alpha(a), Color.alpha(b)),
            ch(Color.red(a), Color.red(b)),
            ch(Color.green(a), Color.green(b)),
            ch(Color.blue(a), Color.blue(b)),
        )
    }

    const val MODE_LIGHT = "light"
    const val MODE_DARK = "dark"
    const val MODE_SYSTEM = "system"
}
