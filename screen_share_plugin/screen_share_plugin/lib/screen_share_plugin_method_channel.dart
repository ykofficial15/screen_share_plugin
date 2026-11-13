import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;

import 'screen_share_plugin_platform_interface.dart';
import 'src/screen_share_options.dart';

/// Android implementation.
///
/// Order matters on Android 14+ (API 34): the user must accept the
/// MediaProjection dialog *before* a `mediaProjection` foreground service may
/// start, and that service must be running *before* the projection is
/// created. So the sequence is:
///   1. ask for notification permission (Android 13+),
///   2. flutter_webrtc shows the capture dialog and keeps the consent token,
///   3. this plugin starts its foreground service and waits until it is up,
///   4. `getDisplayMedia` reuses the token — no second dialog.
/// On Android 5–9 the service is not required by the OS, but it is still
/// started so the capture survives the app going to the background.
class MethodChannelScreenSharePlugin extends ScreenSharePluginPlatform {
  @visibleForTesting
  final methodChannel =
      const MethodChannel('com.example.screen_share_plugin/screen_capture');

  @override
  Future<void> beforeCapture(ScreenShareOptions options) async {
    await methodChannel.invokeMethod<bool>('requestNotificationPermission');

    final granted = await requestCapturePermission(options.androidFullScreenOnly);
    if (!granted) {
      throw ScreenShareException(
          'PERMISSION_DENIED', 'The user declined screen capture.');
    }

    try {
      await methodChannel.invokeMethod<void>('startForegroundService', {
        'title': options.androidNotificationTitle,
        'text': options.androidNotificationText,
      });
    } on PlatformException catch (e) {
      throw ScreenShareException(e.code, e.message ?? 'Could not start service');
    }
  }

  @override
  Future<void> afterCapture() =>
      methodChannel.invokeMethod<void>('stopForegroundService');

  /// Shows the system screen-capture dialog via flutter_webrtc. Overridable
  /// in tests.
  @visibleForTesting
  Future<bool> requestCapturePermission(bool fullScreenOnly) =>
      Helper.requestCapturePermission(fullScreenOnly: fullScreenOnly);
}
