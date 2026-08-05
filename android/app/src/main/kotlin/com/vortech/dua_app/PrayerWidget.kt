package com.vortech.dua_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.CalculationParameters
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.data.DateComponents
import java.util.Calendar
import java.util.Date

/** Today's prayer info, computed natively for the home-screen widgets. */
data class PrayerWidgetData(
    val label: String,
    val hijri: String,
    val names: List<String>,
    /** Today's five times, or null when the app hasn't pushed a location yet. */
    val times: List<Date>?,
    /** Index (0..4) of the next prayer; falls back to 0 (Fajr) once all pass. */
    val nextIndex: Int,
    /** Actual moment of the next prayer (tomorrow's Fajr once today's all pass). */
    val nextTime: Date?,
    val am: String,
    val pm: String,
)

/**
 * Storage + computation helpers for the home-screen prayer widgets.
 *
 * Flutter pushes the location + calculation settings + localized labels down via
 * the `hisn/widget` MethodChannel (see [MainActivity]); we persist them here so
 * [PrayerWidgetProvider] / [PrayerWidgetSmallProvider] can recompute the times
 * (via the Adhan library) and redraw at any time, even when the app is gone.
 */
object PrayerWidget {
    private const val PREFS = "prayer_widget"

    // Must match SunnahCalendarRules.minOffset/maxOffset on the Dart side.
    private const val MIN_HIJRI_OFFSET = -2
    private const val MAX_HIJRI_OFFSET = 2

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Persist the latest config/labels coming from Flutter. */
    fun save(context: Context, data: Map<String, String>) {
        val editor = prefs(context).edit()
        for ((key, value) in data) editor.putString(key, value)
        editor.apply()
    }

    /** Redraw every instance of both widget sizes. */
    fun refresh(context: Context) {
        refreshProvider(context, PrayerWidgetProvider::class.java)
        refreshProvider(context, PrayerWidgetSmallProvider::class.java)
    }

