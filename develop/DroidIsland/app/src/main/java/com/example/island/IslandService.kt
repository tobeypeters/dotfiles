package com.example.island

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.WallpaperManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Outline
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.LayerDrawable
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.display.DisplayManager
import android.media.AudioManager
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.text.TextUtils
import android.text.format.DateFormat
import android.util.Log
import android.view.Display
import android.view.GestureDetector
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class IslandService : Service() {
    companion object {
        private const val TAG = "Island"
        const val ACTION_A11Y_CONNECTED = "com.example.island.A11Y_CONNECTED"

        @Volatile private var runningInstance: IslandService? = null
        fun isUsingTrustedOverlay(): Boolean = runningInstance?.trustedOverlay == true
    }

    enum class Page { NOTIF, MEDIA, TIMER, QUICK, BATTERY }

    private fun log(s: String) = Log.d(TAG, s)

    private fun safe(what: String, block: () -> Unit) {
        try { block() } catch (t: Throwable) {
            Log.e(TAG, "FAIL in $what: ${t.javaClass.simpleName}: ${t.message}", t)
        }
    }

    inner class Root(c: Context) : FrameLayout(c) {
        override fun dispatchTouchEvent(e: MotionEvent): Boolean {
            if (e.actionMasked == MotionEvent.ACTION_DOWN) {
                downX = e.rawX; downY = e.rawY; swiped = false
                if (expanded) scheduleCollapse(idleMs())
            }
            return super.dispatchTouchEvent(e)
        }
        override fun onInterceptTouchEvent(e: MotionEvent): Boolean =
            expanded && e.actionMasked == MotionEvent.ACTION_MOVE &&
                (abs(e.rawX - downX) > dp(20) || abs(e.rawY - downY) > dp(20))
        override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
            super.onLayout(changed, l, t, r, b)
            if (Build.VERSION.SDK_INT >= 29) {
                try {
                    systemGestureExclusionRects = listOf(android.graphics.Rect(0, 0, r - l, b - t))
                } catch (_: Throwable) {}
            }
        }
    }

    private lateinit var wm: WindowManager
    private var trustedOverlay = false
    private lateinit var root: Root
    private lateinit var pages: FrameLayout
    private lateinit var pill: FrameLayout
    private lateinit var lp: WindowManager.LayoutParams
    private val bg = GradientDrawable().apply { setColor(Color.BLACK) }
    private val pageBg = GradientDrawable().apply { setColor(Color.BLACK) }
    private val barBg = GradientDrawable().apply { setColor(Color.BLACK) }
    private val handler = Handler(Looper.getMainLooper())
    private var anim: ValueAnimator? = null
    private var rootOn = false

    private var barCover: View? = null

    private var expanded = false
    private var current = Page.TIMER
    private var collapsedW = 0
    private var collapsedH = 0
    private var collapsedX = 0
    private var inset = 0
    private var statusBarH = 0
    private var cutRight = 0
    private var cutBottom = 0
    private val collapse = Runnable { setExpanded(false) }

    private lateinit var statusRow: LinearLayout
    private lateinit var notifRow: LinearLayout
    private lateinit var liveTv: TextView
    private lateinit var speedTv: TextView
    private lateinit var batPill: TextView
    private lateinit var batIcon: ImageView
    private lateinit var dateTv: TextView
    private lateinit var clockTv: TextView
    private lateinit var wifiIcon: ImageView
    private lateinit var netTypeTv: TextView
    private lateinit var monitor: StatusMonitor
    private var lastIcons: List<Drawable> = emptyList()
    private var rowSig = ""
    private var downX = 0f
    private var downY = 0f
    private var swiped = false
    private val primary = ArrayList<TextView>()
    private val secondary = ArrayList<TextView>()
    private lateinit var clockFormat: java.text.DateFormat
    private lateinit var dateFormat: java.text.DateFormat

    private lateinit var vNotif: LinearLayout
    private lateinit var vMedia: LinearLayout
    private lateinit var vTimer: LinearLayout
    private lateinit var vQuick: LinearLayout
    private lateinit var vBattery: LinearLayout
    private lateinit var nApp: TextView
    private lateinit var nTitle: TextView
    private lateinit var nBody: TextView
    private lateinit var artIv: ImageView
    private lateinit var mTitle: TextView
    private lateinit var mArtist: TextView
    private lateinit var playBtn: TextView
    private lateinit var timeTv: TextView
    private lateinit var swBtn: TextView
    private lateinit var torchBtn: TextView
    private lateinit var batTv: TextView
    private lateinit var batSub: TextView

    private var notif: IslandBus.Notif? = null
    private var controller: MediaController? = null
    private var msm: MediaSessionManager? = null
    private var playing = false
    private var swRunning = false
    private var swBase = 0L
    private var swAccum = 0L
    private var pct = 0
    private var charging = false
    private var batInit = false
    private var lowAlerted = false
    private var fullAlerted = false

    private var screenOn = true
    private var hiddenByApp = false
    private var hiddenByLand = false
    private var hiddenNow = false
    private var hideSet: Set<String> = emptySet()
    private var fgPkg: String? = null
    private var fgSince = 0L
    private var lastRx = 0L
    private var lastT = 0L

    private var torchId: String? = null
    private var torchOn = false
    private var torchInit = false

    private var wallpaperManager: WallpaperManager? = null
    private var wallpaperListener: WallpaperManager.OnColorsChangedListener? = null

    // Connectivity state
    private var wifi = false
    private var cell = false
    private var wifiLevel = 0
    private var wifiSignal = -1
    private var mobileLabel = ""
    private var cm: ConnectivityManager? = null
    private var netCb: ConnectivityManager.NetworkCallback? = null

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
    private val screenW get() = resources.displayMetrics.widthPixels
    private fun idleMs() = Prefs.int(this, "idlems") * 1000L
    private fun popMs() = Prefs.int(this, "popms") * 1000L
    private fun landscape() = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    private fun TextView.bold(): TextView { setTypeface(typeface, Typeface.BOLD); return this }
    private fun TextView.setIfChanged(s: CharSequence) { if (text.toString() != s.toString()) text = s }
    private fun tv(size: Float, color: Int) = TextView(this).apply {
        textSize = size; setTextColor(color)
        if (color == Color.WHITE) primary.add(this) else if (color == Color.LTGRAY) secondary.add(this)
    }
    private fun vbox() = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    private fun ctl(text: String, size: Float = 22f, onClick: () -> Unit) = tv(size, Color.WHITE).apply {
        this.text = text
        setPadding(dp(12), dp(6), dp(12), dp(6))
        setOnClickListener { onClick() }
    }
    private fun WindowManager.LayoutParams.allowCutout() {
        if (Build.VERSION.SDK_INT >= 30)
            layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        else if (Build.VERSION.SDK_INT >= 28)
            layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
    }
    private fun buzz() { if (Prefs.flag(this, "haptic")) safe("buzz") { root.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK) } }

    private fun neutralizeTouchTargets(v: View) {
        v.isClickable = false
        v.isFocusable = false
        v.isFocusableInTouchMode = false
        if (v is ViewGroup) for (i in 0 until v.childCount) neutralizeTouchTargets(v.getChildAt(i))
    }

    private fun overlayType(): Int =
        if (trustedOverlay) WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        else WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY

    private fun barCoverActive(): Boolean = barCover != null

    override fun onBind(i: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_A11Y_CONNECTED) {
            log("ACTION_A11Y_CONNECTED received")
            if (!trustedOverlay) {
                if (tryUpgradeToTrustedOverlay()) {
                    Toast.makeText(this, "Island updated to trusted window", Toast.LENGTH_SHORT).show()
                }
            }
        }
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        log("onCreate: enter")
        runningInstance = this
        val prev = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { t, e ->
            Log.e(TAG, "UNCAUGHT: ${t.name}", e)
            prev?.uncaughtException(t, e)
        }

        safe("startForeground") { startForeground(1, buildNotif()) }
        IslandBus.running = true
        cm = getSystemService(ConnectivityManager::class.java)
        val a11yWm = IslandAccessibilityService.overlayWindowManager()
        if (a11yWm != null) {
            wm = a11yWm
            trustedOverlay = true
            log("onCreate: using accessibility overlay")
        } else {
            wm = getSystemService(WINDOW_SERVICE) as WindowManager
            trustedOverlay = false
            log("onCreate: accessibility service not enabled; using APPLICATION_OVERLAY")
        }

        safe("readWallpaperColors") { readWallpaperColors() }
        installWallpaperListener()
        safe("registerConnectivity") { registerConnectivityCallback() }

        screenOn = try {
            getSystemService(PowerManager::class.java).isInteractive
        } catch (t: Throwable) {
            Log.e(TAG, "isInteractive failed", t); true
        }
        val sid = resources.getIdentifier("status_bar_height", "dimen", "android")
        statusBarH = if (sid > 0) resources.getDimensionPixelSize(sid) else dp(24)
        log("onCreate: statusBarH=$statusBarH screenW=$screenW")
        readCutout()
        safe("rebuildFormats") { rebuildFormats() }

        safe("buildViews") {
            nApp = tv(12f, Color.LTGRAY)
            nTitle = tv(16f, Color.WHITE).bold()
            nBody = tv(14f, Color.WHITE).apply { maxLines = 2; ellipsize = TextUtils.TruncateAt.END }
            vNotif = vbox().apply { addView(nApp); addView(nTitle); addView(nBody) }

            artIv = ImageView(this).apply {
                scaleType = ImageView.ScaleType.CENTER_CROP
                setBackgroundColor(0xFF333333.toInt())
                outlineProvider = object : ViewOutlineProvider() {
                    override fun getOutline(v: View, o: Outline) {
                        o.setRoundRect(0, 0, v.width, v.height, dp(12).toFloat())
                    }
                }
                clipToOutline = true
            }
            mTitle = tv(15f, Color.WHITE).bold().apply { maxLines = 1; ellipsize = TextUtils.TruncateAt.END }
            mArtist = tv(13f, Color.LTGRAY).apply { maxLines = 1; ellipsize = TextUtils.TruncateAt.END }
            playBtn = ctl("▶") {
                controller?.let { c ->
                    if (c.playbackState?.state == PlaybackState.STATE_PLAYING) c.transportControls.pause()
                    else c.transportControls.play()
                }
            }
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                addView(ctl("⏮") { controller?.transportControls?.skipToPrevious() })
                addView(playBtn)
                addView(ctl("⏭") { controller?.transportControls?.skipToNext() })
            }
            val info = vbox().apply { addView(mTitle); addView(mArtist); addView(row) }
            vMedia = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                addView(artIv, LinearLayout.LayoutParams(dp(64), dp(64)))
                addView(info, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                    .apply { leftMargin = dp(14) })
            }

            timeTv = tv(34f, Color.WHITE).bold().apply { text = "00:00" }
            swBtn = ctl("▶ Start", 18f) {
                if (swRunning) { swAccum = swElapsed(); swRunning = false }
                else { swBase = SystemClock.elapsedRealtime(); swRunning = true }
                swBtn.text = if (swRunning) "⏸ Pause" else "▶ Start"
                handler.removeCallbacks(tick); tick.run()
            }
            val swRow = LinearLayout(this).apply {
                gravity = Gravity.CENTER
                addView(swBtn)
                addView(ctl("↺ Reset", 18f) {
                    swAccum = 0; swBase = SystemClock.elapsedRealtime()
                    handler.removeCallbacks(tick); tick.run()
                })
            }
            vTimer = vbox().apply { gravity = Gravity.CENTER_HORIZONTAL; addView(timeTv); addView(swRow) }

            torchBtn = ctl("Light", 14f) { toggleTorch() }
            vQuick = LinearLayout(this).apply {
                gravity = Gravity.CENTER
                addView(torchBtn)
                addView(ctl("Internet", 14f) {
                    launch(if (Build.VERSION.SDK_INT >= 29) Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
                    else Intent(Settings.ACTION_WIFI_SETTINGS))
                })
                addView(ctl("Bluetooth", 14f) { launch(Intent(Settings.ACTION_BLUETOOTH_SETTINGS)) })
                addView(ctl("Settings", 14f) { launch(Intent(this@IslandService, MainActivity::class.java)) })
            }

            batTv = tv(30f, Color.WHITE).bold()
            batSub = tv(14f, Color.LTGRAY)
            vBattery = vbox().apply { gravity = Gravity.CENTER_HORIZONTAL; addView(batTv); addView(batSub) }

            pages = FrameLayout(this).apply {
                alpha = 0f; visibility = View.INVISIBLE
                background = pageBg
                clipToOutline = true
                for (v in listOf(vNotif, vMedia, vTimer, vQuick, vBattery)) {
                    v.visibility = View.GONE
                    addView(v, FrameLayout.LayoutParams(-1, -1))
                }
            }

            notifRow = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL }
            liveTv = tv(12f, Color.WHITE).apply { maxLines = 1; ellipsize = TextUtils.TruncateAt.END; maxWidth = dp(110) }
            speedTv = tv(12f, Color.WHITE).apply { maxLines = 1; minWidth = dp(40); text = "↓0B" }
            batPill = tv(12f, Color.WHITE).apply { maxLines = 1 }
            batIcon = ImageView(this).apply {
                layoutParams = LinearLayout.LayoutParams(dp(16), dp(16))
                setColorFilter(fg())
            }
            dateTv = tv(12f, Color.WHITE).apply { maxLines = 1 }
            clockTv = tv(12f, Color.WHITE).bold().apply { maxLines = 1 }
            wifiIcon = ImageView(this).apply {
                layoutParams = LinearLayout.LayoutParams(dp(16), dp(16))
                setColorFilter(fg())
            }
            netTypeTv = tv(10f, Color.WHITE).apply { maxLines = 1 }
            statusRow = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL }

            pill = FrameLayout(this).apply {
                background = bg
                clipToOutline = true
                addView(statusRow, FrameLayout.LayoutParams(-2, -2, Gravity.START or Gravity.CENTER_VERTICAL))
                neutralizeTouchTargets(this)
            }

            monitor = StatusMonitor(this) { handler.post { rowSig = ""; updateStatus() } }

            root = Root(this).apply {
                addView(pages, FrameLayout.LayoutParams(-1, -1))
                addView(pill, FrameLayout.LayoutParams(collapsedW, collapsedH, Gravity.TOP or Gravity.LEFT))
            }
            safe("setupGestures") { setupGestures() }
        }

        safe("buildLp") {
            lp = WindowManager.LayoutParams(
                screenW, statusBarH + dp(34),
                overlayType(),
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.LEFT
                x = 0; y = 0
                alpha = 1f
                allowCutout()
            }
        }

        IslandBus.listener = { n -> handler.post { safe("onNotif") { onNotif(n) } } }
        IslandBus.onListenerConnected = { safe("initMedia") { initMedia() } }
        IslandBus.reposition = { handler.post { safe("applyMetrics") { applyMetrics(); snapLayout() } } }
        IslandBus.icons = { list -> handler.post { safe("setNotifIcons") { setNotifIcons(list) } } }
        IslandBus.refreshBar = { handler.post { safe("onSettingsChanged") { onSettingsChanged() } } }

        collapsedW = dp(120)
        collapsedH = dp(34)
        safe("initMedia") { initMedia() }
        safe("monitor.start") { monitor.start() }
        safe("batRx") {
            registerReceiver(batRx, IntentFilter(Intent.ACTION_BATTERY_CHANGED))?.let { batRx.onReceive(this, it) }
        }
        safe("clockRx") {
            registerReceiver(clockRx, IntentFilter().apply {
                addAction(Intent.ACTION_TIME_TICK); addAction(Intent.ACTION_TIME_CHANGED); addAction(Intent.ACTION_TIMEZONE_CHANGED)
            })
        }
        safe("screenRx") {
            registerReceiver(screenRx, IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON); addAction(Intent.ACTION_SCREEN_OFF)
            })
        }
        safe("refreshIcons") { IslandBus.refreshIcons?.invoke() }
        hideSet = Prefs.hideApps(this)
        hiddenByLand = landscape() && Prefs.flag(this, "hideLand")
        safe("applyTheme") { applyTheme() }
        safe("applyMetrics") { applyMetrics() }
        log("onCreate: after applyMetrics collapsedW=$collapsedW collapsedH=$collapsedH collapsedX=$collapsedX")
        safe("snapLayout") { snapLayout() }

        if (Prefs.flag(this, "barCover")) safe("installBarCover") { installBarCover() }
        safe("addView") {
            wm.addView(root, lp)
            rootOn = true
            log("onCreate: addView OK  w=${lp.width} h=${lp.height} x=${lp.x} type=${lp.type} barCover=${barCover != null}")
        }
        safe("updateVisibility") { updateVisibility() }
        safe("schedulePolls") { schedulePolls() }
        safe("SystemIcons.apply") { SystemIcons.apply(this) }
        log("onCreate: done")
    }

    // ---------- connectivity ----------
	private fun registerConnectivityCallback() {
	    val m = cm ?: return
	    if (netCb != null) return
	    val cb = object : ConnectivityManager.NetworkCallback() {
		override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
		    val w = caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
		    val c2 = caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)
		    val sig = if (w) caps.signalStrength else -1
		    // Do not require sig to be valid; still update wifi/cell flags.
		    if (w != wifi || c2 != cell || sig != wifiSignal) {
		        wifi = w; cell = c2; wifiSignal = sig
		        if (w) safe("readWifiLevel") { readWifiLevel() }
		        handler.post { updateStatus() }
		    }
		}
		override fun onLost(network: Network) {
		    if (wifi || cell) {
		        wifi = false; cell = false; wifiSignal = -1
		        handler.post { updateStatus() }
		    }
		}
	    }
	    try {
		m.registerDefaultNetworkCallback(cb)
		netCb = cb
		log("registerConnectivityCallback: registered")
	    } catch (t: Throwable) {
		Log.e(TAG, "registerConnectivityCallback", t)
	    }
	}

	private fun readWifiLevel() {
	    var level = -1

	    // Try NetworkCapabilities.signalStrength first (0..4 on API 29+).
	    if (wifiSignal >= 0) {
		level = when (wifiSignal) {
		    0 -> 0
		    1 -> 1
		    2 -> 2
		    else -> 3
		}
	    }

	    // Fall back to WifiManager RSSI. Requires ACCESS_FINE_LOCATION on Android 10+;
	    // without it, connectionInfo throws SecurityException.
	    if (level < 0) {
		try {
		    val wmgr = getSystemService(WifiManager::class.java)
		    @Suppress("DEPRECATION")
		    val info = wmgr?.connectionInfo
		    if (info != null && info.rssi in -99..-1) {
		        val rssi = info.rssi
		        level = when {
		            rssi >= -55 -> 3
		            rssi >= -67 -> 2
		            rssi >= -78 -> 1
		            else -> 0
		        }
		        Log.d(TAG, "readWifiLevel: rssi=$rssi -> $level")
		    } else {
		        Log.d(TAG, "readWifiLevel: rssi=${info?.rssi} unusable (missing location permission?)")
		    }
		} catch (t: Throwable) {
		    Log.e(TAG, "readWifiLevel fallback failed", t)
		}
	    }

	    if (level >= 0) {
		if (level != wifiLevel) {
		    wifiLevel = level
		    log("readWifiLevel: wifiSignal=$wifiSignal final level=$wifiLevel")
		}
	    } else {
		// No usable signal source. Do not leave the icon at 0 (dot); fall back to mid.
		if (wifiLevel == 0) {
		    wifiLevel = 2
		    log("readWifiLevel: no usable signal, defaulting to 2")
		}
	    }
	}

	private fun currentWifiIcon(): Int = when (wifiLevel) {
	    0 -> R.drawable.ic_wifi_0
	    1 -> R.drawable.ic_wifi_1
	    2 -> R.drawable.ic_wifi_2
	    else -> R.drawable.ic_wifi_3
	}

    // ---------- wallpaper colors ----------
    private fun readWallpaperColors() {
        try {
            val wm = WallpaperManager.getInstance(this)
            wallpaperManager = wm
            if (Build.VERSION.SDK_INT >= 27) {
                val colors = wm.getWallpaperColors(WallpaperManager.FLAG_SYSTEM)
                if (colors != null) {
                    val p = colors.primaryColor.toArgb()
                    val s = colors.secondaryColor?.toArgb() ?: darken(p)
                    val t = colors.tertiaryColor?.toArgb() ?: darken(s)
                    Prefs.setWallpaperColors(this, p, s, t)
                    log("readWallpaperColors: p=0x${Integer.toHexString(p)} s=0x${Integer.toHexString(s)} t=0x${Integer.toHexString(t)}")
                }
            }
        } catch (t: Throwable) {
            Log.e(TAG, "readWallpaperColors", t)
        }
    }

    private fun installWallpaperListener() {
        if (Build.VERSION.SDK_INT < 27) return
        try {
            if (wallpaperListener != null) return
            val wm = wallpaperManager ?: WallpaperManager.getInstance(this).also { wallpaperManager = it }
            val l = WallpaperManager.OnColorsChangedListener { _, _ ->
                handler.post {
                    safe("readWallpaperColors") { readWallpaperColors() }
                    if (Prefs.islandColor(this) == -1) safe("applyTheme") { applyTheme() }
                }
            }
            wm.addOnColorsChangedListener(l, handler)
            wallpaperListener = l
            log("installWallpaperListener: registered")
        } catch (t: Throwable) {
            Log.e(TAG, "installWallpaperListener", t)
        }
    }

    private fun removeWallpaperListener() {
        try {
            wallpaperListener?.let { wallpaperManager?.removeOnColorsChangedListener(it) }
        } catch (_: Throwable) {}
        wallpaperListener = null
    }

    private fun darken(argb: Int): Int {
        val r = (Color.red(argb) * 0.75f).toInt().coerceIn(0, 255)
        val g = (Color.green(argb) * 0.75f).toInt().coerceIn(0, 255)
        val b = (Color.blue(argb) * 0.75f).toInt().coerceIn(0, 255)
        return Color.argb(255, r, g, b)
    }

    private fun tryUpgradeToTrustedOverlay(): Boolean {
        val a11yWm = IslandAccessibilityService.overlayWindowManager() ?: return false
        return try {
            if (rootOn) { try { wm.removeView(root) } catch (_: Throwable) {}; rootOn = false }
            removeBarCover()
            wm = a11yWm
            trustedOverlay = true
            lp.type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            snapLayout()
            if (Prefs.flag(this, "barCover")) installBarCover()
            wm.addView(root, lp)
            rootOn = true
            log("upgraded to TYPE_ACCESSIBILITY_OVERLAY")
            true
        } catch (t: Throwable) {
            Log.e(TAG, "upgrade failed", t)
            trustedOverlay = false
            false
        }
    }

    // ---------- bar cover ----------
    private fun installBarCover() {
        if (barCover != null) return
        val w = screenW
        val h = max(statusBarH, dp(24))
        val v = View(this).apply { background = barBg }
        val p = WindowManager.LayoutParams(
            w, h,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR,
            PixelFormat.OPAQUE
        ).apply {
            gravity = Gravity.TOP or Gravity.LEFT
            x = 0; y = 0
            alpha = 1f
            allowCutout()
        }
        try {
            wm.addView(v, p)
            barCover = v
            log("installBarCover: added w=$w h=$h")
            applyPillBackground(false)
        } catch (t: Throwable) {
            Log.e(TAG, "installBarCover failed", t)
            barCover = null
        }
    }

    private fun removeBarCover() {
        barCover?.let { try { wm.removeView(it) } catch (_: Throwable) {} }
        barCover = null
        applyPillBackground(!expanded && !barCoverActive())
    }

    private fun readCutout() {
        cutBottom = statusBarH
        cutRight = if (Build.VERSION.SDK_INT >= 30) dp(8) else dp(48)
        if (Build.VERSION.SDK_INT < 30) return
        try {
            val d = getSystemService(DisplayManager::class.java).getDisplay(Display.DEFAULT_DISPLAY)
            val r = d?.cutout?.boundingRects?.filter { it.top <= 0 }?.minByOrNull { it.left } ?: return
            cutRight = r.right; cutBottom = r.bottom
        } catch (_: Exception) {}
    }

    private fun pillY() = dp(Prefs.yDp(this))
    private fun extraTop() = (collapsedH - dp(12)).coerceAtLeast(0)
    private fun capW() = if (Prefs.align(this) == 0) screenW - dp(Prefs.xDp(this)) - dp(8) else screenW - dp(16)
    private fun collapsedR() = collapsedH / 2f * Prefs.int(this, "round") / 100f
    private fun iconPx() = dp(Prefs.int(this, "font") + 2)

    private fun alignX(w: Int) = when (Prefs.align(this)) {
        1 -> (screenW - w) / 2 + dp(Prefs.xDp(this))
        2 -> screenW - w - dp(8) - dp(Prefs.xDp(this))
        else -> dp(Prefs.xDp(this))
    }

    private fun insetFor(x: Int): Int {
        val pl = dp(Prefs.padL(this))
        return max(dp(10), max(pl, cutRight + pl - x))
    }

    private fun rowWidth(): Int {
        statusRow.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
        return statusRow.measuredWidth
    }

    private fun computeCollapsed() {
        val rw = rowWidth(); val pr = dp(Prefs.padR(this))
        var x = alignX(dp(10) + rw + pr)
        var w = 0
        repeat(3) {
            inset = insetFor(x)
            w = min(inset + rw + pr, capW())
            x = alignX(w)
        }
        collapsedX = x.coerceIn(0, max(0, screenW - w))
        collapsedW = w
        (statusRow.layoutParams as FrameLayout.LayoutParams).leftMargin = inset
        statusRow.requestLayout()
    }

    private fun applyMetrics() {
        collapsedH = max(statusBarH, dp(24))
        pages.setPadding(dp(18), dp(12) + extraTop(), dp(18), dp(12))
        rebuildRow()
        computeCollapsed()
        if (collapsedW <= 0) collapsedW = dp(120)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        readCutout()
        rebuildFormats()
        hiddenByLand = landscape() && Prefs.flag(this, "hideLand")
        updateVisibility()
        applyMetrics()
        val a11yWm = IslandAccessibilityService.overlayWindowManager()
        if (a11yWm != null) {
            wm = a11yWm
            trustedOverlay = true
        } else if (trustedOverlay) {
            wm = getSystemService(WINDOW_SERVICE) as WindowManager
            trustedOverlay = false
        }
        if (barCover != null) removeBarCover()
        if (rootOn) { try { wm.removeView(root) } catch (_: Throwable) {}; rootOn = false }
        lp.type = overlayType()
        snapLayout()
        if (Prefs.flag(this, "barCover") && !hiddenNow) {
            installBarCover()
        }
        try {
            wm.addView(root, lp)
            rootOn = true
            log("onConfigurationChanged: re-added root w=${lp.width} h=${lp.height} barCover=${barCover != null}")
        } catch (t: Throwable) {
            Log.e(TAG, "onConfigurationChanged re-addView failed", t)
        }
    }

    private fun updateVisibility() {
        val hide = hiddenByApp || hiddenByLand
        if (hide == hiddenNow) return
        hiddenNow = hide
        if (hide) { handler.removeCallbacks(collapse); expanded = false; snapLayout() }
        root.visibility = if (hide) View.GONE else View.VISIBLE
        if (hide) {
            removeBarCover()
            SystemIcons.restore(this)
        } else {
            if (Prefs.flag(this, "barCover")) installBarCover()
            SystemIcons.apply(this)
        }
    }

    private val fgPoll = object : Runnable {
        override fun run() { safe("checkForeground") { checkForeground() }; handler.postDelayed(this, 1000) }
    }

    @Suppress("DEPRECATION")
    private fun checkForeground() {
        var hidden = false
        try {
            val usm = getSystemService(UsageStatsManager::class.java)
            val now = System.currentTimeMillis()
            val ev = usm.queryEvents(if (fgSince == 0L) now - 3_600_000L else fgSince - 1000L, now)
            val e = UsageEvents.Event()
            while (ev.hasNextEvent()) {
                ev.getNextEvent(e)
                if (e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) fgPkg = e.packageName
            }
            fgSince = now
            val p = fgPkg
            hidden = p != null && p in hideSet
        } catch (_: Exception) {}
        if (hidden != hiddenByApp) { hiddenByApp = hidden; updateVisibility() }
    }

    private val speedTick = object : Runnable {
        override fun run() {
            safe("speedTick") {
                val rx = TrafficStats.getTotalRxBytes()
                val t = SystemClock.elapsedRealtime()
                if (lastT != 0L && rx >= 0 && rx >= lastRx) {
                    val bps = (rx - lastRx) * 1000 / max(1L, t - lastT)
                    speedTv.setIfChanged("↓" + fmtSpeed(bps))
                }
                lastRx = rx; lastT = t
            }
            handler.postDelayed(this, 1000)
        }
    }

    private fun fmtSpeed(b: Long) = when {
        b < 1000 -> "${b}B"
        b < 1_000_000 -> "${b / 1000}K"
        else -> "%.1fM".format(b / 1_000_000.0)
    }

    private fun schedulePolls() {
        handler.removeCallbacks(fgPoll); handler.removeCallbacks(speedTick)
        lastT = 0L; fgSince = 0L
        if (!screenOn) return
        if (hideSet.isNotEmpty() && UsageAccess.granted(this)) handler.post(fgPoll)
        if (Prefs.flag(this, "netspeed")) handler.post(speedTick)
    }

    private val screenRx = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            screenOn = i.action == Intent.ACTION_SCREEN_ON
            schedulePolls()
            if (screenOn) {
                if (swRunning) { handler.removeCallbacks(tick); tick.run() }
                updateStatus()
            }
        }
    }

    private fun setupGestures() {
        val gd = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onDown(e: MotionEvent) = true
            override fun onSingleTapUp(e: MotionEvent): Boolean {
                if (!expanded) openPage(defaultPage(), idleMs())
                else if (current == Page.NOTIF) openSource()
                else setExpanded(false)
                return true
            }
            override fun onLongPress(e: MotionEvent) {
                if (!expanded) {
                    startActivity(Intent(this@IslandService, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                } else if (current == Page.NOTIF) {
                    notif?.let {
                        Prefs.block(this@IslandService, it.pkg)
                        Toast.makeText(this@IslandService, "Muted ${it.app}", Toast.LENGTH_SHORT).show()
                    }
                    dismissNotif(cancelOriginal = true)
                }
            }
        })

        root.setOnTouchListener { _, e ->
            try {
                if (e.actionMasked == MotionEvent.ACTION_OUTSIDE) {
                    if (expanded) setExpanded(false)
                    return@setOnTouchListener true
                }
                if (e.actionMasked == MotionEvent.ACTION_MOVE && !swiped) {
                    val dx = e.rawX - downX; val dy = e.rawY - downY
                    if (abs(dx) > dp(24) || abs(dy) > dp(24)) {
                        swiped = true
                        val c = MotionEvent.obtain(e); c.action = MotionEvent.ACTION_CANCEL
                        gd.onTouchEvent(c); c.recycle()
                        onSwipe(dx, dy)
                    }
                }
                gd.onTouchEvent(e)
            } catch (t: Throwable) {
                Log.e(TAG, "touch handler crash", t)
            }
            true
        }
    }

    private fun onSwipe(dx: Float, dy: Float) {
        val vertical = abs(dy) > abs(dx)
        if (!expanded) {
            if (vertical && dy > 0) openPage(defaultPage(), idleMs())
            return
        }
        if (vertical) {
            if (dy < 0) { if (current == Page.NOTIF) dismissNotif(true) else setExpanded(false) }
        } else changePage(if (dx < 0) 1 else -1)
    }

    private fun available(): List<Page> = buildList {
        if (notif != null) add(Page.NOTIF)
        if (controller != null && Prefs.flag(this@IslandService, "media")) add(Page.MEDIA)
        if (Prefs.flag(this@IslandService, "timer")) add(Page.TIMER)
        if (Prefs.flag(this@IslandService, "quick")) add(Page.QUICK)
        add(Page.BATTERY)
    }
    private fun defaultPage() = available().first()

    private fun pageH() = dp(when (current) {
        Page.NOTIF -> 112; Page.MEDIA -> 118; Page.TIMER -> 124; Page.QUICK -> 90; Page.BATTERY -> 84
    }) + extraTop()

    private fun showPage() {
        vNotif.visibility = if (current == Page.NOTIF) View.VISIBLE else View.GONE
        vMedia.visibility = if (current == Page.MEDIA) View.VISIBLE else View.GONE
        vTimer.visibility = if (current == Page.TIMER) View.VISIBLE else View.GONE
        vQuick.visibility = if (current == Page.QUICK) View.VISIBLE else View.GONE
        vBattery.visibility = if (current == Page.BATTERY) View.VISIBLE else View.GONE
        if (current == Page.QUICK) initTorch()
        if (current == Page.NOTIF) notif?.let {
            nApp.text = it.app
            if (Prefs.flag(this, "hideText")) { nTitle.text = "New notification"; nBody.text = "" }
            else { nTitle.text = it.title; nBody.text = it.body }
        }
    }

    private fun openPage(p: Page, ms: Long) {
        if (hiddenNow) return
        current = p; showPage()
        if (!expanded) buzz()
        expanded = true; relayout(); scheduleCollapse(ms)
    }

    private fun changePage(d: Int) {
        val l = available()
        val i = l.indexOf(current).coerceAtLeast(0)
        current = l[(i + d + l.size) % l.size]
        showPage(); relayout()
    }

    private fun setExpanded(open: Boolean) {
        expanded = open
        if (!open) handler.removeCallbacks(collapse)
        relayout()
    }

    private fun scheduleCollapse(ms: Long) {
        handler.removeCallbacks(collapse); handler.postDelayed(collapse, ms)
    }

    private fun relayout() {
        try {
            if (expanded) {
                animateTo(screenW - dp(24), pillY() + pageH(), dp(32).toFloat(), dp(12), 0)
            } else {
                val m = dp(12)
                val w = (collapsedW + m * 2).coerceAtMost(screenW)
                val h = (pillY() + collapsedH + m).coerceAtMost(statusBarH + pillY() + collapsedH + m)
                val x = (collapsedX - m).coerceAtLeast(0)
                animateTo(w, h, collapsedR(), x, 0)
            }
        } catch (t: Throwable) {
            Log.e(TAG, "relayout crash", t)
        }
    }

    private fun snapLayout() {
        try { anim?.cancel() } catch (_: Throwable) {}
        if (expanded) {
            lp.width = screenW - dp(24)
            lp.height = pillY() + pageH()
            lp.x = dp(12)
            lp.y = 0
            bg.cornerRadius = dp(32).toFloat()
            pageBg.cornerRadius = dp(32).toFloat()
            pages.alpha = 1f; pages.visibility = View.VISIBLE
            pill.alpha = 0f; pill.visibility = View.GONE
        } else {
            val m = dp(12)
            lp.width = (collapsedW + m * 2).coerceAtMost(screenW)
            lp.height = (pillY() + collapsedH + m).coerceAtMost(statusBarH + pillY() + collapsedH + m)
            lp.x = (collapsedX - m).coerceAtLeast(0)
            lp.y = 0
            bg.cornerRadius = collapsedR()
            pageBg.cornerRadius = collapsedR()
            pages.alpha = 0f; pages.visibility = View.INVISIBLE
            pill.alpha = 1f; pill.visibility = View.VISIBLE
        }
        try {
            val pillLp = pill.layoutParams as FrameLayout.LayoutParams
            pillLp.topMargin = pillY()
            pillLp.leftMargin = if (expanded) 0 else (collapsedX - lp.x).coerceAtLeast(0)
            pillLp.width = collapsedW
            pillLp.height = collapsedH
            pill.layoutParams = pillLp
        } catch (t: Throwable) { Log.e(TAG, "pill lp crash", t) }
        applyPillBackground(!expanded && !barCoverActive())
        if (rootOn) try { wm.updateViewLayout(root, lp) } catch (t: Throwable) { Log.e(TAG, "updateViewLayout", t) }
    }

    private fun animateTo(toW: Int, toH: Int, toR: Float, toX: Int, toY: Int) {
        val fW = lp.width; val fH = lp.height; val fR = bg.cornerRadius; val fX = lp.x; val fY = lp.y
        val fPR = pageBg.cornerRadius
        val fP = pages.alpha
        val tP = if (expanded) 1f else 0f
        if (expanded) pages.visibility = View.VISIBLE
        try { anim?.cancel() } catch (_: Throwable) {}
        anim = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 420
            interpolator = if (expanded) OvershootInterpolator(1.0f) else DecelerateInterpolator()
            addUpdateListener {
                try {
                    val f = it.animatedValue as Float
                    val c = f.coerceIn(0f, 1f)
                    lp.width = (fW + (toW - fW) * f).toInt().coerceAtLeast(dp(20))
                    lp.height = (fH + (toH - fH) * f).toInt().coerceAtLeast(dp(20))
                    lp.x = (fX + (toX - fX) * c).toInt()
                    lp.y = (fY + (toY - fY) * c).toInt()
                    bg.cornerRadius = fR + (toR - fR) * c
                    pageBg.cornerRadius = fPR + (toR - fPR) * c
                    val ca = if (expanded) c else min(1f, c * 2f)
                    pages.alpha = fP + (tP - fP) * ca
                    if (rootOn) wm.updateViewLayout(root, lp)
                } catch (t: Throwable) {
                    Log.e(TAG, "anim update crash", t)
                }
            }
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(a: Animator) {
                    try { if (!expanded) pages.visibility = View.INVISIBLE } catch (_: Throwable) {}
                }
            })
            start()
        }
    }

    private fun onNotif(n: IslandBus.Notif) {
        if (hiddenNow || !Prefs.flag(this, "popups")) return
        if (Prefs.flag(this, "dndRespect") && monitor.dnd) return
        notif = n; openPage(Page.NOTIF, popMs())
    }

    private fun dismissNotif(cancelOriginal: Boolean) {
        val n = notif
        if (cancelOriginal && n?.key != null) IslandBus.cancel?.invoke(n.key)
        notif = null
        if (current == Page.NOTIF) current = defaultPage()
        setExpanded(false)
    }

    private fun launchApp(pkg: String) {
        packageManager.getLaunchIntentForPackage(pkg)?.let { startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }

    private fun openSource() {
        val n = notif ?: return
        try {
            val pi = n.pi
            if (pi != null) pi.send() else launchApp(n.pkg)
        } catch (e: Exception) {
            try { launchApp(n.pkg) } catch (_: Exception) {}
        }
        dismissNotif(false)
    }

    private fun launch(i: Intent) {
        try { startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); setExpanded(false) } catch (_: Exception) {}
    }

    private val torchCb = object : CameraManager.TorchCallback() {
        override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
            if (cameraId == torchId) { torchOn = enabled; torchBtn.text = if (enabled) "Light ●" else "Light" }
        }
    }
    private fun initTorch() {
        if (torchInit) return
        torchInit = true
        try {
            val cm = getSystemService(CameraManager::class.java)
            torchId = cm.cameraIdList.firstOrNull {
                val ch = cm.getCameraCharacteristics(it)
                ch.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true &&
                    ch.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
            }
            cm.registerTorchCallback(torchCb, handler)
        } catch (t: Throwable) { Log.e(TAG, "initTorch", t) }
    }
    private fun toggleTorch() {
        initTorch()
        val id = torchId ?: return
        try { getSystemService(CameraManager::class.java).setTorchMode(id, !torchOn) } catch (t: Throwable) { Log.e(TAG, "toggleTorch", t) }
    }

    private val mediaCb = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) { refreshMedia() }
        override fun onMetadataChanged(metadata: MediaMetadata?) { refreshMedia() }
    }
    private val sessionsListener = MediaSessionManager.OnActiveSessionsChangedListener { list -> pickController(list) }

    private fun initMedia() {
        try {
            val m = getSystemService(MediaSessionManager::class.java)
            val cn = ComponentName(this, NotifService::class.java)
            msm = m
            m.removeOnActiveSessionsChangedListener(sessionsListener)
            m.addOnActiveSessionsChangedListener(sessionsListener, cn)
            pickController(m.getActiveSessions(cn))
        } catch (_: Throwable) {}
    }

    private fun pickController(list: List<MediaController>?) {
        try { controller?.unregisterCallback(mediaCb) } catch (_: Throwable) {}
        controller = list?.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING } ?: list?.firstOrNull()
        try { controller?.registerCallback(mediaCb) } catch (_: Throwable) {}
        refreshMedia()
    }

    private fun refreshMedia() {
        safe("refreshMedia") {
            val md = controller?.metadata
            mTitle.setIfChanged(md?.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Nothing playing")
            mArtist.setIfChanged(md?.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "")
            artIv.setImageBitmap(md?.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: md?.getBitmap(MediaMetadata.METADATA_KEY_ART))
            playing = controller?.playbackState?.state == PlaybackState.STATE_PLAYING
            playBtn.text = if (playing) "⏸" else "▶"
            if (current == Page.MEDIA && current !in available()) {
                current = defaultPage(); showPage(); if (expanded) relayout()
            }
            updateStatus()
        }
    }

    private fun swElapsed() = swAccum + if (swRunning) SystemClock.elapsedRealtime() - swBase else 0L
    private fun fmt(ms: Long): String {
        val s = ms / 1000; val h = s / 3600; val m = (s % 3600) / 60; val x = s % 60
        return if (h > 0) "%d:%02d:%02d".format(h, m, x) else "%02d:%02d".format(m, x)
    }
    private val tick = object : Runnable {
        override fun run() {
            try {
                timeTv.setIfChanged(fmt(swElapsed()))
                if (screenOn) updateStatus()
                if (swRunning && screenOn) handler.postDelayed(this, 500)
            } catch (t: Throwable) { Log.e(TAG, "tick", t) }
        }
    }

    private val batRx = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            try {
                val level = i.getIntExtra(BatteryManager.EXTRA_LEVEL, 0)
                val scale = i.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
                val newPct = level * 100 / scale
                val st = i.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                val now = st == BatteryManager.BATTERY_STATUS_CHARGING || st == BatteryManager.BATTERY_STATUS_FULL
                if (batInit && newPct == pct && now == charging) return
                val wasInit = batInit
                pct = newPct; charging = now; batInit = true
                batTv.setIfChanged("$pct%")
                batSub.setIfChanged(if (now) "⚡ Charging" else "On battery")
                updateStatus()
                if (!wasInit) return
                if (!now && pct <= 20 && !lowAlerted && Prefs.flag(this@IslandService, "lowBatt")) {
                    lowAlerted = true; openPage(Page.BATTERY, popMs())
                }
                if (now || pct > 20) lowAlerted = false
                if (now && pct >= 100 && !fullAlerted && Prefs.flag(this@IslandService, "fullBatt")) {
                    fullAlerted = true
                }
                if (!now || pct < 100) fullAlerted = false
            } catch (t: Throwable) { Log.e(TAG, "batRx", t) }
        }
    }
    private val clockRx = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            try {
                if (i.action != Intent.ACTION_TIME_TICK) rebuildFormats()
                updateStatus()
            } catch (t: Throwable) { Log.e(TAG, "clockRx", t) }
        }
    }

    private fun rebuildFormats() {
        val loc = Locale.getDefault()
        clockFormat = when (Prefs.int(this, "clockfmt")) {
            1 -> SimpleDateFormat("h:mm a", loc)
            2 -> SimpleDateFormat("HH:mm", loc)
            else -> DateFormat.getTimeFormat(this)
        }
        val skeleton = when (Prefs.int(this, "datefmt")) { 1 -> "dMMM"; 2 -> "Md"; else -> "EEEdMMM" }
        dateFormat = SimpleDateFormat(DateFormat.getBestDateTimePattern(loc, skeleton), loc)
    }

    private fun iconView(res: Int): ImageView? = try {
        ImageView(this).apply { setImageResource(res); setColorFilter(fg()) }
    } catch (_: Throwable) { null }

    private fun activeIcons(): List<Pair<String, Int>> {
        val out = ArrayList<Pair<String, Int>>()
        if (!::monitor.isInitialized) return out
        val m = monitor
        fun add(on: Boolean, key: String, res: Int) { if (on && Prefs.flag(this, key)) out.add(key to res) }
        add(m.airplane, "airplane", R.drawable.ic_airplane)
        add(m.dnd, "dnd", R.drawable.ic_dnd)
        add(m.ringer == AudioManager.RINGER_MODE_SILENT, "ringer", R.drawable.ic_silent)
        add(m.ringer == AudioManager.RINGER_MODE_VIBRATE, "ringer", R.drawable.ic_vibrate)
        add(m.alarm, "alarm", R.drawable.ic_alarm)
        add(m.location, "location", R.drawable.ic_location)
        add(m.vpn, "vpn", R.drawable.ic_vpn)
        add(m.bt, "bt", R.drawable.ic_bt)
        add(m.saver, "saver", R.drawable.ic_saver)
        return out
    }

    private fun signature() = listOf(
        liveTv.text.isNotEmpty(), Prefs.flag(this, "battery"), Prefs.flag(this, "date"), Prefs.flag(this, "clock"),
        Prefs.flag(this, "notifIcons"), Prefs.flag(this, "netspeed"), notifRow.childCount,
        wifi, cell, wifiLevel, mobileLabel, pct, charging,
        activeIcons().joinToString(",") { it.second.toString() }
    ).joinToString("|")

    private fun buildRow(withNotif: Boolean) {
        statusRow.removeAllViews()
        val views = ArrayList<View>()
        if (withNotif && Prefs.flag(this, "notifIcons") && notifRow.childCount > 0) views.add(notifRow)
        if (liveTv.text.isNotEmpty()) views.add(liveTv)
        if (Prefs.flag(this, "netspeed")) views.add(speedTv)
        for ((_, res) in activeIcons()) iconView(res)?.let { views.add(it) }

        if (wifi) {
            views.add(wifiIcon)
        } else if (cell && mobileLabel.isNotEmpty()) {
            views.add(netTypeTv)
        }

        if (Prefs.flag(this, "battery")) {
            views.add(batIcon)
            views.add(batPill)
        }
        if (Prefs.flag(this, "date")) views.add(dateTv)
        if (Prefs.flag(this, "clock")) views.add(clockTv)

        val ip = iconPx()
        views.forEachIndexed { i, v ->
            val size = if (v is ImageView) ip else -2
            statusRow.addView(v, LinearLayout.LayoutParams(size, size).apply { if (i > 0) marginStart = dp(6) })
        }
        neutralizeTouchTargets(statusRow)
    }

    private fun rebuildRow() {
        buildRow(true)
        val rw = rowWidth()
        val pr = dp(Prefs.padR(this))
        val needed = insetFor(alignX(dp(10) + rw + pr)) + rw + pr
        if (needed > capW()) buildRow(false)
    }

    private fun setNotifIcons(list: List<Drawable>) {
        lastIcons = list
        notifRow.removeAllViews()
        val ip = iconPx()
        for (d in list.take(4)) {
            notifRow.addView(ImageView(this).apply { setImageDrawable(d); setColorFilter(fg()) },
                LinearLayout.LayoutParams(ip, ip).apply { marginEnd = dp(4) })
        }
        rowSig = ""
        updateStatus()
    }

    private fun updateStatus() {
        safe("updateStatus") {
            val now = Date()
            clockTv.setIfChanged(clockFormat.format(now))
            dateTv.setIfChanged(dateFormat.format(now))
            batPill.setIfChanged("$pct%")
            liveTv.setIfChanged(when {
                swRunning && Prefs.flag(this, "timer") -> "⏱ " + fmt(swElapsed())
                else -> ""
            })

            try { batIcon.setImageDrawable(BatteryFillDrawable(pct, charging, fg())) } catch (_: Throwable) {}

            try {
                if (wifi) {
                    readWifiLevel()
                    wifiIcon.setImageResource(currentWifiIcon())
                    wifiIcon.setColorFilter(fg())
                } else {
                    wifiIcon.setImageDrawable(null)
                }
                if (!wifi && cell) {
                    mobileLabel = NetworkTypeHelper.mobileLabel(this)
                    netTypeTv.text = mobileLabel
                    netTypeTv.setTextColor(fg())
                } else {
                    mobileLabel = ""
                    netTypeTv.text = ""
                }
            } catch (_: Throwable) {}

            val sig = signature()
            if (sig != rowSig) { rowSig = sig; rebuildRow() }
            val ow = collapsedW; val ox = collapsedX
            computeCollapsed()
            if (!expanded && (abs(collapsedW - ow) > dp(3) || collapsedX != ox)) {
                try {
                    val pillLp = pill.layoutParams as FrameLayout.LayoutParams
                    pillLp.width = collapsedW
                    pillLp.leftMargin = (collapsedX - lp.x).coerceAtLeast(0)
                    pill.layoutParams = pillLp
                } catch (_: Throwable) {}
                relayout()
            }
        }
    }

    // ---------- color selection ----------
    private fun baseColor(): Int {
        val icolor = Prefs.islandColor(this)
        return when {
            icolor == 0 -> Color.BLACK
            icolor == 1 -> Color.WHITE
            icolor == 2 -> 0xFF8E8E93.toInt()
            icolor == -1 -> Prefs.customColor(this)
            icolor >= 100 -> {
                val i = icolor - 100
                Prefs.PALETTE.getOrNull(i)?.second ?: Color.BLACK
            }
            else -> Color.BLACK
        }
    }

    private fun fg(): Int {
        val b = baseColor()
        val lum = (0.299 * Color.red(b) + 0.587 * Color.green(b) + 0.114 * Color.blue(b)) / 255.0
        return if (lum > 0.55) Color.BLACK else Color.WHITE
    }

    private fun applyPillBackground(showBevel: Boolean) {
        try {
            val b = baseColor()
            val a = if (Prefs.flag(this, "glass")) (100 - Prefs.glassT(this)) * 255 / 100 else 255
            bg.setColor(Color.argb(a, Color.red(b), Color.green(b), Color.blue(b)))
            bg.cornerRadius = collapsedR()
            if (showBevel) {
                val bevel = BevelDrawable(
                    baseColor = Color.argb(a, Color.red(b), Color.green(b), Color.blue(b)),
                    cornerRadius = collapsedR(),
                    thickness = dp(1).toFloat()
                )
                pill.background = LayerDrawable(arrayOf(bg, bevel))
            } else {
                pill.background = bg
            }
        } catch (t: Throwable) { Log.e(TAG, "applyPillBackground", t) }
    }

    private fun applyTheme() {
        val b = baseColor()
        val a = if (Prefs.flag(this, "glass")) (100 - Prefs.glassT(this)) * 255 / 100 else 255
        bg.setColor(Color.argb(a, Color.red(b), Color.green(b), Color.blue(b)))
        pageBg.setColor(Color.argb(a, Color.red(b), Color.green(b), Color.blue(b)))
        barBg.setColor(b)
        val f = fg()
        primary.forEach { it.setTextColor(f) }
        secondary.forEach { it.setTextColor(Color.argb(170, Color.red(f), Color.green(f), Color.blue(f))) }
        val fs = Prefs.int(this, "font").toFloat()
        for (t in listOf(liveTv, speedTv, batPill, dateTv, clockTv)) t.textSize = fs
        setNotifIcons(lastIcons)
        applyPillBackground(!expanded && !barCoverActive())
    }

    private fun onSettingsChanged() {
        rebuildFormats()
        hideSet = Prefs.hideApps(this)
        if (hideSet.isEmpty() && hiddenByApp) { hiddenByApp = false }
        hiddenByLand = landscape() && Prefs.flag(this, "hideLand")
        updateVisibility()
        if (Prefs.flag(this, "barCover")) {
            if (!hiddenNow) installBarCover()
        } else {
            removeBarCover()
        }
        if (current !in available()) current = defaultPage()
        showPage()
        applyTheme()
        applyMetrics()
        if (expanded) relayout() else snapLayout()
        schedulePolls()
    }

    private fun buildNotif(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel("island", "Island", NotificationManager.IMPORTANCE_MIN))
        return Notification.Builder(this, "island")
            .setContentTitle("DroidIsland running")
            .setSmallIcon(android.R.drawable.ic_dialog_info).build()
    }

    override fun onDestroy() {
        log("onDestroy")
        if (runningInstance === this) runningInstance = null
        IslandBus.running = false
        IslandBus.listener = null
        IslandBus.onListenerConnected = null
        IslandBus.reposition = null
        IslandBus.refreshBar = null
        IslandBus.icons = null
        removeWallpaperListener()
        netCb?.let { try { cm?.unregisterNetworkCallback(it) } catch (_: Throwable) {} }
        netCb = null
        safe("SystemIcons.restore") { SystemIcons.restore(this) }
        if (::monitor.isInitialized) safe("monitor.stop") { monitor.stop() }
        handler.removeCallbacksAndMessages(null)
        try { anim?.cancel() } catch (_: Throwable) {}
        try { unregisterReceiver(batRx) } catch (_: Exception) {}
        try { unregisterReceiver(clockRx) } catch (_: Exception) {}
        try { unregisterReceiver(screenRx) } catch (_: Exception) {}
        try { msm?.removeOnActiveSessionsChangedListener(sessionsListener) } catch (_: Exception) {}
        if (torchInit) try { getSystemService(CameraManager::class.java).unregisterTorchCallback(torchCb) } catch (_: Exception) {}
        try { controller?.unregisterCallback(mediaCb) } catch (_: Throwable) {}
        removeBarCover()
        if (rootOn) try { wm.removeView(root) } catch (_: Exception) {}
        super.onDestroy()
    }
}

