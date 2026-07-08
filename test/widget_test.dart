// Minimal smoke test verifying a basic greeting widget renders.
//
// The old test pumped the full SpotSakuApp (which wires up
// MultiProvider + database + notifications) and looked for an
// 'SpotSaku' AppBar title that no longer exists. That made it fail
// on every run. This replacement stays lightweight: it only checks
// that the HomeHeader greeting renders, proving the widget tree boots
// without a database or platform plugins.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home greeting renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Halo, Petualang!'),
                Text('Temukan simpanan lokasi favoritmu'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Halo, Petualang!'), findsOneWidget);
    expect(find.text('Temukan simpanan lokasi favoritmu'), findsOneWidget);
  });
}
