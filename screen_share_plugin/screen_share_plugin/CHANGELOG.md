# Changelog

## 1.0.0

**Breaking:** `startScreenShare()` now performs the capture and returns the `MediaStream`. Remove your own `getDisplayMedia` call (see "Migrating from 0.0.x" in the README).

### Added
- Support for **iOS, macOS, Windows, Linux and Web**, alongside Android.
- `ScreenShareOptions`: audio, frame rate, size, Android notification text, Android 14+ full-screen-only mode, iOS Broadcast Extension mode.
- `getSources()` and `supportsSourceSelection` for screen/window pickers on desktop.
- `sharing` (`ValueNotifier<bool>`), `currentStream`, `isSharing`, `isSupported`, and an `onStopped` callback. These also report when the user ends sharing outside the app.
- `ScreenShareException` with error codes (`PERMISSION_DENIED`, `UNSUPPORTED`, `NO_SOURCE`, `CAPTURE_FAILED`).
- System audio capture on Web, Windows and Linux.

### Fixed (Android)
- Works on Android 14+ (API 34+). The foreground service now starts after the user's consent and before capture, as Android requires.
- The capture permission dialog is shown once instead of twice.
- The foreground service is declared with type `mediaProjection` and started correctly on every version from Android 5.0 to 16.
- Requests the notification permission on Android 13+.
- Builds in host apps on Android Gradle Plugin 8.x and 9.x.

### Removed
- Unneeded `CAMERA`, `RECORD_AUDIO` and `READ_EXTERNAL_STORAGE` permissions.
- The unused `getPlatformVersion` method.

## 0.0.2

- Initial release: Android screen sharing with a foreground service and `flutter_webrtc` preview.
