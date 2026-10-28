package com.example.island

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent

/**
 * Bare-minimum accessibility service. Its only job is to hold a context from which
 * TYPE_ACCESSIBILITY_OVERLAY windows can be added. Those windows are not subject to the
 * Android 12+ untrusted-touch filter, so touches reach the island on every ROM without
 * needing `am compat disable BLOCK_UNTRUSTED_TOUCHES`.
 */
class IslandAccessibilityService : AccessibilityService() {
    companion object {
        private const val TAG = "IslandA11y"
        @Volatile var instance: IslandAccessibilityService? = null
        fun overlayContext(): Context? = instance?.applicationContext
        fun overlayWindowManager(): WindowManager? =
            instance?.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        fun isConnected() = instance != null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "connected")
        // If the island service is already running, tell it to swap to the trusted window type.
        if (IslandBus.running) {
            try {
                startService(Intent(this, IslandService::class.java).setAction(IslandService.ACTION_A11Y_CONNECTED))
            } catch (_: Throwable) {}
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) { /* unused */ }

    override fun onInterrupt() { /* unused */ }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        Log.d(TAG, "unbound")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}