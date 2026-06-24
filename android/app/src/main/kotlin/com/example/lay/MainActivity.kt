package com.example.lay

import android.Manifest
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.orb/bubble"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        setupMethodCallHandler()
    }

    override fun onResume() {
        super.onResume()
        methodChannel?.invokeMethod("onAppResumed", null)
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    ContextCompat.startForegroundService(
                        this, Intent(this, BubbleService::class.java).apply {
                            action = BubbleService.ACTION_SHOW
                        }
                    )
                    result.success(true)
                }

                "stopService" -> {
                    startService(Intent(this, BubbleService::class.java).apply {
                        action = BubbleService.ACTION_STOP
                    })
                    result.success(true)
                }

                "isServiceRunning" -> {
                    val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
                    val running = manager.getRunningServices(Integer.MAX_VALUE).any {
                        BubbleService::class.java.name == it.service.className
                    }
                    result.success(running)
                }

                "checkOverlayPermission" -> {
                    result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this) else true
                    )
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        startActivity(Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        ))
                    }
                    result.success(true)
                }

                "checkNotificationPermission" -> {
                    result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        else true
                    )
                }

                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1003)
                    }
                    result.success(true)
                }

                "checkBatteryOptimization" -> {
                    result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            (getSystemService(POWER_SERVICE) as android.os.PowerManager).isIgnoringBatteryOptimizations(packageName)
                        else true
                    )
                }

                "requestBatteryOptimization" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            android.net.Uri.parse("package:$packageName")))
                    } catch (_: Exception) {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            android.net.Uri.parse("package:$packageName")))
                    }
                    result.success(true)
                }

                "openAutoStartSettings" -> {
                    BubbleOverlayManager(this).openAutoStartSettings()
                    result.success(true)
                }

                "updateBubbleStyle" -> {
                    val color = (call.argument<Int>("color") ?: 0xFF6366F1.toInt())
                    val size = (call.argument<Int>("size") ?: 56)
                    val opacity = (call.argument<Double>("opacity") ?: 1.0).toFloat()
                    BubbleService.activeInstance?.overlayManager?.updateStyle(color, size, opacity)
                    result.success(true)
                }

                "setAutoHide" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val timeout = call.argument<Int>("timeoutSeconds") ?: 30
                    BubbleService.activeInstance?.overlayManager?.setAutoHide(enabled, timeout)
                    result.success(true)
                }

                "isDeviceLocked" -> {
                    val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
                    result.success(km.isKeyguardLocked)
                }

                "getNativeClips" -> {
                    val clips = BubbleService.activeInstance?.overlayManager?.getClipHistory() ?: emptyList()
                    result.success(clips)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
