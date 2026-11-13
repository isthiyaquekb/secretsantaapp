import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter_test/flutter_test.dart';
import 'package:secretsantaapp/core/services/participant_import_service.dart';
import 'package:secretsantaapp/core/utils/xlsx_sanitizer.dart';

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
      expect(result.addedCount, equals(3));
      expect(result.skippedDuplicatesCount, equals(2));
      expect(result.addedNames, equals(['Alice', 'Bob', 'Charlie']));
      expect(result.summaryMessage, equals('Added 3, skipped 2'));
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

      // Confirm that raw un-sanitized fixture triggers the excel package bug
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
            equals("Couldn't read this file. Check the format or use the template."),
          ),
        ),
      );
    });

    // Requirement 8 tests:
    // (a) Sample HR file layout: Index, User Id, First Name, Last Name, Sex, Email, Phone, Date of birth, Job Title
    test('(a) HR file layout detects First Name + Last Name and extracts Shelby Terrell', () {
      const csv =
          'Index,User Id,First Name,Last Name,Sex,Email,Phone,Date of birth,Job Title\n'
          '1,e8f23,Shelby,Terrell,Female,shelby@example.com,555-0192,1990-05-12,Software Engineer\n'
          '2,a19c4,Marcus,Vance,Male,marcus@example.com,555-0193,1988-11-20,Product Manager\n';
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final table = ParticipantImportService.parseTable(bytes: bytes, fileName: 'employees.csv');
      final selection = ParticipantImportService.detectNameColumn(table);

      expect(selection, isNotNull);
      expect(selection!.type, equals(ColumnSelectionType.combinedFirstLast));
      expect(selection.label, equals('First Name + Last Name'));

      final names = ParticipantImportService.extractRawNames(table, selection);
      expect(names, equals(['Shelby Terrell', 'Marcus Vance']));
    });

    // (b) Single "Name" column
    test('(b) Single Name column detected correctly', () {
      const csv =
          'Name,Department\n'
          'Santa Claus,North Pole\n'
          'Buddy Elf,Workshop\n';
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final table = ParticipantImportService.parseTable(bytes: bytes, fileName: 'names.csv');
      final selection = ParticipantImportService.detectNameColumn(table);

      expect(selection, isNotNull);
      expect(selection!.type, equals(ColumnSelectionType.single));
      expect(selection.columnIndex, equals(0));
      expect(selection.label, equals('Name'));

      final names = ParticipantImportService.extractRawNames(table, selection);
      expect(names, equals(['Santa Claus', 'Buddy Elf']));
    });

    // (c) No header names where column 1 is numbers and column 2 is names
    test('(c) File without header names detects column 2 with names', () {
      const csv =
          '1001,Alice Johnson\n'
          '1002,Bob Smith\n'
          '1003,Charlie Brown\n';
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final table = ParticipantImportService.parseTable(bytes: bytes, fileName: 'data.csv');
      final selection = ParticipantImportService.detectNameColumn(table);

      expect(selection, isNotNull);
      expect(selection!.type, equals(ColumnSelectionType.single));
      expect(selection.columnIndex, equals(1));

      final names = ParticipantImportService.extractRawNames(table, selection);
      expect(names, equals(['Bob Smith', 'Charlie Brown']));
    });

    // (d) All-numeric file, expecting column picker (returns null)
    test('(d) All-numeric file returns null for detection to open column picker', () {
      const csv =
          '101,5000\n'
          '102,6200\n'
          '103,4800\n';
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final table = ParticipantImportService.parseTable(bytes: bytes, fileName: 'numbers.csv');
      final selection = ParticipantImportService.detectNameColumn(table);

      expect(selection, isNull);
    });

    // (e) Semicolon CSV with BOM
    test('(e) Semicolon delimited CSV with UTF-8 BOM parses correctly', () {
      const csvWithBom = '\uFEFFName;Job Title\nAlice;Engineer\nBob;Designer\n';
      final bytes = Uint8List.fromList(utf8.encode(csvWithBom));
      final table = ParticipantImportService.parseTable(bytes: bytes, fileName: 'bom.csv');
      final selection = ParticipantImportService.detectNameColumn(table);

      expect(selection, isNotNull);
      expect(selection!.label, equals('Name'));

      final names = ParticipantImportService.extractRawNames(table, selection);
      expect(names, equals(['Alice', 'Bob']));
    });

    // (f) Duplicate names handling: renumbering vs skipping
    test('(f) Duplicate names: renumbering vs skipping', () {
      final names = ['John Smith', 'Jane Doe', 'John Smith', 'Bob'];
      final existing = ['John Smith'];

      final dupCount = ParticipantImportService.countDuplicates(names, existing);
      expect(dupCount, equals(2)); // John Smith (against existing) and John Smith (within file)

      // Test renumbering
      final renumberedResult = ParticipantImportService.finalizeImport(
        extractedNames: names,
        existingParticipants: existing,
        renumberDuplicates: true,
      );
      expect(
        renumberedResult.addedNames,
        equals(['John Smith 2', 'Jane Doe', 'John Smith 3', 'Bob']),
      );

      // Test skipping
      final skippedResult = ParticipantImportService.finalizeImport(
        extractedNames: names,
        existingParticipants: existing,
        renumberDuplicates: false,
      );
      expect(skippedResult.addedNames, equals(['Jane Doe', 'Bob']));
      expect(skippedResult.skippedDuplicatesCount, equals(2));
    });

    test('Caps at 500 max participants and indicates limit reached', () {
      final longList = List.generate(520, (i) => 'Person $i');
      final result = ParticipantImportService.finalizeImport(
        extractedNames: longList,
        existingParticipants: [],
        renumberDuplicates: false,
      );
      expect(result.addedCount, equals(500));
      expect(result.reachedLimit, isTrue);
      expect(result.summaryMessage, contains('limit of 500 reached'));
    });
  });
}
