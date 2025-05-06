import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screen_share_plugin_platform_interface.dart';

/// An implementation of [ScreenSharePluginPlatform] that uses method channels.
class MethodChannelScreenSharePlugin extends ScreenSharePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('screen_share_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
