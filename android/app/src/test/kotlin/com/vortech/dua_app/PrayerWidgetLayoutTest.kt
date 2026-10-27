package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.os.Bundle
import android.view.View
import android.widget.TextView
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

/** Inflate the real RemoteViews and exercise launcher resizing, including reuse. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], qualifiers = "w400dp-h800dp-xhdpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class PrayerWidgetLayoutTest {
    private lateinit var context: Context
    private lateinit var manager: AppWidgetManager

    @Before fun setUp() {
        context = RuntimeEnvironment.getApplication()
        manager = AppWidgetManager.getInstance(context)
        PrayerWidget.prefs(context).edit().clear()
            .putString("lat", "24.7136").putString("lng", "46.6753")
            .putString("label", "Riyadh").putString("hijri", "11 Jumada al-Ula 1448 AH")
            .putString("theme_mode", "light").commit()
    }

    private fun resize(id: Int, width: Int, height: Int): View {
        manager.updateAppWidgetOptions(id, Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, height)
        })
        PrayerWidgetProvider().onAppWidgetOptionsChanged(context, manager, id, null)
        return shadowOf(manager).getViewFor(id).apply {
            measure(View.MeasureSpec.makeMeasureSpec(WidgetChrome.dp(context, width.toFloat()), View.MeasureSpec.EXACTLY),
                View.MeasureSpec.makeMeasureSpec(WidgetChrome.dp(context, height.toFloat()), View.MeasureSpec.EXACTLY))
            layout(0, 0, measuredWidth, measuredHeight)
        }
    }

    private fun newWidget(): Int = shadowOf(manager)
        .createWidget(PrayerWidgetProvider::class.java, R.layout.prayer_widget)

    private fun assertTimesFit(view: View) {
        for (id in intArrayOf(R.id.name_fajr, R.id.name_dhuhr, R.id.name_asr,
            R.id.name_maghrib, R.id.name_isha, R.id.time_fajr, R.id.time_dhuhr,
            R.id.time_asr, R.id.time_maghrib, R.id.time_isha)) {
            val text = view.findViewById<TextView>(id)
            val bounds = Rect()
            assertTrue("${text.text} must be visible", text.getGlobalVisibleRect(bounds))
            assertEquals("${text.text} must fit vertically", text.height, bounds.height())
            assertTrue("${text.text} must fit its column", text.layout.getLineWidth(0) <= text.width + 1)
        }
    }

    private fun capture(view: View, name: String) {
        val directory = System.getProperty("hisn.widgetPreviewDir") ?: return
        val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
        view.draw(Canvas(bitmap))
        File(directory).apply { mkdirs() }.resolve("$name.png").outputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        bitmap.recycle()
    }

    @Test fun oneRowKeepsAllFiveTimesAndNextHighlight() {
        val view = resize(newWidget(), 360, 50)
        assertEquals(View.GONE, view.findViewById<View>(R.id.prayer_head).visibility)
        assertEquals(View.GONE, view.findViewById<View>(R.id.track_fajr).visibility)
        assertTimesFit(view)
        val lifts = intArrayOf(R.id.lift_fajr, R.id.lift_dhuhr, R.id.lift_asr,
            R.id.lift_maghrib, R.id.lift_isha)
        val data = PrayerWidget.compute(context)
        assertEquals(if (data.nextTime in data.times.orEmpty()) 1 else 0,
            lifts.count { view.findViewById<View>(it).visibility == View.VISIBLE })
        capture(view, "compact-en")
    }

    @Test fun resizingRevealsContextThenReturnsToOneRow() {
        val id = newWidget()
        val timeline = resize(id, 360, 100)
        assertEquals(View.GONE, timeline.findViewById<View>(R.id.prayer_head).visibility)
        assertEquals(View.VISIBLE, timeline.findViewById<View>(R.id.track_fajr).visibility)
        assertTimesFit(timeline)
        capture(timeline, "timeline-en")

        val expanded = resize(id, 360, 160)
        assertEquals(View.VISIBLE, expanded.findViewById<View>(R.id.prayer_head).visibility)
        assertTimesFit(expanded)
        capture(expanded, "expanded-en")

        val compact = resize(id, 360, 50)
        assertEquals(View.GONE, compact.findViewById<View>(R.id.prayer_head).visibility)
        assertTimesFit(compact)
    }

    @Test fun firstUpdateWithoutLauncherOptionsIsCompact() {
        val view = shadowOf(manager).getViewFor(newWidget())
        assertEquals(View.GONE, view.findViewById<View>(R.id.prayer_head).visibility)
        assertEquals(View.GONE, view.findViewById<View>(R.id.track_fajr).visibility)
    }

    @Test fun missingLocationLeavesTimesUnsetWithoutHighlightingAPrayer() {
        PrayerWidget.prefs(context).edit().remove("lat").remove("lng").commit()
        val view = resize(newWidget(), 360, 50)
        assertEquals("—", view.findViewById<TextView>(R.id.time_fajr).text.toString())
        assertEquals(View.INVISIBLE, view.findViewById<View>(R.id.lift_fajr).visibility)
        assertTimesFit(view)
    }

    @Test fun largerSystemTextStillFitsOneRow() {
        RuntimeEnvironment.setFontScale(1.3f)
        val view = resize(newWidget(), 400, 50)
        assertTimesFit(view)
        assertEquals(View.GONE, view.findViewById<View>(R.id.track_fajr).visibility)
        capture(view, "compact-large-text")
    }

    @Test fun arabicAndDarkKeepTheSameCompactStructure() {
        PrayerWidget.prefs(context).edit().putString("lang", "ar")
            .putString("name_fajr", "الفجر").putString("name_dhuhr", "الظهر")
            .putString("name_asr", "العصر").putString("name_maghrib", "المغرب")
            .putString("name_isha", "العشاء").putString("am", "ص").putString("pm", "م")
            .putString("theme_mode", "dark").commit()
        val view = resize(newWidget(), 360, 64)
        assertTimesFit(view)
        assertEquals(View.LAYOUT_DIRECTION_RTL, view.layoutDirection)
        capture(view, "compact-ar-dark")
    }
}
