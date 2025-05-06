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
