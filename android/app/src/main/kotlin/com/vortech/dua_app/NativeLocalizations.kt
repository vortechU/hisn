package com.vortech.dua_app

import android.content.Context
import android.util.Log
import org.json.JSONObject

/** Generated from Flutter's language registry and UI catalogs, available offline. */
object NativeLocalizations {
    private var catalog: JSONObject? = null

    @Synchronized
    private fun catalog(context: Context): JSONObject {
        catalog?.let { return it }
        val loaded = try {
            context.assets.open("flutter_assets/assets/data/native_localizations.json")
                .bufferedReader().use { JSONObject(it.readText()) }
        } catch (error: Exception) {
            Log.e("NativeLocalizations", "Could not load bundled localizations", error)
            JSONObject()
        }
        catalog = loaded
        return loaded
    }

    fun language(context: Context, code: String?): JSONObject {
        val all = catalog(context)
        return all.optJSONObject(code ?: "en") ?: all.optJSONObject("en") ?: JSONObject()
    }

    fun text(context: Context, code: String?, key: String, fallback: String): String =
        language(context, code).optJSONObject("strings")?.optString(key, fallback) ?: fallback
}
