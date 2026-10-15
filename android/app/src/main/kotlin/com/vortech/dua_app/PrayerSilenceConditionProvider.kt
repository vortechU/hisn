package com.vortech.dua_app

import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.service.notification.Condition
import android.service.notification.ConditionProviderService

/** System-bound owner of Hisn's rule. Rechecks persisted deadlines on reconnect. */
class PrayerSilenceConditionProvider : ConditionProviderService() {
    private val handler = Handler(Looper.getMainLooper())
    private val recheck = object : Runnable {
        override fun run() {
            PrayerSilencer.refresh(this@PrayerSilenceConditionProvider)
            handler.postDelayed(this, 60_000L)
        }
    }

    override fun onConnected() {
        current = this
        handler.removeCallbacks(recheck)
        handler.post(recheck)
    }

    override fun onSubscribe(conditionId: Uri) {
        if (conditionId == PrayerSilencer.conditionUri(this)) {
            PrayerSilencer.refresh(this)
        }
    }

    override fun onUnsubscribe(conditionId: Uri) {
        // The system, rather than an app-started service, owns this binding.
    }

    fun publish(condition: Condition) = notifyCondition(condition)

    override fun onDestroy() {
        handler.removeCallbacks(recheck)
        if (current === this) current = null
        super.onDestroy()
    }

    companion object {
        var current: PrayerSilenceConditionProvider? = null
            private set
    }
}
