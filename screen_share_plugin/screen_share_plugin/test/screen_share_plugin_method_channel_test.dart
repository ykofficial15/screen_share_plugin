import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share_plugin/screen_share_plugin.dart';
import 'package:screen_share_plugin/screen_share_plugin_method_channel.dart';

class _FakeConsent extends MethodChannelScreenSharePlugin {
  _FakeConsent(this.granted);
  final bool granted;
  @override
  Future<bool> requestCapturePermission(bool fullScreenOnly) async => granted;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel =
      MethodChannel('com.example.screen_share_plugin/screen_capture');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'requestNotificationPermission' ? true : null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('consent granted: asks notifications, then starts the service',
      () async {
    await _FakeConsent(true).beforeCapture(const ScreenShareOptions(
        androidNotificationTitle: 'T', androidNotificationText: 'X'));

    expect(calls.map((c) => c.method),
        ['requestNotificationPermission', 'startForegroundService']);
    expect(calls.last.arguments, {'title': 'T', 'text': 'X'});
  });

  test('consent denied: throws and never starts the service', () async {
    await expectLater(
      _FakeConsent(false).beforeCapture(const ScreenShareOptions()),
      throwsA(isA<ScreenShareException>()
          .having((e) => e.code, 'code', 'PERMISSION_DENIED')),
    );
    expect(calls.map((c) => c.method), ['requestNotificationPermission']);
  });

  test('afterCapture stops the service', () async {
    await _FakeConsent(true).afterCapture();
    expect(calls.single.method, 'stopForegroundService');
  });
}
