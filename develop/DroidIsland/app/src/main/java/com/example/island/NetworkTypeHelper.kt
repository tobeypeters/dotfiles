package com.example.island

import android.content.Context
import android.os.Build
import android.telephony.TelephonyManager
import android.util.Log

object NetworkTypeHelper {
    private const val TAG = "NetworkType"

    fun mobileLabel(c: Context): String {
        return try {
            val tm = c.getSystemService(TelephonyManager::class.java) ?: return ""
            val type = if (Build.VERSION.SDK_INT >= 24) {
                @Suppress("MissingPermission")
                tm.dataNetworkType
            } else return ""

            when (type) {
                TelephonyManager.NETWORK_TYPE_NR -> "5G"
                TelephonyManager.NETWORK_TYPE_LTE -> "LTE"
                TelephonyManager.NETWORK_TYPE_HSPAP,
                TelephonyManager.NETWORK_TYPE_HSDPA,
                TelephonyManager.NETWORK_TYPE_HSUPA,
                TelephonyManager.NETWORK_TYPE_UMTS,
                TelephonyManager.NETWORK_TYPE_EVDO_0,
                TelephonyManager.NETWORK_TYPE_EVDO_A,
                TelephonyManager.NETWORK_TYPE_EVDO_B,
                TelephonyManager.NETWORK_TYPE_EHRPD,
                TelephonyManager.NETWORK_TYPE_HSPA -> "3G"
                TelephonyManager.NETWORK_TYPE_GPRS,
                TelephonyManager.NETWORK_TYPE_EDGE,
                TelephonyManager.NETWORK_TYPE_CDMA,
                TelephonyManager.NETWORK_TYPE_1xRTT,
                TelephonyManager.NETWORK_TYPE_IDEN -> "2G"
                else -> "Cell"
            }
        } catch (t: Throwable) {
            Log.e(TAG, "mobileLabel failed", t)
            ""
        }
    }
}
