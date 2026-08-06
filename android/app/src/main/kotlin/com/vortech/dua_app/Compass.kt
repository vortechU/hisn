package com.vortech.dua_app

import android.app.Activity
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.SystemClock
import android.view.Surface
import android.view.WindowManager
import io.flutter.plugin.common.EventChannel
import kotlin.math.sqrt

/**
 * The device's magnetic heading, how far it is tilted, and how strong a field
 * it is reading — the three things that decide whether a Qibla needle can be
 * believed.
 *
 * Written natively rather than taken from a compass plugin, because the two
 * failure modes that actually mislead someone looking for the Qibla are both
 * invisible from the Flutter side:
 *
 *  * **Whose accuracy is being reported?** Android reports accuracy per sensor,
 *    through one shared callback. The accelerometer is almost always HIGH; the
 *    magnetometer is the one that drifts. A listener that keeps the last value
 *    from whichever sensor fired reports the accelerometer's confidence about
 *    the magnetometer's error — so a compass forty degrees out still claims to
 *    be fine, and the user is never told to calibrate. Only the magnetometer
 *    and the fused rotation vector are consulted here, and the worse of the two
 *    wins.
 *  * **Which way is "forward"?** Azimuth is only meaningful for a phone lying
 *    flat: held upright, the top edge points at the sky and the value collapses.
 *    Remapping the axes once the tilt passes some threshold papers over that by
 *    silently changing what the number means half way through a turn. This
 *    reports one frame always — the phone flat, top edge forward — and hands
 *    the tilt to the UI to explain.
 *
 * The readings are raw. Whether a given one is trustworthy is decided on the
 * Dart side, where the thresholds can be tested.
 */
class Compass(private val activity: Activity) : EventChannel.StreamHandler, SensorEventListener {

    private val sensors =
        activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    private val rotationSensor: Sensor? =
        sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val magnetometer: Sensor? =
        sensors.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    private val accelerometer: Sensor? =
        sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    private var sink: EventChannel.EventSink? = null

    private val rotationVector = FloatArray(4)
    private var rotationLength = 0
    private var hasRotation = false
    private val gravity = FloatArray(3)
    private var hasGravity = false
    private val magnetic = FloatArray(3)
    private var hasMagnetic = false

    // Null until the sensor has actually told us. A sensor that has never
    // reported is not evidence of a good reading, so it stays out of the
    // reckoning rather than defaulting to something reassuring.
    private var magneticAccuracy: Int? = null
    private var rotationAccuracy: Int? = null

    private var nextEmit = 0L

    private val rotationMatrix = FloatArray(9)
    private val adjustedMatrix = FloatArray(9)
    private val orientation = FloatArray(3)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events ?: return
        // Without a magnetometer there is no magnetic north to find, and the
        // rotation vector (if any) is only gyroscope drift. Say so rather than
        // streaming a heading that means nothing.
        if (magnetometer == null) {
            events.error("unavailable", "This device has no magnetometer.", null)
            return
        }
        // The magnetometer is registered even when the fused rotation vector is
        // driving the heading: it is the only honest source of both the field
        // strength and the calibration state.
        sensors.registerListener(this, magnetometer, RATE_MICROS)
        if (rotationSensor != null) {
            sensors.registerListener(this, rotationSensor, RATE_MICROS)
        } else if (accelerometer != null) {
            sensors.registerListener(this, accelerometer, RATE_MICROS)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
        hasRotation = false
        hasGravity = false
        hasMagnetic = false
        magneticAccuracy = null
        rotationAccuracy = null
        nextEmit = 0L
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                // Some Samsung devices hand back more than four components and
                // getRotationMatrixFromVector throws on the surplus.
                val size = minOf(event.values.size, 4)
                System.arraycopy(event.values, 0, rotationVector, 0, size)
                rotationLength = size
                hasRotation = true
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                System.arraycopy(event.values, 0, magnetic, 0, 3)
                hasMagnetic = true
            }
            Sensor.TYPE_ACCELEROMETER -> {
                System.arraycopy(event.values, 0, gravity, 0, 3)
                hasGravity = true
            }
            else -> return
        }
        emit()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        when (sensor?.type) {
            Sensor.TYPE_MAGNETIC_FIELD -> magneticAccuracy = accuracy
            Sensor.TYPE_ROTATION_VECTOR -> rotationAccuracy = accuracy
            // The accelerometer's accuracy says nothing about which way is
            // north. Deliberately ignored — see the class comment.
            else -> return
        }
    }

    private fun emit() {
        val events = sink ?: return
        if (!hasMagnetic) return

        val now = SystemClock.elapsedRealtime()
        if (now < nextEmit) return

        if (hasRotation) {
            val vector = rotationVector.copyOf(rotationLength)
            SensorManager.getRotationMatrixFromVector(rotationMatrix, vector)
        } else {
            if (!hasGravity) return
            if (!SensorManager.getRotationMatrix(rotationMatrix, null, gravity, magnetic)) {
                return
            }
        }

        // One frame, always: the phone lying flat with its top edge forward,
        // turned only to match however the display itself is rotated.
        val axes = displayAxes()
        if (!SensorManager.remapCoordinateSystem(
                rotationMatrix, axes.first, axes.second, adjustedMatrix)) {
            return
        }
        SensorManager.getOrientation(adjustedMatrix, orientation)

        var heading = Math.toDegrees(orientation[0].toDouble()) % 360.0
        if (heading < 0) heading += 360.0

        events.success(
            mapOf(
                "heading" to heading,
                "pitch" to Math.toDegrees(orientation[1].toDouble()),
                "roll" to Math.toDegrees(orientation[2].toDouble()),
                "accuracy" to accuracyDegrees(),
                "field" to fieldStrength()
            )
        )
        nextEmit = now + RATE_MS
    }

    /**
     * How far off the heading is likely to be, in degrees, or -1 when nothing
     * usable has been reported. The worse of the two sensors that bear on north
     * decides it: a fused rotation vector is no better than the magnetometer
     * feeding it.
     */
    private fun accuracyDegrees(): Double {
        val reported = listOfNotNull(magneticAccuracy, rotationAccuracy)
        return when (reported.minOrNull()) {
            SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> 15.0
            SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> 30.0
            SensorManager.SENSOR_STATUS_ACCURACY_LOW -> 45.0
            // UNRELIABLE, NO_CONTACT, or nothing reported at all.
            else -> -1.0
        }
    }

    /** Field magnitude in microtesla, for comparison against the model. */
    private fun fieldStrength(): Double {
        if (!hasMagnetic) return -1.0
        val x = magnetic[0]
        val y = magnetic[1]
        val z = magnetic[2]
        return sqrt((x * x + y * y + z * z).toDouble())
    }

    private fun displayAxes(): Pair<Int, Int> = when (displayRotation()) {
        Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
        Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
        Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
        else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
    }

    @Suppress("DEPRECATION")
    private fun displayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.rotation ?: Surface.ROTATION_0
        } else {
            (activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager)
                .defaultDisplay.rotation
        }

    companion object {
        const val CHANNEL = "hisn/compass"

        /** Delivery hint to the sensor, and the ceiling we forward at. */
        private const val RATE_MICROS = 20 * 1000
        private const val RATE_MS = 50L
    }
}