/**
 * Battery icon with proportional fill and an optional charging bolt.
 */
private class BatteryFillDrawable(
    private val percent: Int,
    private val charging: Boolean,
    private val tint: Int
) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1.5f
    }

    override fun draw(canvas: Canvas) {
        val b = bounds
        if (b.isEmpty) return
        val l = b.left.toFloat() + 2f
        val t = b.top.toFloat() + 2f
        val r = b.right.toFloat() - 4f
        val bt = b.bottom.toFloat() - 2f

        stroke.color = tint
        canvas.drawRoundRect(RectF(l, t, r, bt), 3f, 3f, stroke)

        paint.color = tint
        canvas.drawRoundRect(RectF(r, t + (bt - t) * 0.3f, r + 3f, bt - (bt - t) * 0.3f), 1f, 1f, paint)

        val p = percent.coerceIn(0, 100) / 100f
        if (p > 0f) {
            paint.color = tint
            val fl = l + 2f
            val ft = t + 2f + (bt - t - 4f) * (1f - p)
            val fr = r - 2f
            val fb = bt - 2f
            if (fr > fl && fb > ft) {
                canvas.drawRoundRect(RectF(fl, ft, fr, fb), 2f, 2f, paint)
            }
        }

        if (charging) {
            val cx = (l + r) / 2f
            val cy = (t + bt) / 2f
            paint.color = if (tint == Color.BLACK) Color.WHITE else Color.BLACK
            val bolt = Path().apply {
                moveTo(cx + 1f, cy - 5f)
                lineTo(cx - 3f, cy + 1f)
                lineTo(cx - 0.5f, cy + 1f)
                lineTo(cx - 1f, cy + 5f)
                lineTo(cx + 3f, cy - 1f)
                lineTo(cx + 0.5f, cy - 1f)
                close()
            }
            canvas.drawPath(bolt, paint)
        }
    }

    override fun setAlpha(alpha: Int) { paint.alpha = alpha; stroke.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter; stroke.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java")
    override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
}

