# screen_share_plugin

Screen sharing for Flutter on **Android, iOS, macOS, Windows, Linux and Web**, with one API.

Capture is done by [flutter_webrtc](https://pub.dev/packages/flutter_webrtc), so the result is a normal WebRTC `MediaStream`. You can preview it with `RTCVideoView` or send it to a peer with an `RTCPeerConnection`. This plugin adds the platform work around that:

- **Android:** the permission flow and the `mediaProjection` foreground service that Android requires, in the right order for every version from 5.0 (API 21) to 16.
- **macOS / Windows / Linux:** listing screens and windows so your app can show its own picker.
- **iOS:** in-app capture through ReplayKit, or whole-device capture through a Broadcast Upload Extension.
- **Web:** the browser's own picker, with optional tab or system audio.

| Platform | What gets captured | Who shows the picker | System audio |
|---|---|---|---|
| Android 5.0+ | Entire screen or one app (Android 14+) | Android system dialog | – |
| iOS 13+ | This app (default) or the whole device (Broadcast Extension) | iOS | – |
| macOS 10.15+ | Any screen or window | Your app (`getSources`) | – |
| Windows | Any screen or window | Your app (`getSources`) | ✓ |
| Linux | Any screen or window | Your app (`getSources`) | ✓ (PulseAudio) |
| Web | Tab, window or screen | The browser | ✓ (Chrome / Edge) |

## Installation

```yaml
dependencies:
  screen_share_plugin: ^1.0.0
```

`flutter_webrtc` comes in as a dependency, and the classes you need from it (`MediaStream`, `RTCVideoRenderer`, `RTCVideoView`, …) are re-exported. Importing `package:screen_share_plugin/screen_share_plugin.dart` is enough.

## Usage

```dart
import 'package:screen_share_plugin/screen_share_plugin.dart';

final renderer = RTCVideoRenderer();
await renderer.initialize();

try {
  // On macOS / Windows / Linux you may pass a `source:` from
  // ScreenSharePlugin.getSources(); without one, the primary screen is used.
  final stream = await ScreenSharePlugin.startScreenShare(
    options: const ScreenShareOptions(audio: true),
    onStopped: () => print('Sharing ended'),
  );
  renderer.srcObject = stream; // show it with RTCVideoView(renderer)
  // ...or add stream.getTracks() to an RTCPeerConnection.
} on ScreenShareException catch (e) {
  // e.code is PERMISSION_DENIED, UNSUPPORTED, NO_SOURCE or CAPTURE_FAILED
}

await ScreenSharePlugin.stopScreenShare();
```

### Letting the user choose a screen or window (desktop)

```dart
if (ScreenSharePlugin.supportsSourceSelection) {
  final sources = await ScreenSharePlugin.getSources(
    types: [SourceType.Screen, SourceType.Window],
  );
  // Show sources[i].name and sources[i].thumbnail in your own UI, then:
  await ScreenSharePlugin.startScreenShare(source: chosen);
}
```

The example app includes a ready-made picker dialog (`SourcePickerDialog`).

### Reacting to sharing ending

The user can end sharing outside your app, from the browser's "Stop sharing" bar, by closing the shared window, or from the system UI. Listen to `ScreenSharePlugin.sharing` (a `ValueNotifier<bool>`) or pass `onStopped`.

### API

| Member | Description |
|---|---|
| `startScreenShare({options, source, onStopped})` | Starts capture and returns the `MediaStream`. Stops any running share first. |
| `stopScreenShare()` | Stops capture and releases platform resources. Safe to call at any time. |
| `getSources({types, thumbnailSize})` | Desktop only: lists screens and windows with thumbnails. |
| `sharing` | `ValueNotifier<bool>` that is true while a share is running. |
| `currentStream`, `isSharing` | The current share, if any. |
| `isSupported`, `supportsSourceSelection` | Platform capability checks. |

`ScreenShareOptions`: `audio`, `frameRate`, `width`/`height` (Web), `androidNotificationTitle`/`androidNotificationText`, `androidFullScreenOnly` (Android 14+), `iosUseBroadcastExtension`.

## Platform setup

### Android

No manual setup is needed. The plugin's manifest adds the `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PROJECTION` and `POST_NOTIFICATIONS` permissions, plus the foreground service declaration.

When sharing starts, the user sees:

1. **Android 13+:** a notification permission prompt. Sharing still works if they decline; the notification just isn't shown.
2. The system "Share your screen?" dialog, **shown once**.
3. A persistent "Your screen is being shared" notification while sharing.

The plugin's minimum is API 21. Apps built with recent Flutter versions start at API 24 anyway. The plugin works with host apps on Android Gradle Plugin 8.x and 9.x.

### iOS

**In-app capture (default)** needs no setup. Only your app's own screen is captured.

**Whole-device capture:** set `ScreenShareOptions(iosUseBroadcastExtension: true)`, then:

1. In Xcode, add a **Broadcast Upload Extension** target to the Runner project.
2. Give both Runner and the extension the same **App Group** (for example `group.com.yourcompany.yourapp`).
3. In `Runner/Info.plist`, add:
   ```xml
   <key>RTCAppGroupIdentifier</key>
   <string>group.com.yourcompany.yourapp</string>
   <key>RTCScreenSharingExtension</key>
   <string>com.yourcompany.yourapp.BroadcastExtension</string>
   ```
4. Implement the extension's `SampleHandler` as described in the [flutter_webrtc iOS screen-sharing guide](https://github.com/flutter-webrtc/flutter-webrtc/wiki/iOS-Screen-Sharing).

### macOS

The first time you capture, macOS asks the user to allow **Screen Recording** under System Settings → Privacy & Security. The app has to be **restarted** after permission is granted; this is a macOS rule. Until then, `getSources()` returns an empty list.

If your app is sandboxed and will also send the stream over the network, add `com.apple.security.network.client` to its entitlements.

### Windows

No setup is needed. Pass `audio: true` to capture system audio through WASAPI loopback.

### Linux

For system audio, install the PulseAudio development package before building (`sudo apt install libpulse-dev`). Without it, video still works.

### Web

The page must be served over HTTPS (or from `localhost`). Tab and system audio are supported in Chromium-based browsers; Safari and Firefox capture video only.

## Migrating from 0.0.x

`startScreenShare()` now starts the capture itself and returns the `MediaStream`. Remove your own `navigator.mediaDevices.getDisplayMedia(...)` call:

```dart
// 0.0.x
await ScreenSharePlugin.startScreenShare();
final stream = await navigator.mediaDevices.getDisplayMedia({...});

// 1.0.0
final stream = await ScreenSharePlugin.startScreenShare();
```

You can also remove the permissions and service you added to `AndroidManifest.xml` by hand; the plugin now declares them itself.

## License

MIT

## Support

If you like this plugin, [support me on Buy Me A Coffee](https://www.buymeacoffee.com/yogxworld).

If this plugin helped you, please consider **subscribing to my YouTube channel**
🎥 [Yogx World](https://www.youtube.com/@yogxworld15)
