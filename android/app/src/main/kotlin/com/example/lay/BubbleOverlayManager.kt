package com.example.lay

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
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
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat

class BubbleOverlayManager(private val context: Context) {

    private val windowManager: WindowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var bubbleView: View? = null
    private var popupView: View? = null
    private var isPopupShowing = false
    private var isDragging = false

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    private val prefs = context.getSharedPreferences("bubble_prefs", Context.MODE_PRIVATE)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val density = context.resources.displayMetrics.density

    private val bubbleSizeDp = 56f
    private val bubbleSizePx = (bubbleSizeDp * density).toInt()
    private val popupWidthDp = 200f
    private val popupWidthPx = (popupWidthDp * density).toInt()

    fun show() {
        if (bubbleView != null) return
        createBubbleView()
    }

    fun dismiss() {
        dismissPopup()
        bubbleView?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (_: Exception) {}
        }
        bubbleView = null
    }

    val isBubbleShowing: Boolean get() = bubbleView != null

    fun getBubblePosition(): Pair<Float, Float> {
        val savedX = prefs.getFloat("bubble_x", -1f)
        val savedY = prefs.getFloat("bubble_y", -1f)
        return Pair(savedX, savedY)
    }

    private fun createBubbleView() {
        val savedX = prefs.getFloat("bubble_x", -1f)
        val savedY = prefs.getFloat("bubble_y", -1f)
        var x = if (savedX > 0) savedX.toInt() else 0
        var y = if (savedY > 0) savedY.toInt() else (context.resources.displayMetrics.heightPixels / 3)

        val params = WindowManager.LayoutParams(
            bubbleSizePx,
            bubbleSizePx,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            this.x = x
            this.y = y
        }

        val bubble = View(context).apply {
            val drawable = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(
                    ContextCompat.getColor(context, R.color.bubble_gradient_start),
                    ContextCompat.getColor(context, R.color.bubble_gradient_end)
                )
            ).apply { shape = GradientDrawable.OVAL }
            background = drawable

            elevation = 8f * density
            outlineProvider = ViewOutlineProvider.BACKGROUND
            clipToOutline = true

            setOnTouchListener { _, event ->
                onTouch(event, params, this)
                true
            }
        }

        windowManager.addView(bubble, params)
        bubbleView = bubble
    }

    private fun onTouch(event: MotionEvent, params: WindowManager.LayoutParams, view: View) {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                isDragging = false
                initialX = params.x
                initialY = params.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = (event.rawX - initialTouchX).toInt()
                val dy = (event.rawY - initialTouchY).toInt()
                if (dx * dx + dy * dy > (10 * density * 10 * density).toInt()) {
                    isDragging = true
                }
                params.x = initialX + dx
                params.y = initialY + dy
                dismissPopup()
                try {
                    windowManager.updateViewLayout(view, params)
                } catch (_: Exception) {}
            }
            MotionEvent.ACTION_UP -> {
                if (!isDragging) {
                    togglePopup(params, view)
                } else {
                    savePosition(params.x.toFloat(), params.y.toFloat())
                }
            }
        }
    }

    private fun togglePopup(params: WindowManager.LayoutParams, anchor: View) {
        if (isPopupShowing) {
            dismissPopup()
        } else {
            showPopup(params, anchor)
        }
    }

    private fun showPopup(params: WindowManager.LayoutParams, anchor: View) {
        if (isPopupShowing) return
        popupView?.let { return }

        val popupWidth = popupWidthPx
        val displayMetrics = context.resources.displayMetrics

        var popupX = params.x + bubbleSizePx
        var popupY = params.y + bubbleSizePx / 2

        if (popupX + popupWidth > displayMetrics.widthPixels) {
            popupX = params.x - popupWidth
        }

        if (popupY + (120 * density) > displayMetrics.heightPixels) {
            popupY = displayMetrics.heightPixels - (120 * density).toInt()
        }

        val popupParams = WindowManager.LayoutParams(
            popupWidth,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = popupX
            y = popupY
        }

        val popup = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            val paddingDp = (12 * density).toInt()
            setPadding(paddingDp, paddingDp, paddingDp, paddingDp)
            elevation = 12f * density

            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadii = floatArrayOf(16f * density, 16f * density, 16f * density, 16f * density, 0f, 0f, 0f, 0f)
                setColor(ContextCompat.getColor(context, R.color.popup_background))
            }
            background = bg
            outlineProvider = ViewOutlineProvider.BACKGROUND
            clipToOutline = true

            addView(createPopupButton("Search", 0xFF6366F1.toInt()) {
                handleSearch()
                dismissPopup()
            })
            addView(createPopupDivider())
            addView(createPopupButton("Copy", 0xFF8B5CF6.toInt()) {
                handleCopy()
                dismissPopup()
            })
        }

        popup.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_OUTSIDE) {
                dismissPopup()
                return@setOnTouchListener true
            }
            false
        }

        windowManager.addView(popup, popupParams)
        popupView = popup
        isPopupShowing = true
    }

    private fun dismissPopup() {
        popupView?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (_: Exception) {}
        }
        popupView = null
        isPopupShowing = false
    }

    private fun createPopupButton(text: String, color: Int, onClick: () -> Unit): View {
        val button = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            val paddingV = (10 * density).toInt()
            val paddingH = (8 * density).toInt()
            setPadding(paddingH, paddingV, paddingH, paddingV)
        }

        val label = TextView(context).apply {
            this.text = text
            textSize = 14f
            setTextColor(ContextCompat.getColor(context, R.color.popup_text))
            val pad = (8 * density).toInt()
            setPadding(pad, 0, pad, 0)
        }
        button.addView(label)
        button.setOnClickListener { onClick() }
        return button
    }

    private fun createPopupDivider(): View {
        return View(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                1
            ).apply {
                val m = (8 * density).toInt()
                setMargins(m, 0, m, 0)
            }
            setBackgroundColor(ContextCompat.getColor(context, R.color.popup_divider))
        }
    }

    private fun handleSearch() {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        val text = clip?.getItemAt(0)?.text?.toString()

        if (text.isNullOrBlank()) {
            Toast.makeText(context, "Clipboard is empty", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://www.google.com/search?q=${Uri.encode(text)}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(intent)
        } catch (_: Exception) {
            Toast.makeText(context, "Unable to open browser", Toast.LENGTH_SHORT).show()
        }
    }

    private fun handleCopy() {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        val text = clip?.getItemAt(0)?.text?.toString()

        if (text.isNullOrBlank()) {
            Toast.makeText(context, "Clipboard is empty", Toast.LENGTH_SHORT).show()
            return
        }

        clipboard.setPrimaryClip(ClipData.newPlainText("text", text))
        Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
    }

    private fun savePosition(x: Float, y: Float) {
        prefs.edit().putFloat("bubble_x", x).putFloat("bubble_y", y).apply()
    }

    fun requestOverlayPermission(activity: android.app.Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(context)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${context.packageName}")
                )
                activity.startActivityForResult(intent, BubbleService.OVERLAY_PERMISSION_REQUEST_CODE)
            }
        }
    }

    fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun openBatteryOptimizationSettings() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    fun openAutoStartSettings() {
        val manufacturer = Build.MANUFACTURER.lowercase()
        try {
            val intent = when {
                manufacturer.contains("xiaomi") -> {
                    Intent().apply {
                        action = "miui.intent.action.OP_AUTO_START"
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        setComponent(
                            android.content.ComponentName(
                                "com.miui.securitycenter",
                                "com.miui.permcenter.autostart.AutoStartManagementActivity"
                            )
                        )
                    }
                }
                manufacturer.contains("oppo") || manufacturer.contains("oneplus") -> {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${context.packageName}")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                manufacturer.contains("vivo") -> {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${context.packageName}")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                manufacturer.contains("samsung") -> {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${context.packageName}")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                else -> {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${context.packageName}")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
            }
            context.startActivity(intent)
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            return powerManager.isIgnoringBatteryOptimizations(context.packageName)
        }
        return true
    }
}
