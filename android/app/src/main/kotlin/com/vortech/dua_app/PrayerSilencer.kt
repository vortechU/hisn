package com.vortech.dua_app

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.notification.Condition
import android.service.notification.ConditionProviderService
import android.util.Log
import org.json.JSONObject
import org.json.JSONArray
import java.util.Calendar
import java.util.Date

/**
 * One app-owned DND rule, finite windows, and independent end protection.
 * Never changes global DND, ringer mode, volume, or a rule owned by anyone else.
 */
object PrayerSilencer {
    private const val PREFS = "prayer_silence_native"
    private const val CONFIG = "config"
    private const val RULE = "owned_rule"
    private const val ACTIVE_END = "active_end"
    private const val SKIP_UNTIL = "skip_until"
    private const val NEXT = "next_alarm"
    private const val EXPIRY = "expiry_alarm"
    private const val FAILED = "schedule_failed"
    private const val BOUNDARY_ID = 74100
    private const val END_ID = 74101
    private const val BACKUP_ID = 74102
    private const val TAG = "PrayerSilencer"

    fun conditionUri(context: Context): Uri =
        Uri.parse("condition://${context.packageName}/prayer-silence")

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun owner(context: Context) = ComponentName(context, PrayerSilenceConditionProvider::class.java)
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    private fun alarms(context: Context) = context.getSystemService(AlarmManager::class.java)

    fun hasExact(context: Context): Boolean = Build.VERSION.SDK_INT < 31 || alarms(context).canScheduleExactAlarms()

    fun onPrayerConfigChanged(context: Context) {
        val source = PrayerWidget.prefs(context)
        val fingerprint = JSONArray(listOf("lat", "lng", "method", "madhab").map {
            source.getString(it, null)
        }).toString()
        val store = prefs(context)
        if (store.getString("prayerConfig", null) == fingerprint) return
        store.edit().putString("prayerConfig", fingerprint).apply()
        refresh(context, resetAlarms = true)
    }

    @Synchronized fun update(context: Context, arguments: Map<*, *>?): Map<String, Any?> {
        val config = JSONObject().put("enabled", arguments?.get("enabled") == true)
            .put("ruleName", arguments?.get("ruleName") as? String ?: "Hisn · Prayer silence")
        val rules = JSONObject()
        val raw = arguments?.get("windows") as? Map<*, *>
        for (prayer in listOf("fajr", "dhuhr", "asr", "maghrib", "isha")) {
            val entry = raw?.get(prayer) as? Map<*, *> ?: continue
            val start = (entry["start"] as? Number)?.toInt() ?: 0
            val end = (entry["end"] as? Number)?.toInt() ?: 0
            if (start !in 0..179 || end !in 1..180 || end <= start) continue
            rules.put(prayer, JSONObject().put("enabled", entry["enabled"] == true)
                .put("start", start).put("end", end))
        }
        config.put("windows", rules)
        val serialized = config.toString()
        if (prefs(context).getString(CONFIG, null) != serialized) {
            val previous = config(context)
            val edit = prefs(context).edit().putString(CONFIG, serialized)
            // Changing the display language must not undo 'end this period'.
            if (previous.optBoolean("enabled") != config.optBoolean("enabled") ||
                previous.optJSONObject("windows")?.toString() != rules.toString()) edit.remove(SKIP_UNTIL)
            edit.apply()
            refresh(context, resetAlarms = true)
        } else refresh(context)
        return status(context)
    }

    private fun config(context: Context): JSONObject = try {
        JSONObject(prefs(context).getString(CONFIG, "{}") ?: "{}")
    } catch (_: Exception) { JSONObject() }

    private fun ownRule(context: Context): Pair<String, AutomaticZenRule>? {
        val mgr = manager(context)
        if (!mgr.isNotificationPolicyAccessGranted) return null
        val id = prefs(context).getString(RULE, null)
        if (id != null) {
            val rule = mgr.getAutomaticZenRule(id)
            if (rule?.owner == owner(context) && rule.conditionId == conditionUri(context)) return id to rule
        }
        // Recover after a settings restore without creating a duplicate rule.
        val match = mgr.automaticZenRules.entries.firstOrNull {
            it.value.owner == owner(context) && it.value.conditionId == conditionUri(context)
        } ?: return null
        prefs(context).edit().putString(RULE, match.key).apply()
        return match.key to match.value
    }

