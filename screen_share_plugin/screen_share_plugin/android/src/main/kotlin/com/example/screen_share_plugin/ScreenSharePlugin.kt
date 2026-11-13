package com.example.screen_share_plugin

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Android side of screen_share_plugin. The capture consent dialog and the
 * capture itself are handled by flutter_webrtc; this plugin supplies what
 * flutter_webrtc leaves to the app: the notification permission and the
 * `mediaProjection` foreground service.
 */
class ScreenSharePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val CHANNEL = "com.example.screen_share_plugin/screen_capture"
        private const val REQUEST_NOTIFICATIONS = 7342
    }

    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var binding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context?.let { ScreenCaptureService.stop(it) }
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding)
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = attach(binding)
    override fun onDetachedFromActivityForConfigChanges() = detach()
    override fun onDetachedFromActivity() = detach()

    private fun attach(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    private fun detach() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
    }

    private val activity: Activity? get() = binding?.activity

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "startForegroundService" -> startService(call, result)
            "stopForegroundService" -> {
                context?.let { ScreenCaptureService.stop(it) }
                result.success(null)
            }
            "isServiceRunning" -> result.success(ScreenCaptureService.isRunning)
            else -> result.notImplemented()
        }
    }

    private fun startService(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.error("NO_CONTEXT", "Plugin not attached", null)
        val title = call.argument<String>("title") ?: "Screen sharing"
        val text = call.argument<String>("text") ?: "Your screen is being shared"
        ScreenCaptureService.start(ctx, title, text) { error ->
            if (error == null) {
                result.success(null)
            } else {
                result.error("SERVICE_FAILED", error.message ?: error.toString(), null)
            }
        }
    }

    /**
     * Android 13+ needs the POST_NOTIFICATIONS runtime permission for the
     * sharing notification to be visible. Sharing still works if the user
     * declines, so this always resolves (true = granted).
     */
    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return result.success(true)
        val ctx = context ?: return result.success(false)
        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED
        ) return result.success(true)

        val act = activity ?: return result.success(false)
        if (pendingPermissionResult != null) return result.success(false)
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        if (requestCode != REQUEST_NOTIFICATIONS) return false
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }
}
