package com.vortech.dua_app

/** Finite, half-open intervals. No expired broadcast can start a quiet period. */
data class PrayerSilenceWindow(val prayer: String, val start: Long, val end: Long) {
    init { require(start < end && end - start <= 180 * 60_000L) }

    fun contains(now: Long): Boolean = now >= start && now < end
}

data class PrayerSilenceDecision(
    val activeUntil: Long?,
    val nextBoundary: Long?,
    val waitingForAdhan: Boolean,
)

object PrayerSilencePlan {
    fun evaluate(
        windows: List<PrayerSilenceWindow>, now: Long,
        enabled: Boolean, permission: Boolean, exact: Boolean,
        adhanPlaying: Boolean, skipUntil: Long = 0,
    ): PrayerSilenceDecision {
        if (!enabled || !permission || !exact) return PrayerSilenceDecision(null, null, false)
        val usable = windows.filter { it.end > skipUntil && it.end > now }
        val current = usable.filter { it.contains(now) }
        val end = current.maxOfOrNull { it.end }
        val boundary = usable.flatMap { listOf(it.start, it.end) }.filter { it > now }.minOrNull()
        return PrayerSilenceDecision(
            if (adhanPlaying) null else end,
            if (adhanPlaying && end != null) minOf(boundary ?: end, now + 60_000L) else boundary,
            adhanPlaying && end != null,
        )
    }
}
