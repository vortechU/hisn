package com.vortech.dua_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * A foreground service that plays the adhan once, then stops itself. Used so the
 * full call to prayer plays reliably even when the app is closed — instead of
 * leaning on a notification channel's custom sound, which some OEMs (MIUI) drop.
 */
class AdhanPlayerService : Service() {
    private var player: MediaPlayer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopEverything()
            return START_NOT_STICKY
        }

        val fajr = intent?.getBooleanExtra(EXTRA_FAJR, false) ?: false
        val usage = intent?.getStringExtra(EXTRA_USAGE) ?: "notification"

        try {
            startInForeground()
        } catch (e: Exception) {
            Log.e(TAG, "startForeground threw", e)
        }
        play(fajr, usage)
        return START_NOT_STICKY
    }

    private fun startInForeground() {
        val mgr = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Adhan playback", NotificationManager.IMPORTANCE_LOW
            ).apply { setSound(null, null) }
            mgr.createNotificationChannel(channel)
        }

        val stopPi = PendingIntent.getService(
            this, 1,
            Intent(this, AdhanPlayerService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPi = openIntent?.let {
            PendingIntent.getActivity(
                this, 2, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("الأذان · Adhan")
            .setContentText("Playing the call to prayer")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPi)
        if (openPi != null) builder.setContentIntent(openPi)

        val notif = builder.build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIF_ID, notif)
        }
    }

    private fun play(fajr: Boolean, usage: String) {
        try {
            player?.release()
            // Static R.raw reference (not getIdentifier-by-name): gives the exact
            // resource id and, critically, forces the release optimizer to KEEP
            // the audio in the APK. A dynamic name lookup made the shrinker think
            // these were unused, so it stripped them (resId resolved to 0).
            val resId = if (fajr) R.raw.adhan_fajr else R.raw.adhan1
            if (resId == 0) {
                Log.e(TAG, "raw resource missing — aborting")
                stopEverything()
                return
            }
            val uri = Uri.parse("android.resource://$packageName/$resId")
            val attrs = AudioAttributes.Builder()
                .setUsage(usageToInt(usage))
                .setContentType(
                    if (usage == "media") AudioAttributes.CONTENT_TYPE_MUSIC
                    else AudioAttributes.CONTENT_TYPE_SONIFICATION
                )
                .build()
            player = MediaPlayer().apply {
                setAudioAttributes(attrs)
                setDataSource(this@AdhanPlayerService, uri)
                setOnCompletionListener { stopEverything() }
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                    stopEverything(); true
                }
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e(TAG, "play() threw", e)
            stopEverything()
        }
    }

    private fun usageToInt(usage: String): Int = when (usage) {
        "media" -> AudioAttributes.USAGE_MEDIA
        "alarm" -> AudioAttributes.USAGE_ALARM
        else -> AudioAttributes.USAGE_NOTIFICATION
    }

    private fun stopEverything() {
        try {
            player?.stop()
        } catch (_: Exception) {
        }
        player?.release()
        player = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        player?.release()
        player = null
        super.onDestroy()
    }

    companion object {
        const val TAG = "AdhanPlayer"
        const val ACTION_STOP = "com.vortech.dua_app.ADHAN_STOP"
        const val EXTRA_FAJR = "fajr"
        const val EXTRA_USAGE = "usage"
        const val CHANNEL_ID = "adhan_playback"
        const val NOTIF_ID = 73101

        fun start(context: android.content.Context, fajr: Boolean, usage: String) {
            val i = Intent(context, AdhanPlayerService::class.java).apply {
                putExtra(EXTRA_FAJR, fajr)
                putExtra(EXTRA_USAGE, usage)
            }
            try {
                ContextCompat.startForegroundService(context, i)
            } catch (e: Exception) {
                Log.e(TAG, "startForegroundService threw", e)
            }
        }
    }
}
