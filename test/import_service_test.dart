import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter_test/flutter_test.dart';
import 'package:xmasfriend/core/services/participant_import_service.dart';
import 'package:xmasfriend/core/utils/xlsx_sanitizer.dart';

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

    test('Successfully imports .xlsx with custom numFmtId < 164 after sanitizing', () {
      final file = File('test/fixtures/custom_numfmt_6.xlsx');
      expect(file.existsSync(), isTrue, reason: 'Fixture file should exist');
      final fixtureBytes = file.readAsBytesSync();

      // Confirm that the raw un-sanitized fixture triggers the exact excel package bug
      expect(
        () => excel_pkg.Excel.decodeBytes(fixtureBytes),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('custom numFmtId starts at 164 but found a value of 6'),
          ),
        ),
      );

      // Confirm sanitizeXlsx strips the bad numFmt element and allows Excel.decodeBytes to succeed
      final sanitizedBytes = sanitizeXlsx(fixtureBytes);
      final excel = excel_pkg.Excel.decodeBytes(sanitizedBytes);
      expect(excel.tables.isNotEmpty, isTrue);

      // Confirm ParticipantImportService handles it end-to-end (retries with sanitizeXlsx)
      final result = ParticipantImportService.parseFileBytes(
        bytes: fixtureBytes,
        fileName: 'custom_numfmt_6.xlsx',
        existingParticipants: [],
      );

      expect(result.addedNames, equals(['Alice', 'Bob', 'Charlie']));
      expect(result.addedCount, equals(3));
      expect(result.skippedDuplicatesCount, equals(0));
    });

    test('Throws friendly message when corrupted .xlsx file fails decoding', () {
      final corruptedBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(
        () => ParticipantImportService.parseFileBytes(
          bytes: corruptedBytes,
          fileName: 'corrupted.xlsx',
          existingParticipants: [],
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals("Couldn't read this file. Try re-saving it as .xlsx or CSV."),
          ),
        ),
      );
    });
  });
}


