import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xmasfriend/main.dart';

void main() {
  testWidgets('App renders splash and loads participants screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    // Initially displays Splash screen
    expect(find.text('Holiday Office Exchange'), findsOneWidget);

    // Advance past splash delay (1200ms) + route transition (300ms)
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 500));

    // Navigated to ParticipantsScreen
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Start the draw'), findsOneWidget);
    expect(find.text('Import from Excel or CSV'), findsOneWidget);
  });
}
