package com.example.lay

import android.app.KeyguardManager
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

class BubbleOverlayManager(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val prefs = context.getSharedPreferences("bubble_prefs", Context.MODE_PRIVATE)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val density = context.resources.displayMetrics.density

    private var bubbleView: View? = null
    private var popupView: View? = null
    private var isPopupShowing = false
    private var isDragging = false
    private var bubbleColor = 0xFF6366F1.toInt()
    private var bubbleSizeDp = 56f
    private var bubbleOpacity = 1.0f
    private var autoHideEnabled = false
    private var autoHideTimeoutMs = 30000L

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    private val bubbleSizePx get() = (bubbleSizeDp * density).toInt()
    private val popupWidthPx get() = (200f * density).toInt()

    private var clipboardListener: ClipboardManager.OnPrimaryClipChangedListener? = null

    fun show() {
        if (bubbleView != null) return
        createBubbleView()
        startClipboardListener()
    }

    fun dismiss() {
        dismissPopup()
        stopClipboardListener()
        cancelAutoHide()
        bubbleView?.let { v ->
            try { windowManager.removeView(v) } catch (_: Exception) {}
        }
        bubbleView = null
    }

    fun updateStyle(color: Int, size: Int, opacity: Float) {
        bubbleColor = color
        bubbleSizeDp = size.toFloat()
        bubbleOpacity = opacity.coerceIn(0.3f, 1.0f)
        bubbleView?.let { view ->
            val bg = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(lightenColor(bubbleColor, 0.1f), bubbleColor)
            ).apply { shape = GradientDrawable.OVAL }
            view.background = bg
            view.alpha = bubbleOpacity
            val newSize = bubbleSizePx
            view.layoutParams?.let { lp ->
                if (lp is WindowManager.LayoutParams) {
                    lp.width = newSize
                    lp.height = newSize
                    try { windowManager.updateViewLayout(view, lp) } catch (_: Exception) {}
                }
            }
        }
    }

    fun setAutoHide(enabled: Boolean, timeoutSeconds: Int) {
        autoHideEnabled = enabled
        autoHideTimeoutMs = (timeoutSeconds * 1000L).coerceAtLeast(5000L)
        if (enabled) startAutoHideTimer() else cancelAutoHide()
    }

    fun isDeviceLocked(): Boolean {
        val km = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return km.isKeyguardLocked
    }

    private fun createBubbleView() {
        val savedX = prefs.getFloat("bubble_x", -1f)
        val savedY = prefs.getFloat("bubble_y", -1f)
        val x = if (savedX > 0) savedX.toInt() else 0
        val y = if (savedY > 0) savedY.toInt() else (context.resources.displayMetrics.heightPixels / 3)

        val params = WindowManager.LayoutParams(
            bubbleSizePx, bubbleSizePx,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            this.x = x; this.y = y
        }

        val bubble = View(context).apply {
            val bg = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(lightenColor(bubbleColor, 0.1f), bubbleColor)
            ).apply { shape = GradientDrawable.OVAL }
            background = bg
            alpha = bubbleOpacity
            elevation = 8f * density
            outlineProvider = ViewOutlineProvider.BACKGROUND
            clipToOutline = true
            setOnTouchListener { _, event -> onTouch(event, params, this); true }
        }

        windowManager.addView(bubble, params)
        bubbleView = bubble
        startAutoHideTimer()
    }

    private fun onTouch(event: MotionEvent, params: WindowManager.LayoutParams, view: View) {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                isDragging = false
                initialX = params.x; initialY = params.y
                initialTouchX = event.rawX; initialTouchY = event.rawY
                cancelAutoHide()
                view.animate().alpha(1f).setDuration(200).start()
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = (event.rawX - initialTouchX).toInt()
                val dy = (event.rawY - initialTouchY).toInt()
                if (dx * dx + dy * dy > (10 * density * 10 * density).toInt()) isDragging = true
                params.x = initialX + dx; params.y = initialY + dy
                dismissPopup()
                try { windowManager.updateViewLayout(view, params) } catch (_: Exception) {}
            }
            MotionEvent.ACTION_UP -> {
                if (isDragging) {
                    snapToEdge(params, view)
                    savePosition(params.x.toFloat(), params.y.toFloat())
                } else {
                    if (isDeviceLocked() && prefs.getBoolean("pin_enabled", false)) {
                        Toast.makeText(context, "Unlock device to use bubble", Toast.LENGTH_SHORT).show()
                    } else {
                        togglePopup(params, view)
                    }
                }
                startAutoHideTimer()
            }
        }
    }

    private fun snapToEdge(params: WindowManager.LayoutParams, view: View) {
        val displayMetrics = context.resources.displayMetrics
        val halfBubble = bubbleSizePx / 2f
        val snapMargin = (16 * density).toInt()
        val targetX: Int

        if (params.x + halfBubble < displayMetrics.widthPixels / 2f) {
            targetX = snapMargin
        } else {
            targetX = displayMetrics.widthPixels - bubbleSizePx - snapMargin
        }

        params.x = targetX
        params.y = params.y.coerceIn(0, displayMetrics.heightPixels - bubbleSizePx)

        try { windowManager.updateViewLayout(view, params) } catch (_: Exception) {}
    }

    private fun togglePopup(params: WindowManager.LayoutParams, anchor: View) {
        if (isPopupShowing) dismissPopup() else showPopup(params, anchor)
    }

    private fun showPopup(params: WindowManager.LayoutParams, anchor: View) {
        if (isPopupShowing) return
        popupView?.let { return }

        val popupWidth = popupWidthPx
        val dm = context.resources.displayMetrics
        var popupX = params.x + bubbleSizePx
        var popupY = params.y + bubbleSizePx / 2
        if (popupX + popupWidth > dm.widthPixels) popupX = params.x - popupWidth

        val popupHeightEst = (200 * density).toInt()
        if (popupY + popupHeightEst > dm.heightPixels) popupY = dm.heightPixels - popupHeightEst

        val popupParams = WindowManager.LayoutParams(
            popupWidth, WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP or Gravity.START; x = popupX; y = popupY }

        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clipText = clipboard.primaryClip?.getItemAt(0)?.text?.toString()

        val popup = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            val p = (12 * density).toInt(); setPadding(p, p, p, p)
            elevation = 12f * density
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadii = floatArrayOf(
                    16f * density, 16f * density, 16f * density, 16f * density,
                    0f, 0f, 0f, 0f
                )
                setColor(ContextCompat.getColor(context, R.color.popup_background))
            }
            background = bg; outlineProvider = ViewOutlineProvider.BACKGROUND; clipToOutline = true

            addPopupButton(this, searchIcon(), "Search") { handleSearch(); dismissPopup() }
            addPopupDivider(this)
            addPopupButton(this, copyIcon(), "Copy") { handleCopy(); dismissPopup() }
            addPopupDivider(this)
            addPopupButton(this, translateIcon(), "Translate") { handleTranslate(); dismissPopup() }
            addPopupDivider(this)
            if (!clipText.isNullOrBlank()) {
                addPopupButton(this, linkIcon(), "Open URL") { handleOpenUrl(); dismissPopup() }
                addPopupDivider(this)
            }
            addPopupButton(this, shareIcon(), "Share") { handleShare(); dismissPopup() }
        }

        popup.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_OUTSIDE) { dismissPopup(); true } else false
        }

        windowManager.addView(popup, popupParams)
        popupView = popup; isPopupShowing = true
    }

    private fun dismissPopup() {
        popupView?.let { v -> try { windowManager.removeView(v) } catch (_: Exception) {} }
        popupView = null; isPopupShowing = false
    }

    private fun addPopupButton(parent: LinearLayout, icon: String, text: String, onClick: () -> Unit) {
        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            val pv = (10 * density).toInt(); val ph = (8 * density).toInt()
            setPadding(ph, pv, ph, pv)
        }
        val label = "$icon  $text"
        val tv = TextView(context).apply {
            this.text = label
            textSize = 14f
            setTextColor(ContextCompat.getColor(context, R.color.popup_text))
            setPadding((8 * density).toInt(), 0, (8 * density).toInt(), 0)
        }
        row.addView(tv)
        row.setOnClickListener { onClick() }
        parent.addView(row)
    }

    private fun addPopupDivider(parent: LinearLayout) {
        View(context).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 1).apply {
                val m = (8 * density).toInt(); setMargins(m, 0, m, 0)
            }
            setBackgroundColor(ContextCompat.getColor(context, R.color.popup_divider))
            parent.addView(this)
        }
    }

    private fun searchIcon() = "\uD83D\uDD0D"
    private fun copyIcon() = "\uD83D\uDCCB"
    private fun translateIcon() = "\uD83C\uDF10"
    private fun linkIcon() = "\uD83D\uDD17"
    private fun shareIcon() = "\uD83D\uDCE4"

    private fun handleSearch() {
        val text = clipboardText() ?: run {
            Toast.makeText(context, "Clipboard is empty", Toast.LENGTH_SHORT).show(); return
        }
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://www.google.com/search?q=${Uri.encode(text)}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            })
        } catch (_: Exception) {
            Toast.makeText(context, "Unable to open browser", Toast.LENGTH_SHORT).show()
        }
        saveClipToHistory(text)
    }

    private fun handleCopy() {
        val text = clipboardText() ?: run {
            Toast.makeText(context, "Clipboard is empty", Toast.LENGTH_SHORT).show(); return
        }
        val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cm.setPrimaryClip(ClipData.newPlainText("text", text))
        Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
        saveClipToHistory(text)
    }

    private fun handleTranslate() {
        val text = clipboardText() ?: run {
            Toast.makeText(context, "Clipboard is empty", Toast.LENGTH_SHORT).show(); return
        }
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://translate.google.com/?text=${Uri.encode(text)}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        } catch (_: Exception) {
            Toast.makeText(context, "Unable to open browser", Toast.LENGTH_SHORT).show()
        }
        saveClipToHistory(text)
    }

    private fun handleOpenUrl() {
        val text = clipboardText() ?: run {
            Toast.makeText(context, "Clipboard is empty", Toast.LENGTH_SHORT).show(); return
        }
        var url = text.trim()
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "https://$url"
        }
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse(url)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        } catch (_: Exception) {
            Toast.makeText(context, "Invalid URL", Toast.LENGTH_SHORT).show()
        }
        saveClipToHistory(text)
    }

    private fun handleShare() {
        val text = clipboardText() ?: run {
            Toast.makeText(context, "Clipboard is empty", Toast.LENGTH_SHORT).show(); return
        }
        try {
            context.startActivity(Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        } catch (_: Exception) {
            Toast.makeText(context, "Unable to share", Toast.LENGTH_SHORT).show()
        }
        saveClipToHistory(text)
    }

    private fun clipboardText(): String? {
        val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        return cm.primaryClip?.getItemAt(0)?.text?.toString()?.takeUnless { it.isBlank() }
    }

    private fun saveClipToHistory(text: String) {
        val clips = try {
            val json = prefs.getString("clip_history", null) ?: return
            JSONArray(json)
        } catch (_: Exception) { JSONArray() }

        for (i in 0 until clips.length()) {
            if (clips.getJSONObject(i).getString("text") == text) {
                clips.remove(i)
                break
            }
        }

        val entry = JSONObject().apply {
            put("text", text)
            put("timestamp", System.currentTimeMillis())
        }
        clips.put(0, entry)

        while (clips.length() > 100) clips.remove(clips.length() - 1)

        prefs.edit().putString("clip_history", clips.toString()).apply()
    }

    fun getClipHistory(): List<Map<String, Any>> {
        val json = prefs.getString("clip_history", null) ?: return emptyList()
        val result = mutableListOf<Map<String, Any>>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                result.add(mapOf(
                    "text" to obj.getString("text"),
                    "timestamp" to obj.getLong("timestamp")
                ))
            }
        } catch (_: Exception) {}
        return result
    }

    private fun startClipboardListener() {
        val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboardListener = ClipboardManager.OnPrimaryClipChangedListener {
            val text = clipboardText()
            if (text != null) {
                saveClipToHistory(text)
            }
            if (autoHideEnabled) {
                bubbleView?.animate()?.alpha(1f)?.setDuration(200)?.start()
                cancelAutoHide()
                startAutoHideTimer()
            }
        }
        cm.addPrimaryClipChangedListener(clipboardListener)
    }

    private fun stopClipboardListener() {
        val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboardListener?.let { cm.removePrimaryClipChangedListener(it) }
        clipboardListener = null
    }

    private var autoHideRunnable: Runnable? = null

    private fun startAutoHideTimer() {
        cancelAutoHide()
        if (!autoHideEnabled) return
        val runnable = Runnable {
            bubbleView?.animate()?.alpha(0.3f)?.setDuration(500)?.start()
        }
        autoHideRunnable = runnable
        mainHandler.postDelayed(runnable, autoHideTimeoutMs)
    }

    private fun cancelAutoHide() {
        autoHideRunnable?.let { mainHandler.removeCallbacks(it) }
        autoHideRunnable = null
    }

    private fun savePosition(x: Float, y: Float) {
        prefs.edit().putFloat("bubble_x", x).putFloat("bubble_y", y).apply()
    }

    private fun lightenColor(color: Int, factor: Float): Int {
        return Color.argb(
            Color.alpha(color),
            (Color.red(color) + (255 - Color.red(color)) * factor).toInt().coerceIn(0, 255),
            (Color.green(color) + (255 - Color.green(color)) * factor).toInt().coerceIn(0, 255),
            (Color.blue(color) + (255 - Color.blue(color)) * factor).toInt().coerceIn(0, 255)
        )
    }

    fun openAutoStartSettings() {
        val manufacturer = Build.MANUFACTURER.lowercase()
        try {
            val intent = when {
                manufacturer.contains("xiaomi") -> Intent().apply {
                    action = "miui.intent.action.OP_AUTO_START"
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    setComponent(android.content.ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    ))
                }
                else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            context.startActivity(intent)
        } catch (_: Exception) {
            try {
                context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            } catch (_: Exception) {}
        }
    }
}
