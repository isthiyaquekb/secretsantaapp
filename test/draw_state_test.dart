import 'package:flutter_test/flutter_test.dart';
import 'package:secretsantaapp/core/data/draw_state.dart';

void main() {
  group('DrawState Unit Tests', () {
    test('toJson and fromJson round trip', () {
      final original = DrawState(
        year: 2026,
        participants: ['Alice', 'Bob', 'Charlie'],
        pairings: {
          'Alice': 'Bob',
          'Bob': 'Charlie',
          'Charlie': 'Alice',
        },
        revealed: {'Alice', 'Charlie'},
        exchangeDate: DateTime(2026, 12, 23, 16, 0),
      );

      final json = original.toJson();
      final restored = DrawState.fromJson(json);

      expect(restored.year, equals(original.year));
      expect(restored.participants, equals(original.participants));
      expect(restored.pairings, equals(original.pairings));
      expect(restored.revealed, equals(original.revealed));
      expect(restored.exchangeDate, equals(original.exchangeDate));
      expect(restored.isDrawn, isTrue);
      expect(restored.isComplete, isFalse);
    });

    test('Situation 1: No draw yet', () {
      const state = DrawState(
        year: 2026,
        participants: ['Alice', 'Bob', 'Charlie'],
      );

      expect(state.isDrawn, isFalse);
      expect(state.isComplete, isFalse);
    });

    test('Situation 2: Partial draw (in progress)', () {
      const state = DrawState(
        year: 2026,
        participants: ['Alice', 'Bob', 'Charlie'],
        pairings: {
          'Alice': 'Bob',
          'Bob': 'Charlie',
          'Charlie': 'Alice',
        },
        revealed: {'Alice'},
      );

      expect(state.isDrawn, isTrue);
      expect(state.isComplete, isFalse);
    });

    test('Situation 3: Complete draw (everyone has drawn)', () {
      const state = DrawState(
        year: 2026,
        participants: ['Alice', 'Bob', 'Charlie'],
        pairings: {
          'Alice': 'Bob',
          'Bob': 'Charlie',
          'Charlie': 'Alice',
        },
        revealed: {'Alice', 'Bob', 'Charlie'},
      );

      expect(state.isDrawn, isTrue);
      expect(state.isComplete, isTrue);
    });

    test('copyWith preserves and overrides fields appropriately', () {
      const initial = DrawState(year: 2026, participants: ['Alice']);
      final updated = initial.copyWith(
        participants: ['Alice', 'Bob'],
        pairings: {'Alice': 'Bob', 'Bob': 'Alice'},
      );

      expect(updated.year, equals(2026));
      expect(updated.participants, equals(['Alice', 'Bob']));
      expect(updated.pairings.length, equals(2));
      expect(updated.revealed, isEmpty);
      expect(updated.isDrawn, isTrue);
      expect(updated.isComplete, isFalse);
    });
  });
}
