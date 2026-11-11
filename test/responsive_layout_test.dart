import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xmasfriend/core/Features/draw/whos_drawing_screen.dart';
import 'package:xmasfriend/core/Features/draw/private_reveal_screen.dart';
import 'package:xmasfriend/core/Features/hr/hr_pairings_screen.dart';
import 'package:xmasfriend/core/Features/participants/participants_screen.dart';
import 'package:xmasfriend/core/employee_pair.dart';
import 'package:xmasfriend/core/services/storage_service.dart';
import 'package:xmasfriend/core/theme/app_theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.saveParticipants(['Alice', 'Bob', 'Charlie']);
    await StorageService.savePairings([
      EmployeePair(picker: 'Alice', picked: 'Bob', hasDrawn: false),
      EmployeePair(picker: 'Bob', picked: 'Charlie', hasDrawn: true, giftIdea: 'Mug'),
      EmployeePair(picker: 'Charlie', picked: 'Alice', hasDrawn: false),
    ]);
  });

  const smallPhoneSize = Size(375, 667); // iPhone SE
  const largePhoneSize = Size(430, 932); // iPhone 16 Pro Max

  for (final size in [smallPhoneSize, largePhoneSize]) {
    final label = size == smallPhoneSize ? 'Small Phone (375x667)' : 'Large Phone (430x932)';

    testWidgets('ParticipantsScreen renders without overflow on $label in light and dark mode', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const ParticipantsScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        final err = tester.takeException();
        expect(err, isNull);
        expect(find.text('Secret Santa'), findsOneWidget);
        expect(find.text('Start the draw'), findsOneWidget);
      }
    });

    testWidgets('WhosDrawingScreen renders without overflow on $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WhosDrawingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final err = tester.takeException();
      expect(err, isNull);
      expect(find.text("Who's drawing?"), findsOneWidget);
      expect(find.text('HR view'), findsOneWidget);
    });

    testWidgets('PrivateRevealScreen renders and holds without overflow on $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PrivateRevealScreen(pickerName: 'Alice'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final err1 = tester.takeException();
      expect(err1, isNull);
      expect(find.text('Hi, Alice'), findsOneWidget);
      expect(find.text('Hold to reveal'), findsOneWidget);

      // Press and hold
      final holdFinder = find.text('Hold to reveal');
      final gesture = await tester.startGesture(tester.getCenter(holdFinder));
      await tester.pump();

      final err2 = tester.takeException();
      expect(err2, isNull);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('YOUR RECIPIENT'), findsOneWidget);

      // Release
      await gesture.up();
      await tester.pump();

      expect(find.text('Bob'), findsNothing);
      expect(find.text('Hold to reveal'), findsOneWidget);
    });

    testWidgets('HrPairingsScreen renders without overflow on $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HrPairingsScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final err = tester.takeException();
      expect(err, isNull);
      expect(find.text('Pairings'), findsOneWidget);
      expect(find.text('Reset draw'), findsOneWidget);
    });
  }
}
