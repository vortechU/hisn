package com.vortech.dua_app

import android.content.Context
import android.content.SharedPreferences

/**
 * The app's own `shared_preferences` store, as the platform sees it.
 *
 * Everything else the widgets need is *pushed* from Flutter into a private
 * store ([PrayerWidget.prefs]) and only read here. The tasbih widget is the
 * exception: it has to write, because a count tapped on the home screen and a
 * count tapped in the app are the same count, and a widget that kept its own
 * tally would quietly disagree with the screen it mirrors.
 *
 * The layout is the `shared_preferences` plugin's, not ours: one file named
 * `FlutterSharedPreferences`, every key prefixed `flutter.`, and Dart `int`
 * stored as a Java `long`. Reading it with [SharedPreferences.getInt] returns a
 * ClassCastException, which is worth knowing before debugging one.
 *
 * Writing from here means the Dart side's in-memory cache can be stale, so the
 * app reloads it when it comes back to the foreground — see the resume hook in
 * `TasbihController`. Without that, the first tap in the app would be computed
 * from a count taken before the widget's.
 */
object FlutterPrefs {

    private const val FILE = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."

    fun of(context: Context): SharedPreferences =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun getInt(context: Context, key: String, fallback: Int = 0): Int = try {
        of(context).getLong(PREFIX + key, fallback.toLong()).toInt()
    } catch (_: ClassCastException) {
        fallback
    }

    fun putInt(context: Context, key: String, value: Int) {
        of(context).edit().putLong(PREFIX + key, value.toLong()).apply()
    }

    fun getString(context: Context, key: String, fallback: String? = null): String? = try {
        of(context).getString(PREFIX + key, fallback)
    } catch (_: ClassCastException) {
        fallback
    }
}
