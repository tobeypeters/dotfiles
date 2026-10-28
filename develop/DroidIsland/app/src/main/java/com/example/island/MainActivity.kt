package com.example.island

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.app.WallpaperManager
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.accessibility.AccessibilityManager
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast

class MainActivity : Activity() {
    private val BG = 0xFF0E0E10.toInt()
    private val CARD = 0xFF1C1C1F.toInt()
    private val BTN = 0xFF2C2C30.toInt()
    private val ACCENT = 0xFF8AB4FF.toInt()
    private val DIM = 0xFF9A9AA0.toInt()
    private val GOOD = 0xFF4ADE80.toInt()
    private val BAD = 0xFFF87171.toInt()

    private lateinit var overlayVal: TextView
    private lateinit var notifVal: TextView
    private lateinit var a11yVal: TextView
    private lateinit var phoneVal: TextView
    private lateinit var runVal: TextView
    private lateinit var battVal: TextView
    private lateinit var iconsVal: TextView
    private lateinit var usageVal: TextView
    private lateinit var hideCountTv: TextView

    private lateinit var presetRow: LinearLayout
    private lateinit var presetBaseRow: LinearLayout
    private lateinit var wpRow: LinearLayout
    private lateinit var currentRow: LinearLayout

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
    private fun lp(w: Int, h: Int, wt: Float = 0f) = LinearLayout.LayoutParams(w, h, wt)
    private fun rounded(color: Int, r: Int) = GradientDrawable().apply { setColor(color); cornerRadius = dp(r).toFloat() }
    private fun push() { IslandBus.refreshBar?.invoke() }

    private fun tx(t: String, size: Float, color: Int = Color.WHITE, bold: Boolean = false) = TextView(this).apply {
        text = t; textSize = size; setTextColor(color)
        if (bold) setTypeface(typeface, Typeface.BOLD)
    }