private class BevelDrawable(
    private val baseColor: Int,
    private val cornerRadius: Float,
    private val thickness: Float
) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val ring = Path()

    override fun draw(canvas: Canvas) {
        val b = bounds
        if (b.isEmpty) return
        val l = b.left.toFloat()
        val t = b.top.toFloat()
        val r = b.right.toFloat()
        val bt = b.bottom.toFloat()
        val radius = cornerRadius.coerceAtMost(b.width() / 2f).coerceAtMost(b.height() / 2f)
        val th = thickness.coerceAtMost(radius * 0.9f).coerceAtLeast(0.5f)

        ring.reset()
        ring.fillType = Path.FillType.EVEN_ODD
        ring.addRoundRect(l, t, r, bt, radius, radius, Path.Direction.CW)
        val ir = (radius - th).coerceAtLeast(0f)
        ring.addRoundRect(l + th, t + th, r - th, bt - th, ir, ir, Path.Direction.CCW)

        val lum = (0.299 * Color.red(baseColor) + 0.587 * Color.green(baseColor) + 0.114 * Color.blue(baseColor)) / 255.0
        val lightFactor = when {
            lum < 0.15 -> 1.35
            lum < 0.35 -> 1.30
            lum > 0.85 -> 1.10
            else -> 1.25
        }
        val darkFactor = when {
            lum < 0.15 -> 0.55
            lum < 0.35 -> 0.65
            lum > 0.85 -> 0.70
            else -> 0.75
        }
        val light = scale(baseColor, lightFactor)
        val dark = scale(baseColor, darkFactor)

        canvas.save()
        canvas.clipPath(ring)
        paint.color = light
        canvas.drawRect(l, t, r, bt, paint)
        canvas.clipRect(l + radius, t + radius, r, bt)
        paint.color = dark
        canvas.drawRect(l, t, r, bt, paint)
        canvas.restore()
    }

    private fun scale(argb: Int, factor: Double): Int {
        val r = (Color.red(argb) * factor).toInt().coerceIn(0, 255)
        val g = (Color.green(argb) * factor).toInt().coerceIn(0, 255)
        val b = (Color.blue(argb) * factor).toInt().coerceIn(0, 255)
        return Color.argb(255, r, g, b)
    }

    override fun setAlpha(alpha: Int) { /* unused */ }
    override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java")
    override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
}
