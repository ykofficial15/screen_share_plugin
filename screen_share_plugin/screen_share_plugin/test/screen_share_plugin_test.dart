import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_share_plugin/screen_share_plugin.dart';
import 'package:screen_share_plugin/screen_share_plugin_method_channel.dart';
import 'package:screen_share_plugin/screen_share_plugin_platform_interface.dart';

class _RecordingPlatform extends ScreenSharePluginPlatform
    with MockPlatformInterfaceMixin {
  final events = <String>[];
  @override
  Future<void> beforeCapture(ScreenShareOptions options) async =>
      events.add('before');
  @override
  Future<void> afterCapture() async => events.add('after');
}

void main() {
  test('Android method-channel implementation is the default', () {
    expect(ScreenSharePluginPlatform.instance,
        isA<MethodChannelScreenSharePlugin>());
  });

  test('desktop/iOS registration installs the no-op platform', () {
    ScreenSharePluginDesktopAndIos.registerWith();
    expect(ScreenSharePluginPlatform.instance, isA<NoOpScreenSharePlatform>());
  });

  test('stopScreenShare is a no-op when nothing is shared', () async {
    final platform = _RecordingPlatform();
    ScreenSharePluginPlatform.instance = platform;

    await ScreenSharePlugin.stopScreenShare();

    expect(ScreenSharePlugin.isSharing, isFalse);
    expect(ScreenSharePlugin.sharing.value, isFalse);
    expect(platform.events, isEmpty);
  });

  test('ScreenShareException toString includes code and message', () {
    expect(ScreenShareException('NO_SOURCE', 'none').toString(),
        'ScreenShareException(NO_SOURCE): none');
  });
}
