package com.example.lay

import android.Manifest
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
                    val intent = Intent(this, BubbleService::class.java).apply {
                        action = BubbleService.ACTION_SHOW
                    }
                    ContextCompat.startForegroundService(this, intent)
                    result.success(true)
                }

                "stopService" -> {
                    val intent = Intent(this, BubbleService::class.java).apply {
                        action = BubbleService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }

                "isServiceRunning" -> {
                    val manager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
                    val running = manager.getRunningServices(Integer.MAX_VALUE).any {
                        BubbleService::class.java.name == it.service.className
                    }
                    result.success(running)
                }

                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !checkOverlayPermission()) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }

                "checkNotificationPermission" -> {
                    result.success(checkNotificationPermission())
                }

                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !checkNotificationPermission()) {
                        requestPermissions(
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            NOTIFICATION_PERMISSION_REQUEST_CODE
                        )
                    }
                    result.success(true)
                }

                "getBubblePosition" -> {
                    val prefs = getSharedPreferences("bubble_prefs", MODE_PRIVATE)
                    val x = prefs.getFloat("bubble_x", -1f).toDouble()
                    val y = prefs.getFloat("bubble_y", -1f).toDouble()
                    result.success(mapOf("x" to x, "y" to y))
                }

                "checkBatteryOptimization" -> {
                    result.success(checkBatteryOptimization())
                }

                "requestBatteryOptimization" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            android.net.Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    } catch (_: Exception) {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            android.net.Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }

                "openAutoStartSettings" -> {
                    BubbleOverlayManager(this).openAutoStartSettings()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun checkNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun checkBatteryOptimization(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as android.os.PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1003
    }
}
