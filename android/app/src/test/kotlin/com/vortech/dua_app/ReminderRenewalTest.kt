package com.vortech.dua_app

import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.shadow.api.Shadow
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [31])
class ReminderRenewalTest {
    private lateinit var context: Context
    private lateinit var scheduler: JobScheduler

    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        scheduler.cancelAll()
        FlutterPrefs.of(context).edit().clear().commit()
        ReminderRenewal.leaveForeground()
    }

    @Test fun renewalIsPeriodicPersistedAndRequiresNoNetworkOrCharging() {
        ReminderRenewal.configure(context, true)
        val job = scheduler.allPendingJobs.single()
        assertEquals(ReminderRenewal.JOB_ID, job.id)
        assertTrue(job.isPeriodic)
        assertTrue(job.isPersisted)
        assertEquals(TimeUnit.HOURS.toMillis(12), job.intervalMillis)
        assertEquals(0, job.networkType)
        assertFalse(job.isRequireCharging)
    }

    @Test fun repeatedConfigDoesNotCreateDuplicateJobs() {
        repeat(5) { ReminderRenewal.configure(context, true) }
        assertEquals(1, scheduler.allPendingJobs.size)
    }

    @Test fun anyReminderKindRenewsAndDisablingCancelsBothJobs() {
        for (key in listOf("notif_master_enabled", "notif_daily_remembrance", "notif_fasting_reminders")) {
            FlutterPrefs.of(context).edit().clear().putBoolean("flutter.$key", true).commit()
            assertTrue(ReminderRenewal.hasWork(context))
            ReminderRenewal.afterBoot(context)
            assertEquals(setOf(ReminderRenewal.JOB_ID, ReminderRenewal.BOOT_JOB_ID),
                scheduler.allPendingJobs.map { it.id }.toSet())
            ReminderRenewal.configure(context, false)
            assertTrue(scheduler.allPendingJobs.isEmpty())
        }
    }

    @Test fun bootDoesNotRenewWhenAllRemindersAreOff() {
        ReminderRenewal.afterBoot(context)
        assertTrue(scheduler.allPendingJobs.isEmpty())
    }

    @Test fun backgroundEngineDoesNotStartForDisabledOrForegroundApp() {
        val service = Robolectric.buildService(ReminderRenewalJobService::class.java).create().get()
        val parameters = Shadow.newInstanceOf(JobParameters::class.java)
        assertFalse(service.onStartJob(parameters))
        FlutterPrefs.of(context).edit().putBoolean("flutter.notif_master_enabled", true).commit()
        ReminderRenewal.enterForeground()
        assertFalse(service.onStartJob(parameters))
        assertNull(ReminderRenewalJobService.active)
        ReminderRenewal.leaveForeground()
    }

    @Test fun onlyAndroidCanBindTheJobService() {
        val service = context.packageManager.getServiceInfo(
            ComponentName(context, ReminderRenewalJobService::class.java), PackageManager.GET_META_DATA)
        assertEquals("android.permission.BIND_JOB_SERVICE", service.permission)
    }
}
