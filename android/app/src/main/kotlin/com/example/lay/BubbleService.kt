package com.example.lay

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BubbleService : Service() {

    lateinit var overlayManager: BubbleOverlayManager
        private set

    override fun onCreate() {
        super.onCreate()
        overlayManager = BubbleOverlayManager(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_HIDE -> {
                overlayManager.dismiss()
                return START_STICKY
            }
            ACTION_SHOW -> {
                startForeground(NOTIFICATION_ID, createNotification())
                overlayManager.show()
                return START_STICKY
            }
            else -> {
                startForeground(NOTIFICATION_ID, createNotification())
                overlayManager.show()
                return START_STICKY
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        overlayManager.dismiss()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    private fun createNotification(): Notification {
        val channelId = NOTIFICATION_CHANNEL_ID
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Bubble Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Foreground service for the floating bubble overlay"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Lay Bubble")
            .setContentText("Floating bubble is active")
            .setSmallIcon(android.R.drawable.ic_menu_search)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    companion object {
        const val NOTIFICATION_ID = 1001
        const val NOTIFICATION_CHANNEL_ID = "bubble_service_channel"
        const val OVERLAY_PERMISSION_REQUEST_CODE = 1002
        const val ACTION_STOP = "com.example.lay.action.STOP"
        const val ACTION_HIDE = "com.example.lay.action.HIDE"
        const val ACTION_SHOW = "com.example.lay.action.SHOW"
    }
}
