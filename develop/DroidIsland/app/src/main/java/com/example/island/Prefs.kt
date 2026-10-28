package com.example.island

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

object Prefs {
    private var cached: SharedPreferences? = null
    private fun sp(c: Context): SharedPreferences =
        cached ?: c.applicationContext.getSharedPreferences("island", Context.MODE_PRIVATE).also { cached = it }

    private val FLAG_DEFAULTS = mapOf(
        "date" to false, "location" to false, "hideIcons" to false, "glass" to false, "hideText" to false,
        "haptic" to false, "fullBatt" to false, "hideLand" to false, "netspeed" to false
    )
    private val INT_DEFAULTS = mapOf(
        "px" to 0, "py" to 0, "padl" to 8, "padr" to 14, "align" to 0, "icolor" to 0, "glasst" to 45,
        "font" to 12, "round" to 100, "clockfmt" to 0, "datefmt" to 0, "popms" to 5, "idlems" to 8
    )
    const val DEF_PAD_L = 8
    const val DEF_PAD_R = 14

    fun flag(c: Context, key: String) = sp(c).getBoolean("f_$key", FLAG_DEFAULTS[key] ?: true)
    fun setFlag(c: Context, key: String, v: Boolean) { sp(c).edit().putBoolean("f_$key", v).apply() }
    fun int(c: Context, key: String) = sp(c).getInt(key, INT_DEFAULTS[key] ?: 0)
    fun setInt(c: Context, key: String, v: Int) { sp(c).edit().putInt(key, v).apply() }

    fun xDp(c: Context) = int(c, "px")
    fun yDp(c: Context) = int(c, "py")
    fun padL(c: Context) = int(c, "padl")
    fun padR(c: Context) = int(c, "padr")
    fun align(c: Context) = int(c, "align")            // 0 left, 1 center, 2 right
    fun islandColor(c: Context) = int(c, "icolor")     // 0 black, 1 white, 2 grey
    fun glassT(c: Context) = int(c, "glasst")          // % transparency when glass is on
    fun setX(c: Context, v: Int) = setInt(c, "px", v)
    fun setY(c: Context, v: Int) = setInt(c, "py", v)
    fun setPadL(c: Context, v: Int) = setInt(c, "padl", v)
    fun setPadR(c: Context, v: Int) = setInt(c, "padr", v)
    fun setAlign(c: Context, v: Int) = setInt(c, "align", v)
    fun setIslandColor(c: Context, v: Int) = setInt(c, "icolor", v)
    fun setGlassT(c: Context, v: Int) = setInt(c, "glasst", v)
    fun resetPos(c: Context) {
        sp(c).edit().putInt("px", 0).putInt("py", 0).putInt("padl", DEF_PAD_L).putInt("padr", DEF_PAD_R).apply()
    }

    fun autoStart(c: Context) = sp(c).getBoolean("boot", false)
    fun setAutoStart(c: Context, v: Boolean) { sp(c).edit().putBoolean("boot", v).apply() }

    fun blocked(c: Context): MutableSet<String> = HashSet(sp(c).getStringSet("blocked", emptySet()) ?: emptySet())
    fun setBlocked(c: Context, s: Set<String>) { sp(c).edit().putStringSet("blocked", HashSet(s)).apply() }
    fun block(c: Context, pkg: String) { val s = blocked(c); s.add(pkg); setBlocked(c, s) }
    fun hideApps(c: Context): MutableSet<String> = HashSet(sp(c).getStringSet("hideapps", emptySet()) ?: emptySet())
    fun setHideApps(c: Context, s: Set<String>) { sp(c).edit().putStringSet("hideapps", HashSet(s)).apply() }

    // ----- backup / restore -----
    fun export(c: Context): String {
        val o = JSONObject()
        for ((k, v) in sp(c).all) {
            if (k.startsWith("bl_")) continue
            when (v) {
                is Set<*> -> o.put(k, JSONArray(v.toList()))
                else -> o.put(k, v)
            }
        }
        return o.toString()
    }

    fun importJson(c: Context, text: String): Boolean = try {
        val o = JSONObject(text)
        val e = sp(c).edit()
        var n = 0
        for (k in o.keys()) {
            if (k.startsWith("bl_")) continue
            when (val v = o.get(k)) {
                is Boolean -> e.putBoolean(k, v)
                is Int -> e.putInt(k, v)
                is String -> e.putString(k, v)
                is JSONArray -> e.putStringSet(k, HashSet<String>().apply { for (i in 0 until v.length()) add(v.getString(i)) })
                else -> continue
            }
            n++
        }
        e.apply()
        n > 0
    } catch (e: Exception) { false }

    fun resetAll(c: Context) {
        val e = sp(c).edit()
        for (k in sp(c).all.keys) if (!k.startsWith("bl_")) e.remove(k)
        e.apply()
    }
}
