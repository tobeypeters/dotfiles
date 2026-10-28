package com.example.island

import android.app.Notification
import android.content.Intent
import android.graphics.drawable.Drawable
import android.os.SystemClock
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotifService : NotificationListenerService() {
    override fun onListenerConnected() {
        IslandBus.cancel = { k -> try { cancelNotification(k) } catch (_: Exception) {} }
        IslandBus.refreshIcons = { refreshIcons() }
        IslandBus.onListenerConnected?.invoke()
        refreshIcons()
        // Second chance to start the island after a reboot: the system binds this service on its own.
        if (SystemClock.elapsedRealtime() < 180_000L && Prefs.autoStart(this) && !IslandBus.running &&
            Settings.canDrawOverlays(this)) {
            try { startForegroundService(Intent(this, IslandService::class.java)) } catch (_: Exception) {}
        }
    }

    override fun onListenerDisconnected() {
        IslandBus.cancel = null
        IslandBus.refreshIcons = null
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) { refreshIcons() }

    private fun refreshIcons() {
        val list: Array<StatusBarNotification> = try { activeNotifications } catch (e: Exception) { null } ?: return
        val blocked = Prefs.blocked(this)
        val seen = HashSet<String>()
        val out = ArrayList<Drawable>()
        for (s in list) {
            if (out.size >= 4) break
            if (s.packageName == packageName || s.packageName in blocked || !seen.add(s.packageName)) continue
            try { s.notification.smallIcon?.loadDrawable(this)?.let { out.add(it.mutate()) } } catch (_: Exception) {}
        }
        IslandBus.icons?.invoke(out)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        refreshIcons()
        val n = sbn.notification
        if (sbn.packageName == packageName || sbn.isOngoing) return
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (sbn.packageName in Prefs.blocked(this)) return
        val ex = n.extras
        val title = ex.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: return
        val body = ex.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val app = try {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(sbn.packageName, 0)).toString()
        } catch (e: Exception) { sbn.packageName }
        IslandBus.post(IslandBus.Notif(app, sbn.packageName, title, body, n.contentIntent, sbn.key))
    }
}
