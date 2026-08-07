package com.vortech.dua_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils

/**
 * Arabic set in the app's own typeface, drawn to a bitmap.
 *
 * RemoteViews has no way to give a TextView a custom font, so Arabic in a
 * home-screen widget would otherwise fall to whatever face the launcher's
 * system font happens to provide — the exact mismatch the app was just fixed
 * for, reappearing one screen over. Drawing the text ourselves is the only way
 * to put Amiri (or whichever face is chosen in Display settings) on the home
 * screen.
 *
 * Bitmaps cost parcel space, and everything a provider sends shares a ~1 MB
 * Binder transaction. So the width is capped, callers pass the tightest box
 * that will do, and a failure returns null rather than throwing — the layouts
 * keep a plain TextView behind every Arabic slot to fall back to.
 */
object WidgetArabic {

    /** Flutter's asset bundle, as the platform AssetManager sees it. */
    private const val ASSETS = "flutter_assets/assets/fonts/"

    /**
     * Widest bitmap we will produce. A 4-cell widget on a 3x screen is around
     * 1000px across; going much past this risks TransactionTooLargeException
     * once the rest of the update is added, and a slightly scaled line of
     * naskh is far better than a widget that refuses to draw.
     */
    private const val MAX_WIDTH = 900

    private val typefaces = HashMap<String, Typeface?>()

    /**
     * The chosen Arabic face, or null if it cannot be loaded.
     *
     * Cached because a provider may redraw several widgets in one pass and
     * parsing a font file per draw is wasteful. Keyed by id + weight.
     */
    @Synchronized
    fun typeface(context: Context, fontId: String?, bold: Boolean): Typeface? {
        val id = fontId ?: "amiri"
        val key = "$id:$bold"
        if (typefaces.containsKey(key)) return typefaces[key]

        val file = when (id) {
            "scheherazade" ->
                if (bold) "arabic/ScheherazadeNew-Bold.ttf"
                else "arabic/ScheherazadeNew-Regular.ttf"
            // Noto Naskh is bundled in a single weight; asking for bold would
            // miss the file and drop the whole line back to the system font.
            "noto" -> "arabic/NotoNaskhArabic-Regular.ttf"
            else -> if (bold) "Amiri-Bold.ttf" else "Amiri-Regular.ttf"
        }

        val loaded = try {
            Typeface.createFromAsset(context.assets, ASSETS + file)
        } catch (_: Exception) {
            null
        }
        typefaces[key] = loaded
        return loaded
    }

    /**
     * [text] set in the chosen face, as a transparent-ground bitmap.
     *
     * Returns null when the font is unavailable or the box is degenerate, so
     * the caller can show its fallback TextView instead of an empty slot.
     */
    fun render(
        context: Context,
        text: String,
        fontId: String?,
        textSizePx: Float,
        color: Int,
        maxWidthPx: Int,
        maxLines: Int = 1,
        bold: Boolean = false,
        align: Layout.Alignment = Layout.Alignment.ALIGN_CENTER,
    ): Bitmap? {
        if (text.isBlank()) return null
        val face = typeface(context, fontId, bold) ?: return null
        val width = maxWidthPx.coerceAtMost(MAX_WIDTH)
        if (width <= 0 || textSizePx <= 0f) return null

        val paint = TextPaint(TextPaint.ANTI_ALIAS_FLAG).apply {
            typeface = face
            textSize = textSizePx
            this.color = color
        }

        return try {
            // The deprecated constructor rather than StaticLayout.Builder,
            // which is API 23 — this app still supports 21. Bidi resolves from
            // the text itself, so Arabic lays out right-to-left without being
            // told.
            @Suppress("DEPRECATION")
            var layout = StaticLayout(
                text, paint, width, align, 1f, 0f, false,
            )
            if (layout.lineCount > maxLines) {
                // Trim to the last line that fits and ellipsize it, rather than
                // letting the box grow and push the rest of the widget out.
                val end = layout.getLineEnd(maxLines - 1)
                val clipped = TextUtils.ellipsize(
                    text.substring(0, end.coerceAtMost(text.length)),
                    paint,
                    width.toFloat() * maxLines,
                    TextUtils.TruncateAt.END,
                )
                @Suppress("DEPRECATION")
                layout = StaticLayout(clipped, paint, width, align, 1f, 0f, false)
            }
            val height = layout.height.coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            layout.draw(Canvas(bitmap))
            bitmap
        } catch (_: Exception) {
            null
        }
    }
}
