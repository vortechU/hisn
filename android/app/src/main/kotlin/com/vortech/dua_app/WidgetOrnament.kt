package com.vortech.dua_app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

/**
 * The manuscript ornaments, drawn for the home-screen widgets.
 *
 * RemoteViews can only fill, tint and stretch — it cannot run the app's
 * `CustomPainter`s. So the marks that carry the identity (the lobed verse
 * rosette, the bead meter on the tasbih) are drawn here onto small bitmaps and
 * handed over with `setImageViewBitmap`. The geometry is a straight port of
 * `lib/widgets/ornament.dart`; if one side changes the other should follow, or
 * the widget stops looking like the app.
 *
 * Every bitmap here is at most a couple of hundred pixels square. That matters:
 * everything a provider sends crosses a Binder transaction with a hard ~1 MB
 * ceiling shared by the whole update, and a full-bleed background bitmap would
 * sail past it.
 */
object WidgetOrnament {

    /**
     * A lobed verse-rosette — the mark that separates āyāt in a mushaf.
     *
     * Used here as a bullet and a completion tick, never wrapped around an
     * icon (the app made that mistake once and every row turned into a
     * medallion).
     */
    fun rosette(
        sizePx: Int,
        color: Int,
        lobes: Int = 8,
        filled: Boolean = false,
    ): Bitmap {
        val size = sizePx.coerceAtLeast(8)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val centre = size / 2f
        val outer = size / 2f
        val ring = outer * 0.74f
        val lobe = ring * sin(Math.PI / lobes).toFloat() * 1.05f

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.STROKE
            strokeWidth = max(0.8f, outer * 0.075f)
        }

        for (i in 0 until lobes) {
            val a = (i / lobes.toFloat()) * 2f * Math.PI.toFloat() - HALF_PI
            canvas.drawCircle(
                centre + cos(a) * ring,
                centre + sin(a) * ring,
                lobe,
                stroke,
            )
        }

        val inner = ring - lobe * 0.35f
        if (filled) {
            canvas.drawCircle(centre, centre, inner, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = WidgetTheme.fade(color, 0.16f)
            })
        }
        canvas.drawCircle(centre, centre, inner, stroke)
        return bitmap
    }

    /**
     * The bead meter: a round counter that illuminates as a count advances.
     *
     * It reads twice, exactly as it does on the Tasbih screen — a continuous
     * arc for the precise fraction, and beads that ink in one at a time so
     * partial progress stays countable at a glance. That double reading is the
     * whole point on a home screen, where the numeral is small.
     */
    fun beadMeter(
        sizePx: Int,
        fraction: Float,
        color: Int,
        track: Int,
        lobes: Int = 11,
    ): Bitmap {
        val size = sizePx.coerceAtLeast(24)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val value = fraction.coerceIn(0f, 1f)
        val centre = size / 2f
        val outer = size / 2f
        val ring = outer * 0.80f
        val lobe = if (lobes == 0) 0f else ring * sin(Math.PI / lobes).toFloat()
        val weight = max(1f, outer * 0.055f)

        val rail = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = track
            style = Paint.Style.STROKE
            strokeWidth = weight
        }
        val inked = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.STROKE
            strokeWidth = weight
        }
        val solid = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = WidgetTheme.fade(color, 0.22f)
        }

        val done = (value * lobes).toInt()
        for (i in 0 until lobes) {
            val a = (i / lobes.toFloat()) * 2f * Math.PI.toFloat() - HALF_PI
            val x = centre + cos(a) * ring
            val y = centre + sin(a) * ring
            val inkedBead = i < done
            if (inkedBead) canvas.drawCircle(x, y, lobe, solid)
            canvas.drawCircle(x, y, lobe, if (inkedBead) inked else rail)
        }

        // The exact fraction, as an arc — just inside the beads when there are
        // any, otherwise out at the rim on its own.
        val arcR = if (lobes == 0) ring else ring - lobe - weight
        if (arcR > 0) {
            canvas.drawCircle(centre, centre, arcR, rail)
            if (value > 0f) {
                canvas.drawArc(
                    RectF(centre - arcR, centre - arcR, centre + arcR, centre + arcR),
                    -90f,
                    value * 360f,
                    false,
                    Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        this.color = color
                        style = Paint.Style.STROKE
                        strokeWidth = weight * 1.2f
                        strokeCap = Paint.Cap.BUTT
                    },
                )
            }
        }
        return bitmap
    }

    /**
     * A ruled progress bar: a hairline rail with the run inked over it.
     *
     * Drawn rather than assembled from two weighted views so the inked run can
     * end mid-pixel — a progress bar built from `layout_weight` snaps to whole
     * pixels and visibly lies about small fractions.
     */
    fun progressRule(
        widthPx: Int,
        heightPx: Int,
        fraction: Float,
        color: Int,
        track: Int,
    ): Bitmap {
        val w = widthPx.coerceAtLeast(8)
        val h = heightPx.coerceAtLeast(2)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val value = fraction.coerceIn(0f, 1f)
        val mid = h / 2f
        val rail = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = track
            style = Paint.Style.STROKE
            strokeWidth = h * 0.32f
        }
        canvas.drawLine(0f, mid, w.toFloat(), mid, rail)
        if (value > 0f) {
            canvas.drawLine(0f, mid, w * value, mid, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                style = Paint.Style.STROKE
                strokeWidth = h.toFloat()
                strokeCap = Paint.Cap.BUTT
            })
        }
        return bitmap
    }

    /**
     * A single hairline rule with a rosette set into the middle of it — the
     * divider the app uses to separate a heading from what it heads.
     */
    fun ruleWithRosette(
        widthPx: Int,
        heightPx: Int,
        color: Int,
        ruleColor: Int,
    ): Bitmap {
        val w = widthPx.coerceAtLeast(24)
        val h = heightPx.coerceAtLeast(8)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val mid = h / 2f
        val gap = h * 0.9f
        val hair = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = ruleColor
            style = Paint.Style.STROKE
            strokeWidth = max(1f, h * 0.06f)
        }
        canvas.drawLine(0f, mid, w / 2f - gap, mid, hair)
        canvas.drawLine(w / 2f + gap, mid, w.toFloat(), mid, hair)

        val mark = rosette(h, color, lobes = 6, filled = true)
        canvas.drawBitmap(mark, w / 2f - h / 2f, 0f, null)
        mark.recycle()
        return bitmap
    }

    private const val HALF_PI = (Math.PI / 2).toFloat()
}
