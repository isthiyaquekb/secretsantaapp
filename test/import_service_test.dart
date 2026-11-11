import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:xmasfriend/core/services/participant_import_service.dart';

void main() {
  group('ParticipantImportService Tests', () {
    test('Correctly parses CSV with header and skips duplicates', () {
      final csvContent = '''Name
Alice
Bob
Charlie
Alice
David
''';
      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final result = ParticipantImportService.parseFileBytes(
        bytes: bytes,
        fileName: 'team.csv',
        existingParticipants: ['David'],
      );

      // 'Name' header skipped.
      // Alice, Bob, Charlie added (3).
      // Second 'Alice' duplicate skipped (1).
      // 'David' already existed in existingParticipants, skipped (1).
      // Total added: 3, skipped: 2.
      expect(result.addedCount, equals(3));
      expect(result.skippedDuplicatesCount, equals(2));
      expect(result.addedNames, equals(['Alice', 'Bob', 'Charlie']));
      expect(result.summaryMessage, equals('Added 3, skipped 2 duplicates'));
    });

    test('Throws on unsupported file extensions', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(
        () => ParticipantImportService.parseFileBytes(
          bytes: bytes,
          fileName: 'test.pdf',
          existingParticipants: [],
        ),
        throwsFormatException,
      );
    });
  });
}