    private fun ensureRule(context: Context, name: String): Pair<String, AutomaticZenRule> {
        ownRule(context)?.let { return it }
        @Suppress("DEPRECATION")
        val rule = AutomaticZenRule(name, owner(context), conditionUri(context),
            NotificationManager.INTERRUPTION_FILTER_ALARMS, true)
        val id = manager(context).addAutomaticZenRule(rule)
        prefs(context).edit().putString(RULE, id).apply()
        return id to rule
    }

    private fun windows(context: Context, now: Long, config: JSONObject): List<PrayerSilenceWindow> {
        val options = config.optJSONObject("windows") ?: return emptyList()
        val result = mutableListOf<PrayerSilenceWindow>()
        // Include yesterday for an Isha interval crossing midnight. Future
        // boundaries replenish themselves, so this does not depend on Flutter.
        for (day in -1..2) {
            val date = Calendar.getInstance().apply { timeInMillis = now; add(Calendar.DAY_OF_MONTH, day) }.time
            for ((prayer, adhan) in PrayerWidget.prayersOn(context, date)) {
                val option = options.optJSONObject(prayer) ?: continue
                if (!option.optBoolean("enabled", false)) continue
                val start = option.optInt("start", -1)
                val end = option.optInt("end", -1)
                if (start !in 0..179 || end !in 1..180 || start >= end) continue
                result.add(PrayerSilenceWindow(prayer, adhan + start * 60_000L, adhan + end * 60_000L))
            }
        }
        return result
    }

    @Synchronized fun refresh(context: Context, resetAlarms: Boolean = false) {
        val store = prefs(context)
        if (resetAlarms) store.edit().remove(NEXT).remove(EXPIRY).apply()
        val now = System.currentTimeMillis()
        store.edit().remove(FAILED).apply()
        val cfg = config(context)
        val enabled = cfg.optBoolean("enabled", false)
        val permission = manager(context).isNotificationPolicyAccessGranted
        val exact = hasExact(context)
        try {
            if (!enabled || !permission || !exact) {
                deactivate(context, remove = !enabled)
                cancel(context, BOUNDARY_ID)
                store.edit().remove(NEXT).apply()
                return
            }
            val all = windows(context, now, cfg)
            if (all.isEmpty()) {
                deactivate(context)
                cancel(context, BOUNDARY_ID)
                store.edit().remove(NEXT).apply()
                return
            }
            val owned = ensureRule(context, cfg.optString("ruleName", "Hisn · Prayer silence"))
            if (!owned.second.isEnabled) { deactivate(context); return }
            val plan = PrayerSilencePlan.evaluate(all, now, enabled, permission, exact,
                AdhanPlayerService.isPlaying, store.getLong(SKIP_UNTIL, 0))

            if (plan.activeUntil != null) {
                // Refuse activation unless a finite exact end and its distinct
                // inexact backup are already registered successfully.
                if (!armExpiry(context, plan.activeUntil)) {
                    store.edit().putBoolean(FAILED, true).apply()
                    deactivate(context)
                    return
                }
                if (publish(context, owned.first, true, cfg.optString("ruleName"))) {
                    store.edit().putLong(ACTIVE_END, plan.activeUntil).apply()
                } else {
                    store.edit().putBoolean(FAILED, true).apply()
                }
            } else deactivate(context)

            val boundary = plan.nextBoundary
            if (boundary != null && store.getLong(NEXT, 0) != boundary) {
                if (armExact(context, BOUNDARY_ID, boundary)) store.edit().putLong(NEXT, boundary).apply()
                else store.edit().putBoolean(FAILED, true).apply()
            } else if (boundary == null) {
                cancel(context, BOUNDARY_ID)
                store.edit().remove(NEXT).apply()
            }
        } catch (error: Exception) {
            store.edit().putBoolean(FAILED, true).apply()
            Log.e(TAG, "Unable to apply finite prayer silence", error)
            try { deactivate(context) } catch (_: Exception) { }
        }
    }

