package com.vortech.dua_app

import android.content.Intent
import android.hardware.GeomagneticField
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "hisn/adhan"
    private val geomagChannelName = "hisn/geomag"
    private val widgetChannelName = "hisn/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Magnetic declination (true-north correction for the Qibla compass),
        // computed by Android's built-in World Magnetic Model. No dependency.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, geomagChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "declination" -> {
                        val lat = call.argument<Double>("lat") ?: 0.0
                        val lng = call.argument<Double>("lng") ?: 0.0
                        val alt = call.argument<Double>("alt") ?: 0.0
                        val field = GeomagneticField(
                            lat.toFloat(),
                            lng.toFloat(),
                            alt.toFloat(),
                            System.currentTimeMillis()
                        )
                        result.success(field.declination.toDouble())
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val alarms = call.argument<List<Map<String, Any>>>("alarms")
                            ?: emptyList()
                        AdhanScheduler.schedule(applicationContext, alarms)
                        result.success(null)
                    }
                    "cancelAll" -> {
                        AdhanScheduler.cancelAll(applicationContext)
                        result.success(null)
                    }
                    "playNow" -> {
                        AdhanPlayerService.start(
                            applicationContext,
                            call.argument<Boolean>("fajr") ?: false,
                            call.argument<String>("usage") ?: "notification"
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        try {
                            startService(
                                Intent(this, AdhanPlayerService::class.java)
                                    .apply { action = AdhanPlayerService.ACTION_STOP }
                            )
                        } catch (_: Exception) {
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Home-screen prayer widget: store the latest config/labels and redraw.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        @Suppress("UNCHECKED_CAST")
                        val data = call.argument<Map<String, String>>("data")
                            ?: emptyMap()
                        PrayerWidget.save(applicationContext, data)
                        PrayerWidget.refresh(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
