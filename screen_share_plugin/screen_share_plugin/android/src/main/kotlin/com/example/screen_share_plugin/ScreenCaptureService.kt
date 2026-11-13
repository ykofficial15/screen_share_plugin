package com.example.screen_share_plugin

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Foreground service that keeps screen capture alive.
 *
 * - Android 10+ (API 29): MediaProjection may only be created while a
 *   foreground service of type `mediaProjection` is running.
 * - Android 14+ (API 34): that service may only start after the user
 *   accepted the capture dialog, and needs FOREGROUND_SERVICE_MEDIA_PROJECTION.
 * - Android 5–9: not required by the OS, but keeps the process (and the
 *   capture) alive while the app is in the background.
 */
class ScreenCaptureService : Service() {

    companion object {
        private const val CHANNEL_ID = "screen_share_plugin_channel"
        private const val NOTIFICATION_ID = 7341
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val START_TIMEOUT_MS = 5000L

        private val mainHandler = Handler(Looper.getMainLooper())
        private var pendingStart: ((Throwable?) -> Unit)? = null

        @Volatile
        var isRunning = false
            private set

        /**
         * Starts the service and calls [onResult] on the main thread once it is
         * in the foreground (null) or failed to get there (the error).
         */
        fun start(context: Context, title: String, text: String, onResult: (Throwable?) -> Unit) {
            deliver(IllegalStateException("Superseded by a newer start request"))

            val timeout = Runnable {
                deliver(IllegalStateException("Foreground service did not start in time"))
            }
            mainHandler.postDelayed(timeout, START_TIMEOUT_MS)
            pendingStart = { error ->
                mainHandler.removeCallbacks(timeout)
                onResult(error)
            }

            val intent = Intent(context, ScreenCaptureService::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text)
            try {
                // startForegroundService on API 26+, startService below.
                ContextCompat.startForegroundService(context, intent)
            } catch (e: Exception) {
                // e.g. ForegroundServiceStartNotAllowedException (API 31+).
                deliver(e)
            }
        }

        fun stop(context: Context) {
            deliver(IllegalStateException("Stopped before it started"))
            context.stopService(Intent(context, ScreenCaptureService::class.java))
        }

        private fun deliver(error: Throwable?) {
            val callback = pendingStart ?: return
            pendingStart = null
            callback(error)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Screen sharing"
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: "Your screen is being shared"

        try {
            createChannelIfNeeded()
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            } else {
                0
            }
            ServiceCompat.startForeground(this, NOTIFICATION_ID, buildNotification(title, text), type)
            isRunning = true
            deliver(null)
        } catch (e: Exception) {
            // API 34+ throws SecurityException if capture consent was not given.
            isRunning = false
            deliver(e)
            stopSelf()
        }
        // Never restart automatically: a restarted service has no capture to keep alive.
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        isRunning = false
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(CHANNEL_ID, "Screen sharing", NotificationManager.IMPORTANCE_LOW)
        channel.setShowBadge(false)
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(title: String, text: String) =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_share)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .apply { launchIntent()?.let { setContentIntent(it) } }
            .build()

    /** Tapping the notification brings the app back to the front. */
    private fun launchIntent(): PendingIntent? {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        launch.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, 0, launch, flags)
    }
}
