package com.example.screen_share_plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

internal class ScreenSharePluginTest {
    @Test
    fun onMethodCall_unknownMethod_isNotImplemented() {
        val plugin = ScreenSharePlugin()
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(MethodCall("doesNotExist", null), result)

        Mockito.verify(result).notImplemented()
    }

    @Test
    fun onMethodCall_isServiceRunning_falseByDefault() {
        val plugin = ScreenSharePlugin()
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(MethodCall("isServiceRunning", null), result)

        Mockito.verify(result).success(false)
    }
}
