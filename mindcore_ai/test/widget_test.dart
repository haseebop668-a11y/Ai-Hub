import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard renders with explicit prototype status', (tester) async {
    await tester.pumpWidget(const MindCoreApp());

    expect(find.text('MINDCORE'), findsOneWidget);
    expect(find.text('SYSTEM OVERVIEW'), findsOneWidget);
    expect(find.text('NOT LOADED'), findsOneWidget);
    expect(find.text('Prototype build: UI is active; local inference and Android automation are not yet connected.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation opens every main section', (tester) async {
    await tester.pumpWidget(const MindCoreApp());

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('LOCAL CHAT / SESSION 01'), findsOneWidget);

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    expect(find.text('APP CONTROL'), findsOneWidget);

    await tester.tap(find.text('Models'));
    await tester.pumpAndSettle();
    expect(find.text('MODEL BAY'), findsOneWidget);

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('PRIVACY & TRUST'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('chat input appends a message and clears the field', (tester) async {
    await tester.pumpWidget(const MindCoreApp());

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    await tester.enterText(input, 'Test message');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(find.text('YOU  /  Test message'), findsOneWidget);
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add an app clearly reports that picker integration is not connected', (tester) async {
    await tester.pumpWidget(const MindCoreApp());

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add an app'));
    await tester.pumpAndSettle();

    expect(find.text('App selection will be connected in the Android integration phase.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline preference toggle changes its displayed value', (tester) async {
    await tester.pumpWidget(const MindCoreApp());

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    final toggle = find.byType(SwitchListTile);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final logicalSize in <Size>[
    const Size(320, 640),
    const Size(360, 800),
    const Size(412, 915),
  ]) {
    testWidgets('dashboard renders without exceptions at $logicalSize', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = logicalSize;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MindCoreApp());
      await tester.pumpAndSettle();
      expect(find.text('MINDCORE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