    private fun card(title: String, parent: LinearLayout): LinearLayout {
        val c = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(CARD, 20)
            setPadding(dp(18), dp(16), dp(18), dp(16))
        }
        c.addView(tx(title.uppercase(), 11f, DIM, true).apply { letterSpacing = 0.12f; setPadding(0, 0, 0, dp(6)) })
        parent.addView(c, lp(-1, -2).apply { topMargin = dp(14) })
        return c
    }

    private fun note(parent: LinearLayout, text: String) =
        parent.addView(tx(text, 12f, DIM).apply { setPadding(0, dp(6), 0, dp(2)) })

    private fun button(label: String, filled: Boolean, onClick: () -> Unit) = tx(label, 14f,
        if (filled) Color.BLACK else Color.WHITE, true).apply {
        gravity = Gravity.CENTER
        background = rounded(if (filled) ACCENT else BTN, 14)
        setPadding(dp(14), dp(12), dp(14), dp(12))
        setOnClickListener { onClick() }
    }

    private fun wide(parent: LinearLayout, label: String, top: Int = 8, onClick: () -> Unit) =
        parent.addView(button(label, false, onClick), lp(-1, -2).apply { topMargin = dp(top) })

    private fun permRow(parent: LinearLayout, title: String, sub: String, btn: String, action: () -> Unit): TextView {
        val status = tx("", 13f, DIM)
        val left = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(tx(title, 15f, Color.WHITE, true)); addView(tx(sub, 12f, DIM)); addView(status)
        }
        parent.addView(LinearLayout(this).apply {
            gravity = Gravity.CENTER_VERTICAL; setPadding(0, dp(6), 0, dp(6))
            addView(left, lp(0, -2, 1f))
            addView(button(btn, false, action).apply { setPadding(dp(16), dp(8), dp(16), dp(8)) })
        })
        return status
    }

    private fun toggle(parent: LinearLayout, title: String, sub: String, init: Boolean, onChange: (Boolean) -> Unit) {
        val sw = Switch(this).apply { isChecked = init; setOnCheckedChangeListener { _, b -> onChange(b) } }
        val left = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(tx(title, 15f, Color.WHITE, true)); addView(tx(sub, 12f, DIM))
        }
        parent.addView(LinearLayout(this).apply {
            gravity = Gravity.CENTER_VERTICAL; setPadding(0, dp(8), 0, dp(8))
            addView(left, lp(0, -2, 1f)); addView(sw)
        })
    }

    private fun flagToggle(parent: LinearLayout, key: String, title: String, sub: String) =
        toggle(parent, title, sub, Prefs.flag(this, key)) { Prefs.setFlag(this, key, it); push() }

    private fun segmented(parent: LinearLayout, title: String, opts: List<String>, sel: Int, onSel: (Int) -> Unit) {
        parent.addView(tx(title, 14f).apply { setPadding(0, dp(10), 0, dp(6)) })
        val row = LinearLayout(this)
        val btns = ArrayList<TextView>()
        fun paint(i: Int) {
            btns.forEachIndexed { j, b ->
                b.background = rounded(if (j == i) ACCENT else BTN, 12)
                b.setTextColor(if (j == i) Color.BLACK else Color.WHITE)
            }
        }
        opts.forEachIndexed { i, o ->
            val b = tx(o, 13f, Color.WHITE, true).apply {
                gravity = Gravity.CENTER; setPadding(dp(8), dp(10), dp(8), dp(10))
                setOnClickListener { paint(i); onSel(i) }
            }
            btns.add(b)
            row.addView(b, lp(0, -2, 1f).apply { if (i > 0) marginStart = dp(8) })
        }
        paint(sel)
        parent.addView(row)
    }

    private fun slider(parent: LinearLayout, title: String, maxV: Int, init: Int, unit: String = "dp",
                       minV: Int = 0, onChange: (Int) -> Unit): SeekBar {
        val valTv = tx("$init $unit", 13f, DIM)
        parent.addView(LinearLayout(this).apply {
            setPadding(0, dp(10), 0, 0)
            addView(tx(title, 14f), lp(0, -2, 1f)); addView(valTv)
        })
        val sb = SeekBar(this).apply {
            max = maxV; min = minV; progress = init
            progressTintList = ColorStateList.valueOf(ACCENT)
            thumbTintList = ColorStateList.valueOf(ACCENT)
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(s: SeekBar?, p: Int, fromUser: Boolean) {
                    valTv.text = "$p $unit"
                    if (fromUser) { onChange(p); IslandBus.reposition?.invoke() }
                }
                override fun onStartTrackingTouch(s: SeekBar?) {}
                override fun onStopTrackingTouch(s: SeekBar?) {}
            })
        }
        parent.addView(sb, lp(-1, -2))
        return sb
    }

    private fun swatchRow(parent: LinearLayout, key: String): LinearLayout {
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        parent.addView(row, lp(-1, dp(52)).apply { topMargin = dp(6) })
        row.tag = key
        return row
    }

    private fun addSwatch(row: LinearLayout, argb: Int, label: String, icolorValue: Int) {
        val sw = TextView(this).apply {
            background = GradientDrawable().apply {
                setColor(argb)
                cornerRadius = dp(10).toFloat()
                setStroke(dp(2), 0x33FFFFFF)
            }
            contentDescription = label
            layoutParams = lp(0, -1, 1f).apply { marginEnd = dp(8) }
            setOnClickListener {
                Prefs.setInt(this@MainActivity, "icolor", icolorValue)
                if (icolorValue == -1) Prefs.setCustomColor(this@MainActivity, argb)
                push()
                refresh()
            }
        }
        row.addView(sw)
    }

    private fun buildSwatches(row: LinearLayout, mode: String) {
        row.removeAllViews()
        when (mode) {
            "preset" -> {
                val palette = Prefs.PALETTE
                for (i in palette.indices) {
                    addSwatch(row, palette[i].second, palette[i].first, 100 + i)
                }
            }
            "base" -> {
                addSwatch(row, Color.BLACK, "Black", 0)
                addSwatch(row, Color.WHITE, "White", 1)
                addSwatch(row, 0xFF8E8E93.toInt(), "Grey", 2)
            }
            "wallpaper" -> {
                val p = Prefs.wpP(this)
                val s = Prefs.wpS(this)
                val t = Prefs.wpT(this)
                addSwatch(row, if (p != 0) p else Color.BLACK, "Primary", -1)
                addSwatch(row, if (s != 0) s else Color.DKGRAY, "Secondary", -1)
                addSwatch(row, if (t != 0) t else Color.GRAY, "Tertiary", -1)
            }
            "current" -> {
                val c = currentArgb()
                addSwatch(row, c, "Current", Prefs.islandColor(this).let { if (it >= 0) it else -1 })
            }
        }
    }

    private fun currentArgb(): Int = when (val ic = Prefs.islandColor(this)) {
        0 -> Color.BLACK
        1 -> Color.WHITE
        2 -> 0xFF8E8E93.toInt()
        -1 -> Prefs.customColor(this)
        else -> {
            val i = ic - 100
            Prefs.PALETTE.getOrNull(i)?.second ?: Color.BLACK
        }
    }

    private fun startIsland() {
        val perms = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            perms.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (checkSelfPermission(Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            perms.add(Manifest.permission.READ_PHONE_STATE)
        }
        if (perms.isNotEmpty()) requestPermissions(perms.toTypedArray(), 1)
        if (Settings.canDrawOverlays(this)) startForegroundService(Intent(this, IslandService::class.java))
        else Toast.makeText(this, "Grant 'Draw over apps' first", Toast.LENGTH_SHORT).show()
        window.decorView.postDelayed({ refresh() }, 600)
    }

    private fun stopIsland() {
        stopService(Intent(this, IslandService::class.java))
        SystemIcons.restore(this)
        window.decorView.postDelayed({ refresh() }, 600)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        return am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.resolveInfo.serviceInfo.packageName == packageName }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = BG
        window.navigationBarColor = BG
        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(24), dp(16), dp(32))
        }
        col.addView(tx("DroidIsland", 30f, Color.WHITE, true))
        col.addView(tx("A dynamic island for Android", 14f, DIM).apply { setPadding(0, dp(2), 0, 0) })

        // ----- setup -----
        val setup = card("Setup", col)
        overlayVal = permRow(setup, "Draw over apps", "Lets the island sit above other apps", "Grant") {
            startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
        }
        notifVal = permRow(setup, "Notification access", "Needed for notifications and media", "Grant") {
            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
        }
        a11yVal = permRow(setup, "Accessibility service",
            "Required for reliable touches on Android 12+. Enable DroidIsland in the list.", "Grant") {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }
        phoneVal = permRow(setup, "Phone state",
            "Reads the mobile network type (5G / LTE / 3G / 2G)", "Grant") {
            if (Build.VERSION.SDK_INT >= 23) {
                requestPermissions(arrayOf(Manifest.permission.READ_PHONE_STATE), 2)
            }
        }
        note(setup, "If touches on the island feel flaky or only work in some spots, " +
            "the accessibility service fixes that. It is only used to host the island window — " +
            "DroidIsland does not read screen content or control other apps.")
        runVal = tx("", 13f, DIM).apply { setPadding(0, dp(10), 0, dp(8)) }
        setup.addView(runVal)
        setup.addView(LinearLayout(this).apply {
            addView(button("Start island", true) { startIsland() }, lp(0, -2, 1f).apply { marginEnd = dp(6) })
            addView(button("Stop island", false) { stopIsland() }, lp(0, -2, 1f).apply { marginStart = dp(6) })
        })
        wide(setup, "Restart island") {
            stopIsland(); window.decorView.postDelayed({ startIsland() }, 900)
        }

        // ----- reliability -----
        val rel = card("Start & reliability", col)
        toggle(rel, "Start on boot", "Starts by itself after the phone restarts and is unlocked", Prefs.autoStart(this)) {
            Prefs.setAutoStart(this, it)
        }
        battVal = permRow(rel, "Run in background", "Stops the system from pausing the island", "Allow") {
            try {
                startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
            } catch (_: Exception) { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) }
        }
        note(rel, "Open DroidIsland at least once after installing. Some phone makers also need Autostart allowed in " +
            "their own app settings.")

        // ----- position & padding -----
        val pos = card("Position & padding", col)
        segmented(pos, "Alignment", listOf("Left", "Center", "Right"), Prefs.align(this)) {
            Prefs.setAlign(this, it); IslandBus.reposition?.invoke()
        }
        note(pos, "Left sits next to the camera hole. Center and Right keep their place and the island grows toward " +
            "the middle of the screen automatically when items are added or removed.")
        val wDp = (resources.displayMetrics.widthPixels / resources.displayMetrics.density).toInt()
        val xBar = slider(pos, "Horizontal offset (away from the edge)", wDp - 40, Prefs.xDp(this)) { Prefs.setX(this, it) }
        val yBar = slider(pos, "Up / down", 120, Prefs.yDp(this)) { Prefs.setY(this, it) }
        val lBar = slider(pos, "Left padding (after camera)", 60, Prefs.padL(this)) { Prefs.setPadL(this, it) }
        val rBar = slider(pos, "Right padding", 60, Prefs.padR(this)) { Prefs.setPadR(this, it) }
        wide(pos, "Reset position & padding", 16) {
            Prefs.resetPos(this)
            xBar.progress = 0; yBar.progress = 0
            lBar.progress = Prefs.DEF_PAD_L; rBar.progress = Prefs.DEF_PAD_R
            IslandBus.reposition?.invoke()
        }

        // ----- appearance -----
        val look = card("Appearance", col)

        look.addView(tx("Preset colors", 14f).apply { setPadding(0, dp(10), 0, dp(4)) })
        presetRow = swatchRow(look, "preset")
        buildSwatches(presetRow, "preset")

        look.addView(tx("Basics", 14f).apply { setPadding(0, dp(10), 0, dp(4)) })
        presetBaseRow = swatchRow(look, "base")
        buildSwatches(presetBaseRow, "base")

        look.addView(tx("Wallpaper Primary Colors", 14f).apply { setPadding(0, dp(14), 0, dp(4)) })
        note(look, "Pulled from the current wallpaper. Recalculated on startup and when the wallpaper changes.")
        wpRow = swatchRow(look, "wallpaper")
        buildSwatches(wpRow, "wallpaper")

        look.addView(tx("Current", 14f).apply { setPadding(0, dp(14), 0, dp(4)) })
        note(look, "The color currently applied to the island.")
        currentRow = swatchRow(look, "current")
        buildSwatches(currentRow, "current")

        flagToggle(look, "glass", "Glass", "See-through island that blends with the color above")
        slider(look, "Glass transparency", 80, Prefs.glassT(this), "%") { Prefs.setGlassT(this, it); push() }
        slider(look, "Text size", 18, Prefs.int(this, "font"), "sp", 9) { Prefs.setInt(this, "font", it); push() }
        slider(look, "Corner roundness", 100, Prefs.int(this, "round"), "%") { Prefs.setInt(this, "round", it); push() }

        // ----- items -----
        val items = card("Island items", col)
        note(items, "Everything shows inside the island. From the right: clock, date, battery, Wi-Fi, then other icons, " +
            "network speed, and notification icons.")
        listOf(
            Triple("clock", "Clock", "Time in the island"),
            Triple("battery", "Battery", "Percent, icon and charging bolt"),
            Triple("date", "Date", "Weekday and date"),
            Triple("notifIcons", "Notification icons", "Icons of pending notifications"),
            Triple("netspeed", "Network speed", "Live download speed"),
            Triple("wifi", "Wi-Fi", "Signal-level icon when Wi-Fi is the active connection"),
            Triple("cell", "Mobile data", "5G / LTE / 3G / 2G label when mobile data is the active connection"),
            Triple("bt", "Bluetooth", "When Bluetooth is on"),
            Triple("airplane", "Airplane mode", "When airplane mode is on"),
            Triple("dnd", "Do Not Disturb", "When a Do Not Disturb mode is active"),
            Triple("ringer", "Silent / vibrate", "When the ringer is silent or vibrate"),
            Triple("alarm", "Next alarm", "When an alarm is set"),
            Triple("location", "Location", "When location services are on"),
            Triple("vpn", "VPN", "When a VPN is connected"),
            Triple("saver", "Battery saver", "When battery saver is on")
        ).forEach { (key, title, sub) -> flagToggle(items, key, title, sub) }
        segmented(items, "Clock format", listOf("System", "12-hour", "24-hour"), Prefs.int(this, "clockfmt")) {
            Prefs.setInt(this, "clockfmt", it); push()
        }
        segmented(items, "Date format", listOf("Mon 26 Oct", "26 Oct", "10/26"), Prefs.int(this, "datefmt")) {
            Prefs.setInt(this, "datefmt", it); push()
        }

        // ----- features -----
        val beh = card("Features", col)
        flagToggle(beh, "media", "Media controls", "Music page with title, artist and transport")
        flagToggle(beh, "timer", "Stopwatch timer", "Timer page and ⏱ indicator in the island")
        flagToggle(beh, "quick", "Quick tools page", "Flashlight, Internet, Bluetooth and Settings shortcuts")
        flagToggle(beh, "popups", "Notification pop-ups", "Expand the island when a notification arrives")
        flagToggle(beh, "dndRespect", "Respect Do Not Disturb", "No pop-ups while Do Not Disturb is on")
        flagToggle(beh, "hideText", "Hide notification text", "Show only the app name in pop-ups")
        flagToggle(beh, "haptic", "Haptic feedback", "Tiny vibration when the island opens")
        flagToggle(beh, "lowBatt", "Low battery alert", "Open the battery page at 20%")
        flagToggle(beh, "fullBatt", "Full charge alert", "Track state at 100% (no popup)")
        flagToggle(beh, "hideLand", "Hide in landscape", "Hide the island when the screen is rotated")
        slider(beh, "Pop-up time", 15, Prefs.int(this, "popms"), "s", 2) { Prefs.setInt(this, "popms", it) }
        slider(beh, "Auto-close time", 20, Prefs.int(this, "idlems"), "s", 3) { Prefs.setInt(this, "idlems", it) }
        wide(beh, "Choose apps to show", 12) { chooseApps() }
        wide(beh, "Send test notification") {
            IslandBus.post(IslandBus.Notif("Test", packageName, "Hello there", "This is your island", null, null))
        }

        // ----- hide system icons -----
        val hide = card("Hide system icons", col)
        note(hide, "Hides the real status bar's clock and icons so only DroidIsland shows them. " +
            "Needs a one-time ADB permission. Some phone makers (for example Samsung) ignore this.")
        iconsVal = tx("", 13f, DIM).apply { setPadding(0, dp(10), 0, dp(6)) }
        hide.addView(iconsVal)
        val cmd = "adb shell pm grant $packageName android.permission.WRITE_SECURE_SETTINGS"
        hide.addView(tx(cmd, 12f, ACCENT).apply {
            typeface = Typeface.MONOSPACE; setTextIsSelectable(true)
            background = rounded(BTN, 10); setPadding(dp(10), dp(8), dp(10), dp(8))
        })
        wide(hide, "Copy command") { copy("adb", cmd) }
        wide(hide, "Restore system icons now") {
            SystemIcons.restore(this, true)
            Toast.makeText(this, "System icons restored", Toast.LENGTH_SHORT).show()
        }
        toggle(hide, "Hide system icons", "Wi-Fi, mobile, Bluetooth, alarm and the rest", Prefs.flag(this, "hideIcons")) {
            Prefs.setFlag(this, "hideIcons", it); syncIcons(); refresh()
        }
        toggle(hide, "Also hide system clock", "Use the clock in the island instead", Prefs.flag(this, "hideClock")) {
            Prefs.setFlag(this, "hideClock", it); syncIcons()
        }
        toggle(hide, "Also hide system battery", "Use the battery in the island instead", Prefs.flag(this, "hideBattery")) {
            Prefs.setFlag(this, "hideBattery", it); syncIcons()
        }
        toggle(hide, "Cover the status bar", "Blocks HUD chips (screen recording, USB, etc.) from showing; the pull-down still works",
            Prefs.flag(this, "barCover")) {
            Prefs.setFlag(this, "barCover", it); push()
        }

        // ----- hide in apps -----
        val ha = card("Hide in apps", col)
        note(ha, "Hide the island while one of these apps is in front, for example games or video players. Needs Usage access.")
        usageVal = tx("", 13f, DIM).apply { setPadding(0, dp(10), 0, dp(6)) }
        ha.addView(usageVal)
        ha.addView(button("Grant usage access", false) {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }, lp(-1, -2))
        hideCountTv = tx("", 13f, DIM).apply { setPadding(0, dp(12), 0, 0) }
        ha.addView(hideCountTv)
        wide(ha, "Choose apps to hide in") { chooseHideApps() }

        // ----- backup & reset -----
        val bk = card("Backup & reset", col)
        note(bk, "Copy your settings to the clipboard to keep them, or paste them back later.")
        wide(bk, "Copy settings") { copy("DroidIsland settings", Prefs.export(this)) }
        wide(bk, "Paste settings") {
            val cb = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            val t = if (cb.hasPrimaryClip() && (cb.primaryClip?.itemCount ?: 0) > 0) cb.primaryClip?.getItemAt(0)?.text?.toString() else null
            if (t != null && Prefs.importJson(this, t)) {
                Toast.makeText(this, "Settings restored", Toast.LENGTH_SHORT).show()
                push(); IslandBus.reposition?.invoke(); recreate()
            } else Toast.makeText(this, "Clipboard doesn't hold DroidIsland settings", Toast.LENGTH_SHORT).show()
        }
        wide(bk, "Reset all settings") {
            AlertDialog.Builder(this).setTitle("Reset all settings?")
                .setMessage("Every option goes back to its default, including Start on boot and your app lists.")
                .setPositiveButton("Reset") { _, _ ->
                    SystemIcons.restore(this); Prefs.resetAll(this)
                    push(); IslandBus.reposition?.invoke(); recreate()
                }
                .setNegativeButton("Cancel", null).show()
        }

        // ----- gestures -----
        val g = card("Gestures", col)
        g.addView(tx("Tap pill: open  •  Swipe down on pill: open\n" +
            "Swipe left / right: switch pages\n" +
            "Swipe up: close or dismiss notification\n" +
            "Tap notification: open its app\n" +
            "Long-press notification: mute that app\n" +
            "Long-press pill: open these settings", 13f, DIM).apply { setLineSpacing(0f, 1.25f) })

        setContentView(ScrollView(this).apply { setBackgroundColor(BG); addView(col) })
        refresh()
    }

    private fun copy(label: String, text: String) {
        (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText(label, text))
        Toast.makeText(this, "Copied", Toast.LENGTH_SHORT).show()
    }

    private fun syncIcons() {
        if (!Prefs.flag(this, "hideIcons") || IslandBus.running) SystemIcons.apply(this)
    }

    override fun onResume() {
        super.onResume()
        if (!IslandBus.running) SystemIcons.restore(this)
        try {
            val wm = WallpaperManager.getInstance(this)
            if (Build.VERSION.SDK_INT >= 27) {
                val c = wm.getWallpaperColors(WallpaperManager.FLAG_SYSTEM)
                if (c != null) {
                    val p = c.primaryColor.toArgb()
                    val s = c.secondaryColor?.toArgb() ?: p
                    val t = c.tertiaryColor?.toArgb() ?: s
                    Prefs.setWallpaperColors(this, p, s, t)
                }
            }
        } catch (_: Throwable) {}
        refresh()
    }

    private fun refresh() {
        fun status(tv: TextView, ok: Boolean, good: String, bad: String) {
            tv.text = if (ok) good else bad
            tv.setTextColor(if (ok) GOOD else BAD)
        }
        status(overlayVal, Settings.canDrawOverlays(this), "✓ Granted", "✗ Not granted")
        val nl = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")?.contains(packageName) == true
        status(notifVal, nl, "✓ Granted", "✗ Not granted")
        status(a11yVal, isAccessibilityServiceEnabled(),
            "✓ Enabled — touches work everywhere",
            "✗ Not enabled — touches may be filtered by the system")
        status(phoneVal,
            checkSelfPermission(Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED,
            "✓ Granted", "✗ Not granted")
        status(battVal, getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(packageName),
            "✓ Unrestricted", "✗ Restricted (may stop after idle or restart)")
        status(usageVal, UsageAccess.granted(this), "✓ Usage access granted", "✗ Usage access not granted")
        status(iconsVal, SystemIcons.granted(this), "✓ Permission granted",
            "✗ Permission needed. Run this on a computer with the phone connected by USB:")
        val hn = Prefs.hideApps(this).size
        hideCountTv.text = if (hn == 0) "No apps selected" else "$hn app${if (hn == 1) "" else "s"} selected"
        runVal.text = if (IslandBus.running) "● Island is running" else "○ Island is stopped"
        runVal.setTextColor(if (IslandBus.running) GOOD else DIM)

        if (::presetRow.isInitialized) buildSwatches(presetRow, "preset")
        if (::presetBaseRow.isInitialized) buildSwatches(presetBaseRow, "base")
        if (::wpRow.isInitialized) buildSwatches(wpRow, "wallpaper")
        if (::currentRow.isInitialized) buildSwatches(currentRow, "current")
    }

    private fun launcherApps(): List<Pair<String, String>> {
        val pm = packageManager
        val q = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(q, 0)
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .distinctBy { it.first }.sortedBy { it.second.lowercase() }
    }

    private fun chooseHideApps() {
        val apps = launcherApps()
        val cur = Prefs.hideApps(this)
        val checked = BooleanArray(apps.size) { apps[it].first in cur }
        AlertDialog.Builder(this).setTitle("Hide island in")
            .setMultiChoiceItems(apps.map { it.second }.toTypedArray(), checked) { _, i, on -> checked[i] = on }
            .setPositiveButton("Save") { _, _ ->
                val n = cur.toMutableSet()
                apps.forEachIndexed { i, a -> if (checked[i]) n.add(a.first) else n.remove(a.first) }
                Prefs.setHideApps(this, n); push(); refresh()
            }
            .setNegativeButton("Cancel", null).show()
    }

    private fun chooseApps() {
        val apps = launcherApps()
        val blocked = Prefs.blocked(this)
        val checked = BooleanArray(apps.size) { apps[it].first !in blocked }
        AlertDialog.Builder(this).setTitle("Show notifications from")
            .setMultiChoiceItems(apps.map { it.second }.toTypedArray(), checked) { _, i, on -> checked[i] = on }
            .setPositiveButton("Save") { _, _ ->
                val nb = blocked.toMutableSet()
                apps.forEachIndexed { i, a -> if (checked[i]) nb.remove(a.first) else nb.add(a.first) }
                Prefs.setBlocked(this, nb); push()
                IslandBus.refreshIcons?.invoke()
            }
            .setNegativeButton("Cancel", null).show()
    }
}
