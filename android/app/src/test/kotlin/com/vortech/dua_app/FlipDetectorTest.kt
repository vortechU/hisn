package com.vortech.dua_app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FlipDetectorTest {
    private val g = 9.81f

    /** Feeds [ms] of one steady orientation at 20 ms a sample. */
    private fun FlipDetector.hold(x: Float, y: Float, z: Float, from: Long, ms: Long): Boolean {
        var fired = false
        var t = from
        while (t <= from + ms) {
            fired = onSample(x, y, z, t) || fired
            t += 20
        }
        return fired
    }

    @Test
    fun turningFaceDownSilences() {
        val detector = FlipDetector()
        assertFalse(detector.hold(0f, 0f, g, 0, 300))
        assertTrue(detector.hold(0f, 0f, -g, 320, 800))
    }

    @Test
    fun alreadyFaceDownAtStartNeverFires() {
        val detector = FlipDetector()
        assertFalse(detector.hold(0f, 0f, -g, 0, 5_000))
    }

    @Test
    fun aMomentaryTipPastFlatDoesNotCount() {
        val detector = FlipDetector()
        detector.hold(0f, 0f, g, 0, 300)
        assertFalse(detector.hold(0f, 0f, -g, 320, 200))
        assertFalse(detector.hold(0f, 0f, g, 540, 300))
    }

    @Test
    fun aPhoneHeldUprightThenFlippedStillCounts() {
        val detector = FlipDetector()
        // Held in a hand, screen facing the reader: gravity along y.
        assertFalse(detector.hold(0f, g, 0f, 0, 500))
        assertTrue(detector.hold(0f, 0f, -g, 520, 800))
    }

    @Test
    fun aPocketOnItsSideDoesNotCount() {
        val detector = FlipDetector()
        detector.hold(0f, 0f, g, 0, 300)
        assertFalse(detector.hold(g, 0f, -2f, 320, 2_000))
    }
}
