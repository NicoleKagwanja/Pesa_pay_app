// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pesa_pay/main.dart';
import 'package:pesa_pay/screen/auth/login_screen.dart'; // Import the screen

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Ensure initialization for plugins like SharedPreferences
    TestWidgetsFlutterBinding.ensureInitialized();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(home: const LoginScreen()), // ✅ Provide required 'home' parameter
    );

    // Verify that our counter starts at 0.
    // Note: This test seems to be from a counter app template.
    // If your app doesn't have a counter, this part may not apply.
    expect(find.text('0'), findsNothing); // Adjust based on actual UI
    expect(
      find.text('Login'),
      findsOneWidget,
    ); // Example: Check if Login screen appears

    // If you had a button to tap, you could test navigation
    // await tester.tap(find.byType(ElevatedButton));
    // await tester.pump();
  });
}
