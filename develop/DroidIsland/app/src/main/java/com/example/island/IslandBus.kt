package com.example.island

import android.app.PendingIntent
import android.graphics.drawable.Drawable

object IslandBus {
    data class Notif(
        val app: String, val pkg: String, val title: String, val body: String,
        val pi: PendingIntent?, val key: String?
    )
    @Volatile var running = false
    var listener: ((Notif) -> Unit)? = null
    var reposition: (() -> Unit)? = null
    var refreshBar: (() -> Unit)? = null
    var icons: ((List<Drawable>) -> Unit)? = null
    var refreshIcons: (() -> Unit)? = null
    var cancel: ((String) -> Unit)? = null
    var onListenerConnected: (() -> Unit)? = null
    fun post(n: Notif) { listener?.invoke(n) }
}
