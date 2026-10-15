package com.vortech.dua_app

import org.junit.Assert.*
import org.junit.Test

class PrayerSilencePlanTest {
    private val window = PrayerSilenceWindow("fajr", 1_000L, 100_000L)

    private fun evaluate(now: Long, enabled: Boolean = true, permission: Boolean = true,
                         exact: Boolean = true, playing: Boolean = false, skip: Long = 0L) =
        PrayerSilencePlan.evaluate(listOf(window), now, enabled, permission, exact, playing, skip)

    @Test fun expiredOrEarlyBroadcastDoesNotActivate() {
        assertNull(evaluate(999).activeUntil)
        assertEquals(1_000L, evaluate(999).nextBoundary)
        assertEquals(100_000L, evaluate(1_000).activeUntil)
        assertNull(evaluate(100_000).activeUntil)
        assertNull(evaluate(100_001).nextBoundary)
    }

    @Test fun missingAccessOrDisabledNeverActivatesOrSchedules() {
        for (decision in listOf(evaluate(2_000, enabled = false), evaluate(2_000, permission = false),
            evaluate(2_000, exact = false))) {
            assertNull(decision.activeUntil)
            assertNull(decision.nextBoundary)
        }
    }

    @Test fun adhanDefersStartButNeverExtendsDeadline() {
        val waiting = evaluate(90_000, playing = true)
        assertTrue(waiting.waitingForAdhan)
        assertNull(waiting.activeUntil)
        assertEquals(100_000L, waiting.nextBoundary)
        assertEquals(100_000L, evaluate(99_999).activeUntil)
        assertNull(evaluate(100_000).activeUntil)
    }

    @Test fun skipCurrentKeepsLaterWindowsScheduled() {
        val later = PrayerSilenceWindow("dhuhr", 150_000, 200_000)
        val result = PrayerSilencePlan.evaluate(listOf(window, later), 5_000,
            true, true, true, false, window.end)
        assertNull(result.activeUntil)
        assertEquals(later.start, result.nextBoundary)
    }

    @Test fun overlappingWindowsEndAtLastCurrentDeadline() {
        val second = PrayerSilenceWindow("dhuhr", 50_000, 150_000)
        val result = PrayerSilencePlan.evaluate(listOf(window, second), 60_000,
            true, true, true, false)
        assertEquals(150_000L, result.activeUntil)
        assertEquals(100_000L, result.nextBoundary)
    }

    @Test(expected = IllegalArgumentException::class)
    fun infiniteOrReversedWindowsAreRejected() { PrayerSilenceWindow("fajr", 10, 10) }

    @Test(expected = IllegalArgumentException::class)
    fun overlongWindowsAreRejected() { PrayerSilenceWindow("fajr", 0, 181 * 60_000L) }
}
