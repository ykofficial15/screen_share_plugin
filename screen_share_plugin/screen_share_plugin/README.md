# screen_share_plugin

A Flutter plugin that enables **real-time screen sharing on Android** using native Kotlin code and displays the stream via [flutter_webrtc](https://pub.dev/packages/flutter_webrtc).

## Features

- ✅ Real-time screen sharing on Android.
- ✅ Screen preview powered by `flutter_webrtc`. (Thanks to the flutter_webrtc team).
- ✅ Native Android code written in **Kotlin**.
- ✅ Tested with **Flutter 3.29** and **compile SDK version up to 35** to reduce compatibility issues.

## Getting Started

### 1. Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  screen_share_plugin: ^0.0.2
```

### 2. Android Setup

Ensure you are using:

* **Flutter SDK:** `3.29.0`
* **compileSdkVersion:** `35` (in your `android/app/build.gradle`)
* **Allow Permissions from app info:** `Notifications, Camera, Microphone for screen sharing`

### 3. Permissions and Manifest Configuration (Optional)

Add the required permissions and service declaration to your `AndroidManifest.xml`.
If your configuration doesn't work out of the box, try adding these manually:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <!-- Permissions required for screen sharing -->
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

  <application
      android:label="screen_share_plugin_example"
      android:name="${applicationName}"
      android:icon="@mipmap/ic_launcher">

      <!-- Foreground service declaration for media projection -->
      <service
          android:name="com.example.screen_share_plugin.ScreenCaptureService"
          android:enabled="true"
          android:exported="false"
          android:foregroundServiceType="mediaProjection" />

      <activity
          android:name=".MainActivity"
          android:exported="true"
          android:launchMode="singleTop"
          android:theme="@style/LaunchTheme"
          android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
          android:hardwareAccelerated="true"
          android:windowSoftInputMode="adjustResize">

          <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />

          <intent-filter>
              <action android:name="android.intent.action.MAIN" />
              <category android:name="android.intent.category.LAUNCHER" />
          </intent-filter>
      </activity>

      <meta-data
          android:name="flutterEmbedding"
          android:value="2" />
  </application>
</manifest>
```
---

## Example Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:screen_share_plugin/screen_share_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ScreenShareDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScreenShareDemo extends StatefulWidget {
  const ScreenShareDemo({super.key});

  @override
  State<ScreenShareDemo> createState() => _ScreenShareDemoState();
}

class _ScreenShareDemoState extends State<ScreenShareDemo> {
  bool _isSharing = false;
  String _status = "Idle";
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  Future<void> _initializeRenderer() async {
    await _localRenderer.initialize();
  }

  Future<void> _startScreenSharing() async {
    try {
      setState(() {
        _status = "Requesting permission...";
      });

      // Start the screen share plugin
      await ScreenSharePlugin.startScreenShare();

      // After starting the service, grab the display media
      final mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': 640,
            'minHeight': 480,
            'minFrameRate': 30,
          },
          'facingMode': 'user',
          'optional': [],
        }
      };

      _localStream =
          await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;

      setState(() {
        _isSharing = true;
        _status = "Screen sharing active";
      });
    } catch (e) {
      setState(() {
        _status = "Error: ${e.toString()}";
      });
    }
  }

  Future<void> _stopScreenSharing() async {
    try {
      await ScreenSharePlugin.stopScreenShare();

      setState(() {
        _isSharing = false;
        _status = "Screen sharing stopped";
      });

      _localStream?.dispose();
      _localRenderer.srcObject = null;
    } catch (e) {
      setState(() {
        _status = "Error: ${e.toString()}";
      });
    }
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Screen Sharing Plugin Example"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              _isSharing
                  ? SizedBox(
                      width: 640,
                      height: 480,
                      child: RTCVideoView(_localRenderer),
                    )
                  : const Center(child: Text("No Screen Sharing")),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(_isSharing ? Icons.stop : Icons.screen_share),
                label:
                    Text(_isSharing ? "Stop Sharing" : "Start Screen Sharing"),
                onPressed:
                    _isSharing ? _stopScreenSharing : _startScreenSharing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## License

MIT License

---

## Support

If you like this plugin, [support me on Buy Me A Coffee](https://www.buymeacoffee.com/yogxworld).

If this plugin helped you, please consider **subscribing to my YouTube channel**
🎥 [Yogx World](https://www.youtube.com/@yogxworld15)

---
