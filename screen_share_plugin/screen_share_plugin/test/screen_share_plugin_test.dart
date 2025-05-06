import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share_plugin/screen_share_plugin.dart';
import 'package:screen_share_plugin/screen_share_plugin_platform_interface.dart';
import 'package:screen_share_plugin/screen_share_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockScreenSharePluginPlatform
    with MockPlatformInterfaceMixin
    implements ScreenSharePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ScreenSharePluginPlatform initialPlatform = ScreenSharePluginPlatform.instance;

  test('$MethodChannelScreenSharePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScreenSharePlugin>());
  });

  test('getPlatformVersion', () async {
    ScreenSharePlugin screenSharePlugin = ScreenSharePlugin();
    MockScreenSharePluginPlatform fakePlatform = MockScreenSharePluginPlatform();
    ScreenSharePluginPlatform.instance = fakePlatform;

    expect(await screenSharePlugin.getPlatformVersion(), '42');
  });
}
