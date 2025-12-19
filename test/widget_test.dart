import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conduit/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ConduitApp(),
      ),
    );

    // Verify the login screen is shown
    expect(find.text('Welcome to Conduit'), findsOneWidget);
  });
}
