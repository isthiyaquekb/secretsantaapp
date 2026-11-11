import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:xmasfriend/core/services/draw_service.dart';

void main() {
  group('Secret Santa Sattolo Draw Logic Tests', () {
    test('Throws ArgumentError if fewer than 3 participants', () {
      expect(
        () => SecretSantaDrawService.generatePairings(['Alice', 'Bob']),
        throwsArgumentError,
      );
      expect(
        () => SecretSantaDrawService.generatePairings([]),
        throwsArgumentError,
      );
    });

    for (int size = 3; size <= 50; size++) {
      test('List size $size guarantees valid single cycle, no self-pairing, and exact picks', () {
        final rng = Random(42 + size);
        final participants = List.generate(size, (i) => 'Employee_${i + 1}');

        // Test multiple runs per size to ensure randomness and consistency
        for (int run = 0; run < 10; run++) {
          final pairings = SecretSantaDrawService.generatePairings(
            participants,
            rng,
          );

          // 1. Total pairings equals participant count
          expect(pairings.length, equals(size));

          final pickers = <String>{};
          final pickedList = <String>{};
          final pairMap = <String, String>{};

          for (final pair in pairings) {
            // 2. No self-pairing (nobody may draw themselves)
            expect(
              pair.picker,
              isNot(equals(pair.picked)),
              reason: 'Self-pairing detected: ${pair.picker} picked themselves in size $size',
            );

            pickers.add(pair.picker);
            pickedList.add(pair.picked);
            pairMap[pair.picker] = pair.picked;
          }

          // 3. Everyone picks exactly once
          expect(pickers.length, equals(size));
          expect(pickers, containsAll(participants));

          // 4. Everyone is picked exactly once
          expect(pickedList.length, equals(size));
          expect(pickedList, containsAll(participants));

          // 5. Single cycle verification:
          // Starting at participants[0], following the chain must visit all N unique participants before returning.
          final visitedInCycle = <String>{};
          String current = participants[0];

          for (int step = 0; step < size; step++) {
            visitedInCycle.add(current);
            final next = pairMap[current];
            expect(next, isNotNull);
            current = next!;
          }

          expect(
            visitedInCycle.length,
            equals(size),
            reason: 'Draw did not form a single cycle covering all $size participants',
          );
          expect(
            current,
            equals(participants[0]),
            reason: 'Single cycle did not close back at the start for size $size',
          );
        }
      });
    }
  });
}
