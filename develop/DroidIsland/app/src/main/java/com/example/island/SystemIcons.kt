package com.example.island

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Settings

/**
 * Hides the real status bar icons via the SystemUI "icon_blacklist" secure setting.
 * Needs: adb shell pm grant com.example.island android.permission.WRITE_SECURE_SETTINGS
 * Some phone makers (e.g. Samsung One UI) ignore this setting.
 */
object SystemIcons {
    private const val KEY = "icon_blacklist"
    private const val BASE = "rotate,headset,cast,hotspot,vpn,sync_failing,nfc,location,managed_profile,zen," +
        "alarm_clock,ethernet,wifi,mobile,airplane,volume,bluetooth,data_saver,ime,call_strength,no_sim," +
        "sync_active,speakerphone,mute,tty,embms,hearing_aid,do_not_disturb"

    fun granted(c: Context) = c.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) == PackageManager.PERMISSION_GRANTED

    private fun sp(c: Context) = c.getSharedPreferences("island", Context.MODE_PRIVATE)

    /** Applies the hide list if the option is on, otherwise restores the original list. */
    fun apply(c: Context): Boolean {
        if (!granted(c)) return false
        return try {
            if (Prefs.flag(c, "hideIcons")) {
                if (!sp(c).getBoolean("bl_saved", false)) {
                    sp(c).edit().putString("bl_orig", Settings.Secure.getString(c.contentResolver, KEY))
                        .putBoolean("bl_saved", true).apply()
                }
                var v = BASE
                if (Prefs.flag(c, "hideClock")) v += ",clock"
                if (Prefs.flag(c, "hideBattery")) v += ",battery"
                Settings.Secure.putString(c.contentResolver, KEY, v)
            } else restore(c)
            true
        } catch (e: Exception) { false }
    }

    /** Puts the icons back. With force, also clears the hide list even if we never saved the original. */
    fun restore(c: Context, force: Boolean = false) {
        if (!granted(c)) return
        val saved = sp(c).getBoolean("bl_saved", false)
        if (!saved && !force) return
        try {
            Settings.Secure.putString(c.contentResolver, KEY, if (saved) sp(c).getString("bl_orig", null) ?: "" else "")
            sp(c).edit().putBoolean("bl_saved", false).apply()
        } catch (_: Exception) {}
    }
}
