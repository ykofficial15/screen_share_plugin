/// Cross-platform screen sharing for Flutter.
///
/// Supports Android (5.0+), iOS, macOS, Windows, Linux and Web. The returned
/// [MediaStream] is a regular flutter_webrtc stream: show it with
/// [RTCVideoView] or add its tracks to an `RTCPeerConnection`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'screen_share_plugin_platform_interface.dart';
import 'src/screen_share_options.dart';

export 'package:flutter_webrtc/flutter_webrtc.dart'
    show
        DesktopCapturerSource,
        MediaStream,
        MediaStreamTrack,
        RTCVideoRenderer,
        RTCVideoView,
        RTCVideoViewObjectFit,
        SourceType,
        ThumbnailSize;
export 'src/screen_share_options.dart';
export 'src/screen_share_plugin_desktop_and_ios.dart';

class ScreenSharePlugin {
  ScreenSharePlugin._();

  static MediaStream? _stream;
  static Future<void>? _stopping;

  /// Notifies listeners whenever sharing starts or stops — including when the
  /// user ends it from outside the app (browser "Stop sharing" bar, closing
  /// the shared window, revoking capture in the system UI).
  static final ValueNotifier<bool> sharing = ValueNotifier<bool>(false);

  /// The stream currently being captured, if any.
  static MediaStream? get currentStream => _stream;

  /// Whether a capture is currently running.
  static bool get isSharing => _stream != null;

  /// Whether screen sharing is available on the current platform.
  static bool get isSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// `true` on macOS, Windows and Linux, where the app chooses which screen
  /// or window to capture (use [getSources] to build a picker). On Android,
  /// iOS and Web the operating system or browser shows its own picker.
  static bool get supportsSourceSelection =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Lists the screens and/or windows that can be captured.
  /// Desktop only — see [supportsSourceSelection].
  static Future<List<DesktopCapturerSource>> getSources({
    List<SourceType> types = const [SourceType.Screen, SourceType.Window],
    ThumbnailSize? thumbnailSize,
  }) {
    if (!supportsSourceSelection) {
      throw ScreenShareException('UNSUPPORTED',
          'getSources is only available on macOS, Windows and Linux.');
    }
    return desktopCapturer.getSources(
      types: types,
      thumbnailSize: thumbnailSize ?? ThumbnailSize(320, 180),
    );
  }

  /// Starts capturing the screen and returns the captured stream.
  ///
  /// * [source] — desktop only: the screen/window to capture (from
  ///   [getSources]). Defaults to the primary screen.
  /// * [onStopped] — called once when sharing ends for any reason.
  ///
  /// Throws [ScreenShareException] if the user declines or capture fails.
  /// If a share is already running it is stopped first.
  static Future<MediaStream> startScreenShare({
    ScreenShareOptions options = const ScreenShareOptions(),
    DesktopCapturerSource? source,
    VoidCallback? onStopped,
  }) async {
    if (!isSupported) {
      throw ScreenShareException(
          'UNSUPPORTED', 'Screen sharing is not supported on this platform.');
    }
    await stopScreenShare();

    final platform = ScreenSharePluginPlatform.instance;
    await platform.beforeCapture(options);

    final MediaStream stream;
    try {
      final constraints = await _buildConstraints(options, source);
      stream = await navigator.mediaDevices.getDisplayMedia(constraints);
    } catch (e) {
      await platform.afterCapture();
      if (e is ScreenShareException) rethrow;
      throw ScreenShareException(_isDenial(e) ? 'PERMISSION_DENIED' : 'CAPTURE_FAILED', '$e');
    }

    _stream = stream;
    sharing.value = true;

    var notified = false;
    void handleEnded() {
      if (notified || !identical(_stream, stream)) return;
      notified = true;
      stopScreenShare();
      onStopped?.call();
    }

    for (final track in stream.getTracks()) {
      track.onEnded = handleEnded;
    }
    stream.onRemoveTrack = (_) {
      if (stream.getVideoTracks().isEmpty) handleEnded();
    };
    return stream;
  }

  /// Stops the current capture (if any) and releases platform resources
  /// such as the Android foreground service. Safe to call repeatedly.
  static Future<void> stopScreenShare() {
    return _stopping ??= _stop().whenComplete(() => _stopping = null);
  }

  static Future<void> _stop() async {
    final stream = _stream;
    if (stream == null) return;
    _stream = null;
    for (final track in stream.getTracks()) {
      track.onEnded = null;
      try {
        await track.stop();
      } catch (_) {}
    }
    try {
      await stream.dispose();
    } catch (_) {}
    await ScreenSharePluginPlatform.instance.afterCapture();
    sharing.value = false;
  }

  static Future<Map<String, dynamic>> _buildConstraints(
      ScreenShareOptions options, DesktopCapturerSource? source) async {
    if (kIsWeb) {
      return {
        'audio': options.audio,
        'video': {
          'frameRate': {'ideal': options.frameRate},
          if (options.width != null) 'width': {'ideal': options.width},
          if (options.height != null) 'height': {'ideal': options.height},
        },
      };
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return {'audio': false, 'video': true};
      case TargetPlatform.iOS:
        return {
          'audio': false,
          'video': options.iosUseBroadcastExtension
              ? {'deviceId': 'broadcast'}
              : true,
        };
      default: // macOS, Windows, Linux
        source ??= await _defaultScreen();
        return {
          'audio': options.audio &&
              defaultTargetPlatform != TargetPlatform.macOS,
          'video': {
            'deviceId': {'exact': source.id},
            'mandatory': {'frameRate': options.frameRate.toDouble()},
          },
        };
    }
  }

  static Future<DesktopCapturerSource> _defaultScreen() async {
    final screens = await desktopCapturer.getSources(types: [SourceType.Screen]);
    if (screens.isEmpty) {
      throw ScreenShareException(
          'NO_SOURCE',
          defaultTargetPlatform == TargetPlatform.macOS
              ? 'No screen available. Allow this app under System Settings > '
                  'Privacy & Security > Screen Recording, then restart it.'
              : 'No screen available to capture.');
    }
    return screens.first;
  }

  static bool _isDenial(Object e) {
    final s = e.toString();
    return s.contains('NotAllowedError') ||
        s.contains('Permission') ||
        s.contains('permission') ||
        s.contains('denied');
  }
}
