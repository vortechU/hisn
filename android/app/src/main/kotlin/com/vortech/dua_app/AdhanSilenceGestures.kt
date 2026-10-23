package com.vortech.dua_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.SystemClock
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.content.ContextCompat
import androidx.media.VolumeProviderCompat
import kotlin.math.abs

/**
 * The quick ways to silence a playing adhan without finding the notification:
 * press either volume button, or turn the phone face down on the table.
 *
 * Volume keys are caught twice over. A media session with its own volume
 * provider is handed the keys even on the lock screen, the way a music app's
 * are; and in case another session wins them, a change to any stream's volume
 * while the adhan plays counts as the same request. The activity's own key
 * handling in [MainActivity] still covers the app being open.
 *
 * Everything here lives only while the adhan plays: [start] when it begins,
 * [stop] when it ends, however it ends.
 */
class AdhanSilenceGestures(
    private val context: Context,
    private val onSilence: () -> Unit,
) {
    private var session: MediaSessionCompat? = null
    private var volumeReceiver: BroadcastReceiver? = null
    private var sensorListener: SensorEventListener? = null
    private var startedAt = 0L
    private var fired = false

    val sessionToken: MediaSessionCompat.Token? get() = session?.sessionToken

    fun start(flip: Boolean) {
        stop()
        fired = false
        startedAt = SystemClock.elapsedRealtime()
        startSession()
        startVolumeWatch()
        if (flip) startFlipWatch()
    }

    fun stop() {
        session?.run {
            isActive = false
            release()
        }
        session = null
        volumeReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        volumeReceiver = null
        sensorListener?.let { sensorManager()?.unregisterListener(it) }
        sensorListener = null
    }

    private fun silence() {
        if (fired) return
        fired = true
        onSilence()
    }

    private fun startSession() {
        val provider = object : VolumeProviderCompat(VOLUME_CONTROL_RELATIVE, 1, 1) {
            override fun onAdjustVolume(direction: Int) {
                // Zero is a request to show the volume panel, not a press.
                if (direction != 0) silence()
            }

            override fun onSetVolumeTo(volume: Int) = silence()
        }
        session = MediaSessionCompat(context, "HisnAdhan").apply {
            setPlaybackToRemote(provider)
            setPlaybackState(
                PlaybackStateCompat.Builder()
                    .setActions(PlaybackStateCompat.ACTION_STOP or PlaybackStateCompat.ACTION_PAUSE)
                    .setState(PlaybackStateCompat.STATE_PLAYING, 0, 1f)
                    .build()
            )
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onStop() = silence()
                override fun onPause() = silence()
            })
            isActive = true
        }
    }

    private fun startVolumeWatch() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (isInitialStickyBroadcast) return
                val now = intent.getIntExtra(EXTRA_VOLUME, -1)
                val before = intent.getIntExtra(EXTRA_PREV_VOLUME, -1)
                // A settle period: starting playback must not read as a press.
                if (SystemClock.elapsedRealtime() - startedAt < SETTLE_MS) return
                if (now != before) silence()
            }
        }
        ContextCompat.registerReceiver(
            context, receiver, IntentFilter(VOLUME_CHANGED), ContextCompat.RECEIVER_NOT_EXPORTED
        )
        volumeReceiver = receiver
    }

    private fun startFlipWatch() {
        val manager = sensorManager() ?: return
        val sensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
        val detector = FlipDetector()
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val (x, y, z) = Triple(event.values[0], event.values[1], event.values[2])
                if (detector.onSample(x, y, z, event.timestamp / 1_000_000)) silence()
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_UI)
        sensorListener = listener
    }

    private fun sensorManager(): SensorManager? =
        context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager

    companion object {
        // Not in the public SDK, but sent by every Android release since 4.0.
        private const val VOLUME_CHANGED = "android.media.VOLUME_CHANGED_ACTION"
        private const val EXTRA_VOLUME = "android.media.EXTRA_VOLUME_STREAM_VALUE"
        private const val EXTRA_PREV_VOLUME = "android.media.EXTRA_PREV_VOLUME_STREAM_VALUE"
        private const val SETTLE_MS = 1500L
    }
}

/**
 * Notices the phone being turned face down, from accelerometer samples.
 *
 * Only a *turn* counts: a phone already lying face down when the adhan starts
 * has to be seen the other way up first, or it would silence the adhan before
 * anyone had touched it. Face down must then hold for [holdMs], so the screen
 * tipping past flat in a hand on its way somewhere else doesn't count either.
 */
class FlipDetector(private val holdMs: Long = 400) {
    private var gx = Float.NaN
    private var gy = 0f
    private var gz = 0f
    private var armed = false
    private var downSince: Long? = null

    /** Feeds one sample in m/s² at [timeMs]; true once the turn is complete. */
    fun onSample(x: Float, y: Float, z: Float, timeMs: Long): Boolean {
        // A light low-pass leaves gravity and drops most of the hand's shake.
        if (gx.isNaN()) {
            gx = x; gy = y; gz = z
        } else {
            gx += SMOOTHING * (x - gx)
            gy += SMOOTHING * (y - gy)
            gz += SMOOTHING * (z - gz)
        }
        val faceDown = gz < -FACE_DOWN_Z && abs(gx) < LEVEL_XY && abs(gy) < LEVEL_XY
        if (!armed) {
            armed = gz > NOT_DOWN_Z
            return false
        }
        if (!faceDown) {
            downSince = null
            return false
        }
        val since = downSince ?: timeMs.also { downSince = it }
        return timeMs - since >= holdMs
    }

    private companion object {
        const val SMOOTHING = 0.3f
        const val FACE_DOWN_Z = 8f
        const val LEVEL_XY = 3.5f
        const val NOT_DOWN_Z = -2f
    }
}
