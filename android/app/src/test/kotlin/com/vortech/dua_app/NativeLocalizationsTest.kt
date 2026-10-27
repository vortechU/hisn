package com.vortech.dua_app

import android.content.Context
import android.text.Spanned
import android.text.style.TypefaceSpan
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class NativeLocalizationsTest {
    private lateinit var context: Context

    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        PrayerWidget.prefs(context).edit().clear().commit()
    }

    @Test fun everyBundledLanguageLoadsItsMetadataAndCatalogStrings() {
        val bundled = context.assets.open("flutter_assets/assets/data/native_localizations.json")
            .bufferedReader().use { JSONObject(it.readText()) }
        for (code in bundled.keys()) {
            val expected = bundled.getJSONObject(code)
            val language = NativeLocalizations.language(context, code)
            assertEquals(expected.getBoolean("rtl"), language.getBoolean("rtl"))
            val strings = expected.getJSONObject("strings")
            for (key in strings.keys()) {
                assertEquals(strings.getString(key), NativeLocalizations.text(context, code, key, "MISSING"))
            }
        }
    }

    @Test fun unknownLanguageFallsBackToEnglish() {
        assertEquals("Stop adhan", NativeLocalizations.text(context, "unknown", "stopAdhan", "MISSING"))
        assertFalse(NativeLocalizations.language(context, "unknown").getBoolean("rtl"))
    }

    @Test fun widgetDirectionFontAndDigitsFollowTheRegistry() {
        PrayerWidget.prefs(context).edit().putString("lang", "ur").commit()
        assertTrue(WidgetChrome.isRtlUi(context))
        assertFalse(WidgetChrome.isArabicUi(context))
        assertEquals("123", WidgetChrome.digits(context, 123))
        val text = WidgetChrome.ui(context, "اردو") as Spanned
        assertEquals("sans-serif", text.getSpans(0, text.length, TypefaceSpan::class.java).single().family)
        PrayerWidget.prefs(context).edit().putString("lang", "ar").commit()
        assertTrue(WidgetChrome.isRtlUi(context))
        assertTrue(WidgetChrome.isArabicUi(context))
        assertEquals("١٢٣", WidgetChrome.digits(context, 123))
        PrayerWidget.prefs(context).edit().putString("lang", "en").commit()
        assertFalse(WidgetChrome.isRtlUi(context))
        val english = WidgetChrome.ui(context, "English")
        assertTrue(english is String)
        assertEquals("English", english)
    }
}
