import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xmasfriend/core/data/draw_repository.dart';
import 'package:xmasfriend/main.dart';

void main() {
  testWidgets('App renders splash and loads participants screen', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    DrawRepository.instance.resetCache();

    await tester.pumpWidget(const MyApp());

    // Initially displays Splash screen
    expect(find.text('Holiday Office Exchange'), findsOneWidget);

    // Advance past splash intro (2200ms) + pause (700ms) + route transition (500ms)
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // Navigated to ParticipantsScreen
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Start the draw'), findsOneWidget);
    expect(find.text('Import from Excel or CSV'), findsOneWidget);
  });
}
