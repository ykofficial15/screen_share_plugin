import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:screen_share_plugin/screen_share_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plugin reports support and starts idle', (tester) async {
    expect(ScreenSharePlugin.isSupported, isTrue);
    expect(ScreenSharePlugin.isSharing, isFalse);
    // stopScreenShare must be safe to call when nothing is running.
    await ScreenSharePlugin.stopScreenShare();
    expect(ScreenSharePlugin.sharing.value, isFalse);
  });
}