    private fun refreshProvider(context: Context, cls: Class<*>) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val ids = manager.getAppWidgetIds(ComponentName(context, cls))
        if (ids.isEmpty()) return
        val intent = Intent(context, cls).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        context.sendBroadcast(intent)
    }

    /** Read config + compute today's prayer times for rendering. */
    fun compute(context: Context): PrayerWidgetData {
        val p = prefs(context)
        val label = p.getString("label", "Hisn") ?: "Hisn"
        val am = p.getString("am", "AM") ?: "AM"
        val pm = p.getString("pm", "PM") ?: "PM"
        val names = listOf(
            p.getString("name_fajr", "Fajr") ?: "Fajr",
            p.getString("name_dhuhr", "Dhuhr") ?: "Dhuhr",
            p.getString("name_asr", "Asr") ?: "Asr",
            p.getString("name_maghrib", "Maghrib") ?: "Maghrib",
            p.getString("name_isha", "Isha") ?: "Isha",
        )
        val hijri = hijriDate(p)

        val lat = p.getString("lat", null)?.toDoubleOrNull()
        val lng = p.getString("lng", null)?.toDoubleOrNull()
        if (lat == null || lng == null) {
            return PrayerWidgetData(label, hijri, names, null, 0, null, am, pm)
        }

        val coords = Coordinates(lat, lng)
        val params = paramsFor(p.getString("method", "umm_al_qura")).apply {
            madhab = madhabFor(p.getString("madhab", "shafi"))
        }
        val now = Date()
        val today = dateComponents(now)
        val pt = PrayerTimes(coords, today, params)
        val times = listOf(pt.fajr, pt.dhuhr, pt.asr, pt.maghrib, pt.isha)

        var nextIndex = times.indexOfFirst { it.after(now) }
        val nextTime: Date
        if (nextIndex < 0) {
            // All of today's prayers have passed — next is tomorrow's Fajr.
            val tomorrow = Calendar.getInstance().apply {
                time = now
                add(Calendar.DAY_OF_MONTH, 1)
            }.time
            nextTime = PrayerTimes(coords, dateComponents(tomorrow), params).fajr
            nextIndex = 0
        } else {
            nextTime = times[nextIndex]
        }
        return PrayerWidgetData(label, hijri, names, times, nextIndex, nextTime, am, pm)
    }

    private fun dateComponents(date: Date): DateComponents {
        val c = Calendar.getInstance().apply { time = date }
        return DateComponents(
            c.get(Calendar.YEAR),
            c.get(Calendar.MONTH) + 1,
            c.get(Calendar.DAY_OF_MONTH),
        )
    }

    /**
     * The Hijri date. Computed natively (Umm al-Qura via ICU) so it advances at
     * midnight without the app, using the localized month names Flutter pushed.
     * Falls back to the Flutter-rendered string when ICU isn't available.
     *
     * The user's sighting offset is applied here as well as in the app. The
     * calculated date can run a day either side of a local sighting, and the
     * widget sits next to the app on the same screen — if only one of them
     * honoured the adjustment they would visibly disagree.
     */
    private fun hijriDate(p: SharedPreferences): String {
        // Already carries the offset: Flutter rendered it before pushing.
        val fallback = p.getString("hijri", "") ?: ""
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return fallback
        return try {
            val cal = android.icu.util.IslamicCalendar().apply {
                calculationType = android.icu.util.IslamicCalendar.CalculationType.ISLAMIC_UMALQURA
                timeInMillis = shiftedNow(hijriOffset(p))
            }
            val day = cal.get(android.icu.util.Calendar.DAY_OF_MONTH)
            val monthIndex = cal.get(android.icu.util.Calendar.MONTH) // 0-based
            val year = cal.get(android.icu.util.Calendar.YEAR)
            val months = (p.getString("hijri_months", "") ?: "").split("|")
            val month = months.getOrNull(monthIndex)?.takeIf { it.isNotBlank() }
                ?: return fallback
            val suffix = p.getString("hijri_suffix", "") ?: ""
            "$day $month $year $suffix".trim()
        } catch (_: Exception) {
            fallback
        }
    }

    /**
     * The stored sighting adjustment, in days. Clamped to the same range the
     * app offers, so a malformed or stale value can't push the widget somewhere
     * the app would never go. Absent (an install predating the setting) is 0.
     */
    private fun hijriOffset(p: SharedPreferences): Int =
        (p.getString("hijri_offset", null)?.toIntOrNull() ?: 0)
            .coerceIn(MIN_HIJRI_OFFSET, MAX_HIJRI_OFFSET)

    /**
     * Now, moved by [offsetDays], for converting to a Hijri date.
     *
     * Pinned to midday before the days are added — the same thing the Dart side
     * does. Adding a day's worth of milliseconds outright would land on a
     * skipped or repeated hour across a daylight-saving change and could come
     * out on the wrong calendar day.
     */
    private fun shiftedNow(offsetDays: Int): Long =
        Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, 12)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_MONTH, offsetDays)
        }.timeInMillis

    private fun paramsFor(method: String?): CalculationParameters = when (method) {
        "muslim_world_league" -> CalculationMethod.MUSLIM_WORLD_LEAGUE.parameters
        "egyptian" -> CalculationMethod.EGYPTIAN.parameters
        "karachi" -> CalculationMethod.KARACHI.parameters
        "umm_al_qura" -> CalculationMethod.UMM_AL_QURA.parameters
        "dubai" -> CalculationMethod.DUBAI.parameters
        "qatar" -> CalculationMethod.QATAR.parameters
        "kuwait" -> CalculationMethod.KUWAIT.parameters
        "moon_sighting_committee" -> CalculationMethod.MOON_SIGHTING_COMMITTEE.parameters
        "singapore" -> CalculationMethod.SINGAPORE.parameters
        "north_america" -> CalculationMethod.NORTH_AMERICA.parameters
        // Not enum constants in the Java library — use their published angles.
        "turkey" -> CalculationParameters(18.0, 17.0)
        "tehran" -> CalculationParameters(17.7, 14.0)
        else -> CalculationMethod.UMM_AL_QURA.parameters
    }

    private fun madhabFor(madhab: String?): Madhab =
        if (madhab == "hanafi") Madhab.HANAFI else Madhab.SHAFI
}
