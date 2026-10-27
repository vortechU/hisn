package com.vortech.dua_app

import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

/** Refill the three-day window every twelve hours, independently of app opens. */
object ReminderRenewal {
    const val JOB_ID = 98210
    const val BOOT_JOB_ID = 98211
    const val CHANNEL = "hisn/reminder_renewal"
    val intervalMillis = TimeUnit.HOURS.toMillis(12)
    var foreground = false
        private set

    fun hasWork(context: Context): Boolean =
        FlutterPrefs.getBoolean(context, "notif_master_enabled", false) ||
            FlutterPrefs.getBoolean(context, "notif_daily_remembrance", false) ||
            FlutterPrefs.getBoolean(context, "notif_fasting_reminders", false)

    fun configure(context: Context, enabled: Boolean) {
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        if (!enabled) {
            scheduler.cancel(JOB_ID)
            scheduler.cancel(BOOT_JOB_ID)
            return
        }
        // Do not reset an existing period on every progress/settings update.
        if (scheduler.allPendingJobs.any { it.id == JOB_ID }) return
        val job = JobInfo.Builder(JOB_ID, ComponentName(context, ReminderRenewalJobService::class.java))
            .setPeriodic(intervalMillis)
            .setPersisted(true)
            .setBackoffCriteria(TimeUnit.MINUTES.toMillis(15), JobInfo.BACKOFF_POLICY_EXPONENTIAL)
            .build()
        check(scheduler.schedule(job) == JobScheduler.RESULT_SUCCESS) { "Reminder renewal was not scheduled" }
    }

    /** A long power-off can exhaust the old window: do not wait twelve hours. */
    fun afterBoot(context: Context) {
        val enabled = hasWork(context)
        configure(context, enabled)
        if (!enabled) return
        val job = JobInfo.Builder(BOOT_JOB_ID, ComponentName(context, ReminderRenewalJobService::class.java))
            .setOverrideDeadline(TimeUnit.MINUTES.toMillis(30))
            .build()
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        scheduler.schedule(job)
    }

    fun enterForeground() {
        foreground = true
        // Foreground startup owns rescheduling from this point. Stop the old
        // engine before it can race a settings change or backup restore.
        ReminderRenewalJobService.active?.finish(false)
    }

    fun leaveForeground() { foreground = false }

    fun attach(context: Context, messenger: BinaryMessenger,
               complete: ((Boolean) -> Unit)? = null): MethodChannel =
        MethodChannel(messenger, CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "configure" -> {
                            configure(context, call.argument<Boolean>("enabled") == true)
                            result.success(null)
                        }
                        "complete" -> {
                            result.success(null)
                            complete?.invoke(call.argument<Boolean>("success") == true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("reminder_renewal", error.message, null)
                }
            }
        }
}
