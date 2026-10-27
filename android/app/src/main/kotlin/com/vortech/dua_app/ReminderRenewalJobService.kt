package com.vortech.dua_app

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
import net.wolverinebeach.flutter_timezone.FlutterTimezonePlugin

/** A bounded headless run of the existing reminder planner, without a view. */
class ReminderRenewalJobService : JobService() {
    companion object {
        var active: ReminderRenewalJobService? = null
            private set
    }

    private val handler = Handler(Looper.getMainLooper())
    private var parameters: JobParameters? = null
    private var engine: FlutterEngine? = null
    private var renewalChannel: MethodChannel? = null
    private var adhanChannel: MethodChannel? = null
    private val timeout = Runnable { finish(true) }

    override fun onStartJob(params: JobParameters): Boolean {
        if (!ReminderRenewal.hasWork(this)) {
            ReminderRenewal.configure(this, false)
            return false
        }
        if (ReminderRenewal.foreground || parameters != null) return false
        parameters = params
        active = this
        handler.post { startEngine() }
        return true
    }

    private fun startEngine() {
        if (parameters == null) return
        handler.postDelayed(timeout, 60_000)
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            // Register only what renewal uses. In particular, this engine must
            // not attach to the UI engine's audio session or device sensors.
            val worker = FlutterEngine(applicationContext, null, false)
            engine = worker
            worker.plugins.add(SharedPreferencesPlugin())
            worker.plugins.add(FlutterLocalNotificationsPlugin())
            worker.plugins.add(FlutterTimezonePlugin())
            val messenger = worker.dartExecutor.binaryMessenger
            renewalChannel = ReminderRenewal.attach(applicationContext, messenger) { success ->
                // Send the reply before destroying the channel/engine.
                handler.post { finish(!success) }
            }
            adhanChannel = MethodChannel(messenger, "hisn/adhan").also { channel ->
                channel.setMethodCallHandler { call, result ->
                    try {
                        when (call.method) {
                            "schedule" -> {
                                val alarms = call.argument<List<Map<String, Any>>>("alarms") ?: emptyList()
                                AdhanScheduler.schedule(applicationContext, alarms)
                                result.success(null)
                            }
                            "cancelAll" -> {
                                AdhanScheduler.cancelAll(applicationContext)
                                result.success(null)
                            }
                            else -> result.notImplemented()
                        }
                    } catch (error: Exception) {
                        result.error("reminder_adhan", error.message, null)
                    }
                }
            }
            worker.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "renewReminders"))
        } catch (error: Exception) {
            Log.e("ReminderRenewal", "Could not renew reminders", error)
            finish(true)
        }
    }

    fun finish(retry: Boolean) {
        val params = parameters ?: return
        cleanup()
        jobFinished(params, retry)
    }

    private fun cleanup() {
        parameters = null
        if (active === this) active = null
        handler.removeCallbacks(timeout)
        renewalChannel?.setMethodCallHandler(null)
        adhanChannel?.setMethodCallHandler(null)
        renewalChannel = null
        adhanChannel = null
        engine?.destroy()
        engine = null
    }

    override fun onStopJob(params: JobParameters): Boolean {
        cleanup()
        return true
    }

    override fun onDestroy() {
        cleanup()
        super.onDestroy()
    }
}
