import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'screen_share_plugin_method_channel.dart';
import 'src/screen_share_options.dart';

/// Platform hooks that run around the flutter_webrtc capture.
///
/// Capture itself is always done by flutter_webrtc's `getDisplayMedia`.
/// A platform only needs to override these hooks when it has to do extra
/// work before or after capturing — today that is only Android, which must
/// obtain consent and run a `mediaProjection` foreground service.
abstract class ScreenSharePluginPlatform extends PlatformInterface {
  ScreenSharePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScreenSharePluginPlatform _instance = MethodChannelScreenSharePlugin();

  /// The active implementation. Defaults to [MethodChannelScreenSharePlugin]
  /// (Android); other platforms replace it when they register.
  static ScreenSharePluginPlatform get instance => _instance;

  static set instance(ScreenSharePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Called right before `getDisplayMedia`. Throws [ScreenShareException]
  /// if sharing must not start.
  Future<void> beforeCapture(ScreenShareOptions options) async {}

  /// Called after the capture stopped or failed to start.
  Future<void> afterCapture() async {}
}

/// Implementation used where flutter_webrtc needs no extra platform work
/// (iOS, macOS, Windows, Linux and Web).
class NoOpScreenSharePlatform extends ScreenSharePluginPlatform {}
