// This is a basic Flutter widget test.
//
// To perform an interaction test, use the Flutter testing API:
// https://docs.flutter.dev/testing/overview#widget-tests

import 'package:flutter_test/flutter_test.dart';
import 'package:libass_app/main.dart';

void main() {
  testWidgets('App launches and shows LIBASS branding', (WidgetTester tester) async {
    await tester.pumpWidget(const LibassApp());
    // The splash screen should show the LIBASS branding
    expect(find.text('AI Personal Stylist'), findsOneWidget);
    
    // Wait for the async session check to finish (network will fail or timeout in test, falling back to AuthScreen)
    await tester.pump(const Duration(seconds: 1)); // allow future to complete
    await tester.pumpAndSettle(); // settle animations
    
    // Let's check if the AuthScreen is now shown
    expect(find.text('Sign In'), findsOneWidget);
  });
}
