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
        "haptic" to false, "fullBatt" to false, "hideLand" to false, "netspeed" to false, "barCover" to false
    )
    private val INT_DEFAULTS = mapOf(
        "px" to 0, "py" to 0, "padl" to 8, "padr" to 14, "align" to 0, "icolor" to 0, "glasst" to 45,
        "font" to 12, "round" to 100, "clockfmt" to 0, "datefmt" to 0, "popms" to 5, "idlems" to 8,
        "customColor" to 0xFF000000.toInt(),
        "wpP" to 0, "wpS" to 0, "wpT" to 0
    )
    const val DEF_PAD_L = 8
    const val DEF_PAD_R = 14

    /**
     * Color sources.
     * icolor = 0/1/2 for black/white/grey,
     * icolor = 100 + i for PALETTE[i],
     * icolor = -1 for custom wallpaper color stored in "customColor".
     */
    val PALETTE: List<Pair<String, Int>> = listOf(
        "Crimson"   to 0xFFB71C1C.toInt(),
        "Tomato"    to 0xFFD32F2F.toInt(),
        "Rose"      to 0xFFE57373.toInt(),
        "Forest"    to 0xFF1B5E20.toInt(),
        "Emerald"   to 0xFF2E7D32.toInt(),
        "Mint"      to 0xFF81C784.toInt(),
        "Navy"      to 0xFF0D47A1.toInt(),
        "Cobalt"    to 0xFF1976D2.toInt(),
        "Sky"       to 0xFF64B5F6.toInt()
    )

    fun flag(c: Context, key: String) = sp(c).getBoolean("f_$key", FLAG_DEFAULTS[key] ?: true)
    fun setFlag(c: Context, key: String, v: Boolean) { sp(c).edit().putBoolean("f_$key", v).apply() }
    fun int(c: Context, key: String) = sp(c).getInt(key, INT_DEFAULTS[key] ?: 0)
    fun setInt(c: Context, key: String, v: Int) { sp(c).edit().putInt(key, v).apply() }

    fun xDp(c: Context) = int(c, "px")
    fun yDp(c: Context) = int(c, "py")
    fun padL(c: Context) = int(c, "padl")
    fun padR(c: Context) = int(c, "padr")
    fun align(c: Context) = int(c, "align")
    fun islandColor(c: Context) = int(c, "icolor")
    fun glassT(c: Context) = int(c, "glasst")
    fun setX(c: Context, v: Int) = setInt(c, "px", v)
    fun setY(c: Context, v: Int) = setInt(c, "py", v)
    fun setPadL(c: Context, v: Int) = setInt(c, "padl", v)
    fun setPadR(c: Context, v: Int) = setInt(c, "padr", v)
    fun setAlign(c: Context, v: Int) = setInt(c, "align", v)
    fun setIslandColor(c: Context, v: Int) = setInt(c, "icolor", v)
    fun setGlassT(c: Context, v: Int) = setInt(c, "glasst", v)

    /** The custom color chosen from wallpaper primaries or a palette entry. */
    fun customColor(c: Context) = int(c, "customColor")
    fun setCustomColor(c: Context, argb: Int) { setInt(c, "customColor", argb); setInt(c, "icolor", -1) }

    /** Three wallpaper primaries (P/S/T), set by IslandService when the wallpaper changes. */
    fun setWallpaperColors(c: Context, p: Int, s: Int, t: Int) {
        sp(c).edit().putInt("wpP", p).putInt("wpS", s).putInt("wpT", t).apply()
    }
    fun wpP(c: Context) = int(c, "wpP")
    fun wpS(c: Context) = int(c, "wpS")
    fun wpT(c: Context) = int(c, "wpT")

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

    fun export(c: Context): String {
        val o = JSONObject()
        for ((k, v) in sp(c).all) {
            if (k.startsWith("bl_") || k.startsWith("wp")) continue
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
            if (k.startsWith("bl_") || k.startsWith("wp")) continue
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
        for (k in sp(c).all.keys) if (!k.startsWith("bl_") && !k.startsWith("wp")) e.remove(k)
        e.apply()
    }
}
