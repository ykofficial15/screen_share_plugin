import 'package:flutter/services.dart';

class ScreenSharePlugin {
  static const MethodChannel _channel =
      MethodChannel('com.example.screen_share_plugin/screen_capture');

  static Future<void> startScreenShare() async {
    await _channel.invokeMethod('requestScreenCapturePermission');
  }

  static Future<void> stopScreenShare() async {
    await _channel.invokeMethod('stopForegroundService');
  }
}
