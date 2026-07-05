// Basic smoke test for the SpotSaku app.
//
// Verifies that the app boots and the home screen renders its title.

import 'package:flutter_test/flutter_test.dart';

import 'package:spotsaku/main.dart';

void main() {
  testWidgets('App boots and shows home title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpotSakuApp());

    // The home AppBar should display the app name.
    expect(find.text('SpotSaku'), findsOneWidget);
  });
}
