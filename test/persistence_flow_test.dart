import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secretsantaapp/core/data/draw_repository.dart';
import 'package:secretsantaapp/core/data/draw_state.dart';
import 'package:secretsantaapp/core/services/draw_service.dart';
import 'package:secretsantaapp/core/utils/exchange_date.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    DrawRepository.instance.resetCache();
  });

  group('End-to-End Persistence & Lifecycle Scenarios', () {
    test(
        'Scenario 1: Add names, simulate app kill and relaunch -> names persist',
        () async {
      final repo = DrawRepository.instance;
      var state = await repo.load();
      expect(state.participants, isEmpty);

      // Add names
      state = state
          .copyWith(participants: ['Issac', 'Jayesh', 'Sachin', 'Steffy']);
      await repo.save(state);

      // Simulate kill and relaunch (clear memory cache)
      repo.resetCache();
      final relaunchedState = await repo.load();

      expect(relaunchedState.participants,
          equals(['Issac', 'Jayesh', 'Sachin', 'Steffy']));
      expect(relaunchedState.isDrawn, isFalse);
    });

    test(
        'Scenario 2: Start draw, 3 people pick, kill & relaunch -> lands on WhosDrawing with 3 checked',
        () async {
      final repo = DrawRepository.instance;
      final participants = ['Issac', 'Jayesh', 'Sachin', 'Steffy', 'Amal'];
      final pairsList = SecretSantaDrawService.generatePairings(participants);
      final pairsMap = {for (final p in pairsList) p.picker: p.picked};

      // Save initial draw
      var state = DrawState(
        year: 2026,
        participants: participants,
        pairings: pairsMap,
        revealed: {},
      );
      await repo.save(state);

      // 3 people pick
      await repo.markRevealed('Issac');
      await repo.markRevealed('Jayesh');
      await repo.markRevealed('Sachin');

      // Simulate app kill & relaunch
      repo.resetCache();
      final relaunched = await repo.load();

      expect(relaunched.isDrawn, isTrue);
      expect(relaunched.isComplete, isFalse);
      expect(relaunched.revealed, containsAll(['Issac', 'Jayesh', 'Sachin']));
      expect(relaunched.revealed.length, equals(3));
      expect(relaunched.revealed.contains('Steffy'), isFalse);
      expect(relaunched.revealed.contains('Amal'), isFalse);
    });

    test(
        'Scenario 3: Finish all picks, kill & relaunch -> lands on complete (isComplete=true, never isDrawn=false)',
        () async {
      final repo = DrawRepository.instance;
      final participants = ['Issac', 'Jayesh', 'Sachin'];
      final pairsList = SecretSantaDrawService.generatePairings(participants);
      final pairsMap = {for (final p in pairsList) p.picker: p.picked};

      var state = DrawState(
        year: 2026,
        participants: participants,
        pairings: pairsMap,
        revealed: {'Issac', 'Jayesh', 'Sachin'},
      );
      await repo.save(state);

      // Simulate kill & relaunch
      repo.resetCache();
      final relaunched = await repo.load();

      expect(relaunched.isDrawn, isTrue);
      expect(relaunched.isComplete, isTrue);
    });

    test(
        'Scenario 4: HR picks date, relaunch -> exchangeDate persists and formatShortDate matches',
        () async {
      final repo = DrawRepository.instance;
      var state = await repo.load();
      final selectedDate = DateTime(2026, 12, 24);

      await repo.save(state.copyWith(exchangeDate: selectedDate));

      // Simulate kill & relaunch
      repo.resetCache();
      final relaunched = await repo.load();

      expect(relaunched.exchangeDate, equals(selectedDate));
      expect(formatShortDate(relaunched.exchangeDate!), equals('Dec 24'));
    });

    test(
        'Scenario 5: HR resetDraw -> clears pairings and progress, but keeps participants',
        () async {
      final repo = DrawRepository.instance;
      final participants = ['Issac', 'Jayesh', 'Sachin'];
      final pairsList = SecretSantaDrawService.generatePairings(participants);
      final pairsMap = {for (final p in pairsList) p.picker: p.picked};

      var state = DrawState(
        year: 2026,
        participants: participants,
        pairings: pairsMap,
        revealed: {'Issac', 'Jayesh'},
      );
      await repo.save(state);

      // HR confirms reset
      await repo.resetDraw();

      // Simulate kill & relaunch
      repo.resetCache();
      final resetState = await repo.load();

      expect(resetState.participants, equals(['Issac', 'Jayesh', 'Sachin']));
      expect(resetState.pairings, isEmpty);
      expect(resetState.revealed, isEmpty);
      expect(resetState.isDrawn, isFalse);
      expect(resetState.isComplete, isFalse);
    });

    test(
        'HR Master PIN Security: salted hash storage, verification, and change PIN',
        () async {
      final repo = DrawRepository.instance;

      expect(await repo.hasHrPin(), isFalse);

      // Set PIN
      await repo.setHrPin('5678');
      expect(await repo.hasHrPin(), isTrue);

      // Verify
      expect(await repo.verifyHrPin('5678'), isTrue);
      expect(await repo.verifyHrPin('1234'), isFalse);
      expect(await repo.verifyHrPin('0000'), isFalse);

      // Change PIN
      await repo.setHrPin('9999');
      expect(await repo.verifyHrPin('5678'), isFalse);
      expect(await repo.verifyHrPin('9999'), isTrue);

      // Forgot PIN resets PIN and draw
      await repo.resetDrawAndPin();
      expect(await repo.hasHrPin(), isFalse);
    });
  });
}