    private fun condition(context: Context, active: Boolean, name: String): Condition {
        val state = if (active) Condition.STATE_TRUE else Condition.STATE_FALSE
        return if (Build.VERSION.SDK_INT >= 35) {
            Condition(conditionUri(context), name, state, Condition.SOURCE_SCHEDULE)
        } else {
            @Suppress("DEPRECATION")
            Condition(conditionUri(context), name, "", "", 0, state, Condition.FLAG_RELEVANT_ALWAYS)
        }
    }

    private fun publish(context: Context, id: String, active: Boolean, name: String): Boolean {
        val update = condition(context, active, name)
        if (Build.VERSION.SDK_INT >= 29) {
            manager(context).setAutomaticZenRuleState(id, update)
            return true
        }
        val provider = PrayerSilenceConditionProvider.current
        if (provider != null) { provider.publish(update); return true }
        ConditionProviderService.requestRebind(owner(context))
        // On older Android an absent provider cannot publish. Never activate
        // speculatively; the system reconnect will evaluate the deadline again.
        return false
    }

    private fun deactivate(context: Context, remove: Boolean = false) {
        val store = prefs(context)
        if (manager(context).isNotificationPolicyAccessGranted) {
            val owned = ownRule(context)
            if (owned != null) {
                val sent = publish(context, owned.first, false, config(context).optString("ruleName"))
                // API24–28 must not retain a true rule if its provider is gone.
                if (remove || (!sent && store.getLong(ACTIVE_END, 0) > 0)) {
                    manager(context).removeAutomaticZenRule(owned.first)
                    store.edit().remove(RULE).apply()
                }
            }
        }
        store.edit().remove(ACTIVE_END).remove(EXPIRY).apply()
        cancel(context, END_ID)
        cancel(context, BACKUP_ID)
    }

    @Synchronized fun skipCurrent(context: Context): Map<String, Any?> {
        val now = System.currentTimeMillis()
        val until = windows(context, now, config(context)).filter { it.contains(now) }.maxOfOrNull { it.end } ?: now
        prefs(context).edit().putLong(SKIP_UNTIL, until).apply()
        refresh(context, resetAlarms = true)
        return status(context)
    }

    @Synchronized fun status(context: Context): Map<String, Any?> {
        val cfg = config(context)
        val enabled = cfg.optBoolean("enabled", false)
        val permission = manager(context).isNotificationPolicyAccessGranted
        val exact = hasExact(context)
        val now = System.currentTimeMillis()
        val end = prefs(context).getLong(ACTIVE_END, 0).takeIf { it > now }
        val own = try { ownRule(context) } catch (_: Exception) { null }
        val ruleDisabled = own?.second?.isEnabled == false
        val current = windows(context, now, cfg).any { it.contains(now) }
        val reason = when {
            !enabled -> "disabled"
            !permission -> "permission"
            !exact -> "exactAlarm"
            PrayerWidget.prayersOn(context, Date(now)).isEmpty() -> "location"
            ruleDisabled -> "ruleDisabled"
            prefs(context).getBoolean(FAILED, false) -> "error"
            current && AdhanPlayerService.isPlaying -> "waiting"
            end != null -> "active"
            current && prefs(context).getLong(SKIP_UNTIL, 0) <= now -> "error"
            own == null -> "error"
            else -> "ready"
        }
        return mapOf("supported" to true, "enabled" to enabled, "reason" to reason, "policyGranted" to permission,
            "exactAllowed" to exact, "activeUntil" to end)
    }

    private fun pending(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context, id, Intent(context, PrayerSilenceReceiver::class.java).apply {
            action = "${context.packageName}.PRAYER_SILENCE_$id"
        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun cancel(context: Context, id: Int) = alarms(context).cancel(pending(context, id))

    private fun armExact(context: Context, id: Int, at: Long): Boolean = try {
        if (!hasExact(context)) false else {
            alarms(context).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context, id))
            true
        }
    } catch (_: Exception) { false }

    private fun armExpiry(context: Context, at: Long): Boolean {
        if (prefs(context).getLong(EXPIRY, 0) == at) return true
        if (!armExact(context, END_ID, at)) return false
        try {
            // Different PendingIntent: revoking exact-alarm access cancels exact
            // alarms, while this backup remains an inexact bounded-end check.
            alarms(context).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context, BACKUP_ID))
        } catch (_: Exception) { cancel(context, END_ID); return false }
        prefs(context).edit().putLong(EXPIRY, at).apply()
        return true
    }
}
