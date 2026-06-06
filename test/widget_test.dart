// Smoke test: the app boots and shows the Firebase-setup screen when Firebase
// is not configured in the test environment.

import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_management/main.dart';

void main() {
  testWidgets('App renders setup screen when Firebase is not configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HostelApp(firebaseError: 'not-configured'));
    expect(find.text('Firebase not connected yet'), findsOneWidget);
  });
}
