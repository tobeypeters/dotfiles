package com.example.island

import android.app.AlarmManager
import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/** Tracks the system states that the Android status bar normally shows. */
class StatusMonitor(private val c: Context, private val changed: () -> Unit) {
    @Volatile var wifi = false
    @Volatile var cell = false
    @Volatile var vpn = false
    @Volatile var bt = false
    @Volatile var airplane = false
    @Volatile var dnd = false
    @Volatile var alarm = false
    @Volatile var location = false
    @Volatile var saver = false
    @Volatile var ringer = AudioManager.RINGER_MODE_NORMAL

    private val cm = c.getSystemService(ConnectivityManager::class.java)

    private val netCb = object : ConnectivityManager.NetworkCallback() {
        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
            val w = caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
            val c2 = caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)
            val v = caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
            if (w != wifi || c2 != cell || v != vpn) { wifi = w; cell = c2; vpn = v; changed() }
        }
        override fun onLost(network: Network) {
            if (wifi || cell || vpn) { wifi = false; cell = false; vpn = false; changed() }
        }
    }

    private val rx = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, i: Intent) {
            val before = snapshot()
            refresh()
            if (i.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                val s = i.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1)
                bt = s == BluetoothAdapter.STATE_ON || s == BluetoothAdapter.STATE_TURNING_ON
            }
            if (snapshot() != before) changed()
        }
    }

    private fun snapshot() = "$bt$airplane$dnd$alarm$location$saver$ringer"

    fun refresh() {
        try {
            val cr = c.contentResolver
            bt = Settings.Global.getInt(cr, "bluetooth_on", 0) == 1
            airplane = Settings.Global.getInt(cr, Settings.Global.AIRPLANE_MODE_ON, 0) == 1
            dnd = c.getSystemService(NotificationManager::class.java).currentInterruptionFilter >
                NotificationManager.INTERRUPTION_FILTER_ALL
            ringer = c.getSystemService(AudioManager::class.java).ringerMode
            alarm = c.getSystemService(AlarmManager::class.java).nextAlarmClock != null
            location = if (Build.VERSION.SDK_INT >= 28) c.getSystemService(LocationManager::class.java).isLocationEnabled else false
            saver = c.getSystemService(PowerManager::class.java).isPowerSaveMode
        } catch (_: Exception) {}
    }

    fun start() {
        refresh()
        val f = IntentFilter().apply {
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
            addAction(Intent.ACTION_AIRPLANE_MODE_CHANGED)
            addAction(NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED)
            addAction(AudioManager.RINGER_MODE_CHANGED_ACTION)
            addAction(AlarmManager.ACTION_NEXT_ALARM_CLOCK_CHANGED)
            addAction(LocationManager.MODE_CHANGED_ACTION)
            addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        }
        c.registerReceiver(rx, f)
        try { cm.registerDefaultNetworkCallback(netCb) } catch (_: Exception) {}
        changed()
    }

    fun stop() {
        try { c.unregisterReceiver(rx) } catch (_: Exception) {}
        try { cm.unregisterNetworkCallback(netCb) } catch (_: Exception) {}
    }
}
