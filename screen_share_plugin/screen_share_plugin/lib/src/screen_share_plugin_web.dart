import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../screen_share_plugin_platform_interface.dart';

/// Web registration. The browser's own `getDisplayMedia` picker handles
/// consent and source selection, so no extra hooks are needed.
class ScreenSharePluginWeb {
  static void registerWith(Registrar registrar) {
    ScreenSharePluginPlatform.instance = NoOpScreenSharePlatform();
  }
}
