import '../screen_share_plugin_platform_interface.dart';

/// Registered on iOS, macOS, Windows and Linux. flutter_webrtc handles the
/// native capture on these platforms, so no extra hooks are needed.
class ScreenSharePluginDesktopAndIos {
  static void registerWith() {
    ScreenSharePluginPlatform.instance = NoOpScreenSharePlatform();
  }
}
