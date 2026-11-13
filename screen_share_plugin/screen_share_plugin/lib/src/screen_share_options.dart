/// Options for [ScreenSharePlugin.startScreenShare].
class ScreenShareOptions {
  const ScreenShareOptions({
    this.audio = false,
    this.frameRate = 30,
    this.width,
    this.height,
    this.androidNotificationTitle = 'Screen sharing',
    this.androidNotificationText = 'Your screen is being shared',
    this.androidFullScreenOnly = false,
    this.iosUseBroadcastExtension = false,
  });

  /// Also capture system/tab audio where the platform supports it
  /// (Web: Chrome/Edge tab or system audio; Windows: WASAPI loopback;
  /// Linux: PulseAudio loopback). Ignored on Android, iOS and macOS.
  final bool audio;

  /// Requested frame rate. Honoured on Web and desktop; Android and iOS
  /// capture at the platform's native rate.
  final int frameRate;

  /// Preferred capture size. Honoured on Web only; native platforms capture
  /// the full resolution of the selected screen or window.
  final int? width;
  final int? height;

  /// Text of the persistent notification Android shows while sharing
  /// (Android requires a visible foreground-service notification).
  final String androidNotificationTitle;
  final String androidNotificationText;

  /// Android 14+: hide the "single app" option in the system dialog so the
  /// user can only share the entire screen.
  final bool androidFullScreenOnly;

  /// iOS: capture the whole device (including other apps) through a
  /// ReplayKit Broadcast Upload Extension instead of only this app.
  /// Requires the extension and App Group to be set up — see the README.
  final bool iosUseBroadcastExtension;
}

/// Thrown when screen sharing cannot start (for example the user declined
/// the system dialog, or the platform is not supported).
class ScreenShareException implements Exception {
  ScreenShareException(this.code, this.message);

  /// Machine-readable reason, e.g. `PERMISSION_DENIED`, `UNSUPPORTED`,
  /// `NO_SOURCE`, `CAPTURE_FAILED`.
  final String code;
  final String message;

  @override
  String toString() => 'ScreenShareException($code): $message';
}
