package com.vortech.dua_app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.sin

/**
 * The app's drawn marks, for the home-screen widgets.
 *
 * RemoteViews can only fill, tint and stretch — it cannot run the app's
 * `CustomPainter`s. So the marks that carry information a view cannot (where
 * "now" falls between two prayers, how far round a count has come) are drawn
 * here and handed over as bitmaps. The geometry follows
 * `lib/widgets/ornament.dart` and `prayer_header.dart`; if one side changes the
 * other should follow, or the widget stops looking like the app.
 *
 * Every mark is drawn in white, as a mask, and coloured by the tint it is shown
 * with (see [WidgetChrome.mask]) — so it turns from day to night with the rest
 * of the widget, without a redraw. Where one mark needs two strengths of the
 * same ink, the weaker is drawn at partial alpha. Each is kept small, too: the
 * whole update crosses a Binder transaction with a hard ~1 MB ceiling.
 */
object WidgetOrnament {

    /** Where a prayer stands relative to now, as the day track draws it. */
    enum class Mark { PASSED, NEXT, LATER }

    /** The rail's and the later nodes' strength against the inked run. */
    private const val RAIL_ALPHA = 0.22f
    private const val LATER_ALPHA = 0.45f

    /**
     * The day as a track under five evenly spaced columns: a faint rail, the
     * part already lived inked over it up to a "now" bar, and a node per
     * prayer — solid once passed, an open ring for the next, faint for later.
     *
     * The nodes sit at the centres of five equal columns so they line up with
     * the names and times laid out above and below by the layout. [nowAt] is
     * the bar's position in column units, from -0.5 (the leading edge) to 4.5
     * (the trailing edge); [rtl] mirrors the whole strip. The next prayer's
     * ring is hollowed right through, so the lifted panel behind it shows.
     */
    fun dayTrack(
        widthPx: Int,
        heightPx: Int,
        density: Float,
        marks: List<Mark>,
        nowAt: Float?,
        rtl: Boolean,
    ): Bitmap {
        val w = widthPx.coerceAtLeast(40)
        val h = heightPx.coerceAtLeast(8)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val column = w / marks.size.coerceAtLeast(1).toFloat()
        val y = h / 2f
        val r = 4.5f * density
        val ring = r + 2.5f * density

        // Position along the strip, in column units, as pixels.
        fun xOf(units: Float): Float {
            val x = (units + 0.5f) * column
            return if (rtl) w - x else x
        }

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2f * density
            strokeCap = Paint.Cap.ROUND
        }
        val start = xOf(-0.5f) + if (rtl) -r else r
        val end = xOf(marks.size - 0.5f) + if (rtl) r else -r
        canvas.drawLine(start, y, end, y, stroke.apply { color = white(RAIL_ALPHA) })
        val nowX = nowAt?.let { xOf(it.coerceIn(-0.5f, marks.size - 0.5f)) }
        if (nowX != null) {
            // Over the rail, not blended with it: the run is the full ink.
            canvas.drawLine(start, y, nowX, y, stroke.apply {
                color = Color.WHITE
                xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC)
            })
            stroke.xfermode = null
        }

        val fill = Paint(Paint.ANTI_ALIAS_FLAG)
        val clear = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
        }
        marks.forEachIndexed { i, mark ->
            val x = xOf(i.toFloat())
            when (mark) {
                Mark.NEXT -> {
                    canvas.drawCircle(x, y, ring, fill.apply { color = Color.WHITE })
                    canvas.drawCircle(x, y, r - 0.5f * density, clear)
                }
                Mark.PASSED -> canvas.drawCircle(x, y, r, fill.apply { color = Color.WHITE })
                Mark.LATER -> {
                    // Cleared first, so the faint node does not add to the rail.
                    canvas.drawCircle(x, y, r, clear)
                    canvas.drawCircle(x, y, r, fill.apply { color = white(LATER_ALPHA) })
                }
            }
        }

        // Now: a short upright bar through the line, as in the app's strip —
        // left out in the minutes before an adhan, when it would only cut
        // through the next prayer's ring, which already says "almost".
        val nextX = marks.indexOf(Mark.NEXT).takeIf { it >= 0 }?.let { xOf(it.toFloat()) }
        val crowded = nowX != null && nextX != null && abs(nowX - nextX) < ring + 3f * density
        if (nowX != null && !crowded) {
            canvas.drawLine(
                nowX, y - 7f * density, nowX, y + 7f * density,
                stroke.apply {
                    color = Color.WHITE
                    strokeWidth = 2.5f * density
                },
            )
        }
        return bitmap
    }

    /**
     * The counter's ring, as two masks laid one over the other: the [track]
     * (the full circle and every bead) and the [run] (the arc to the exact
     * fraction, and the beads filled so far), so partial progress stays
     * countable at a glance. A port of `_RingPainter` in ornament.dart.
     */
    fun ring(sizePx: Int, fraction: Float, lobes: Int = 11): RingMasks {
        val size = sizePx.coerceAtLeast(24)
        val track = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val run = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val value = fraction.coerceIn(0f, 1f)
        val centre = size / 2f
        val outer = size / 2f
        val weight = max(3f, outer * 0.075f)
        val bead = if (lobes == 0) 0f else max(2.5f, outer * 0.035f)
        val arcR = outer - weight / 2 - if (lobes == 0) 0f else bead * 2 + outer * 0.05f

        val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = weight
            strokeCap = Paint.Cap.ROUND
        }
        Canvas(track).drawCircle(centre, centre, arcR, line)
        if (value > 0f) {
            Canvas(run).drawArc(
                RectF(centre - arcR, centre - arcR, centre + arcR, centre + arcR),
                -90f, value * 360f, false, line,
            )
        }

        if (lobes > 0) {
            val ringR = outer - bead - 1
            val filled = floor(value * lobes).toInt()
            val dot = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
            for (i in 0 until lobes) {
                val a = (i / lobes.toFloat()) * 2f * Math.PI.toFloat() - HALF_PI
                val x = centre + cos(a) * ringR
                val y = centre + sin(a) * ringR
                Canvas(if (i < filled) run else track).drawCircle(x, y, bead, dot)
            }
        }
        return RingMasks(track, run)
    }

    class RingMasks(val track: Bitmap, val run: Bitmap)

    /**
     * The inked run of the app's linear meter, from the leading edge — laid
     * over a rounded track the layout draws itself.
     *
     * Drawn rather than sized with `layout_weight` so the run can end
     * mid-pixel: a bar built from weights snaps to whole pixels and visibly
     * lies about small fractions.
     */
    fun progressRun(widthPx: Int, heightPx: Int, fraction: Float, rtl: Boolean): Bitmap {
        val w = widthPx.coerceAtLeast(8)
        val h = heightPx.coerceAtLeast(2)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val value = fraction.coerceIn(0f, 1f)
        if (value > 0f) {
            // Never narrower than the bar is tall, so a first step shows as a
            // dot rather than a sliver.
            val run = max(h.toFloat(), w * value)
            val rect = if (rtl) RectF(w - run, 0f, w.toFloat(), h.toFloat())
            else RectF(0f, 0f, run, h.toFloat())
            Canvas(bitmap).drawRoundRect(rect, h / 2f, h / 2f,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE })
        }
        return bitmap
    }

    private fun white(alpha: Float): Int = Color.argb((alpha * 255).toInt(), 255, 255, 255)

    private const val HALF_PI = (Math.PI / 2).toFloat()
}
