package com.example.island

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(c: Context, i: Intent) {
        if (Prefs.autoStart(c) && Settings.canDrawOverlays(c)) {
            try { c.startForegroundService(Intent(c, IslandService::class.java)) }
            catch (_: Exception) { SystemIcons.restore(c) }   // NotifService tries again once it connects
        } else {
            // The island will not run, so never leave the real status bar icons hidden.
            SystemIcons.restore(c)
        }
    }
}
