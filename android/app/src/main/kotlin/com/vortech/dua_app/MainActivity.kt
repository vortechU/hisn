package com.vortech.dua_app

import android.content.Intent
import android.hardware.GeomagneticField
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "hisn/adhan"
    private val geomagChannelName = "hisn/geomag"
    private val widgetChannelName = "hisn/widget"

    /**
     * Where a home-screen widget asked the app to open.
     *
     * Held rather than delivered straight away because a cold launch reaches
     * here long before Flutter is ready to navigate; Dart collects it with
     * `consumeRoute` once its navigator exists. A warm launch takes the other
     * path — [onNewIntent] pushes it, since nothing will ask again.
     */
    private var pendingRoute: String? = null
    private var widgetChannel: MethodChannel? = null

    /**
     * A widget tapped while the app is already running. The engine is live, so
     * hand the route over immediately instead of waiting to be asked.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val route = intent.getStringExtra(WidgetChrome.EXTRA_ROUTE) ?: return
        val channel = widgetChannel
        if (channel != null) {
            channel.invokeMethod("route", route)
        } else {
            pendingRoute = route
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingRoute = intent?.getStringExtra(WidgetChrome.EXTRA_ROUTE)

        // The live compass: heading, tilt, and how believable the reading is.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, Compass.CHANNEL)
            .setStreamHandler(Compass(this))

        // The Earth's field where the user is standing, from Android's built-in
        // World Magnetic Model. Two numbers come out of it: the declination
        // that turns a magnetic heading into a true one, and the field strength
        // the phone *should* be reading — which is how a compass sitting next
        // to something magnetic can be caught.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, geomagChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "field" -> {
                        val lat = call.argument<Double>("lat") ?: 0.0
                        val lng = call.argument<Double>("lng") ?: 0.0
                        val alt = call.argument<Double>("alt") ?: 0.0
                        val field = GeomagneticField(
                            lat.toFloat(),
                            lng.toFloat(),
                            alt.toFloat(),
                            System.currentTimeMillis()
                        )
                        result.success(
                            mapOf(
                                "declination" to field.declination.toDouble(),
                                // The model works in nanotesla, the sensor in
                                // microtesla. Match the sensor.
                                "strength" to field.fieldStrength.toDouble() / 1000.0
                            )
                        )
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

        // Home-screen widgets: store the latest config/labels and redraw.
        val widget = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            widgetChannelName,
        )
        widgetChannel = widget
        widget.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    @Suppress("UNCHECKED_CAST")
                    val data = call.argument<Map<String, String>>("data")
                        ?: emptyMap()
                    PrayerWidget.save(applicationContext, data)
                    PrayerWidget.refresh(applicationContext)
                    result.success(null)
                }
                // The destination a widget tap asked for, if this launch came
                // from one. Cleared as it is handed over so a later restore
                // (a rotation, say) does not navigate a second time.
                "consumeRoute" -> {
                    result.success(pendingRoute)
                    pendingRoute = null
                }
                else -> result.notImplemented()
            }
        }
    }
}
