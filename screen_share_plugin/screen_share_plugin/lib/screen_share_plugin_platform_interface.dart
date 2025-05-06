import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'screen_share_plugin_method_channel.dart';

abstract class ScreenSharePluginPlatform extends PlatformInterface {
  /// Constructs a ScreenSharePluginPlatform.
  ScreenSharePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScreenSharePluginPlatform _instance = MethodChannelScreenSharePlugin();

  /// The default instance of [ScreenSharePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelScreenSharePlugin].
  static ScreenSharePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScreenSharePluginPlatform] when
  /// they register themselves.
  static set instance(ScreenSharePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
