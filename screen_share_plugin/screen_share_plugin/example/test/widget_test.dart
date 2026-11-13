import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_share_plugin_example/main.dart';

void main() {
  testWidgets('shows idle status and a start button', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Start screen sharing'), findsOneWidget);
    expect(find.byIcon(Icons.screen_share), findsOneWidget);
  });
}
