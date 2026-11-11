import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:excel/excel.dart' as excel_pkg;

class ImportResult {
  final List<String> addedNames;
  final int addedCount;
  final int skippedDuplicatesCount;

  ImportResult({
    required this.addedNames,
    required this.addedCount,
    required this.skippedDuplicatesCount,
  });

  String get summaryMessage =>
      'Added $addedCount, skipped $skippedDuplicatesCount duplicates';
}

class ParticipantImportService {
  ParticipantImportService._();

  static const _headerKeywords = {
    'name',
    'names',
    'participant',
    'participants',
    'employee',
    'employees',
    'member',
    'members',
    'full name',
    'fullname',
    'person',
  };

  /// Parses bytes from a .csv, .xlsx, or .xls file.
  /// Reads the first column of the first sheet/table.
  /// Skips header row if detected, and ignores case-insensitive duplicates.
  static ImportResult parseFileBytes({
    required Uint8List bytes,
    required String fileName,
    required List<String> existingParticipants,
  }) {
    final extension = fileName.split('.').last.toLowerCase();
    final rawEntries = <String>[];

    if (extension == 'csv') {
      final content = utf8.decode(bytes, allowMalformed: true);
      // Handles standard comma, newline, or CRLF separated CSV
      final rows = csv_pkg.csv.decode(content);
      for (final row in rows) {
        if (row.isNotEmpty) {
          rawEntries.add(row[0].toString());
        }
      }
    } else if (extension == 'xlsx' || extension == 'xls') {
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      if (excel.tables.isNotEmpty) {
        final firstSheetName = excel.tables.keys.first;
        final sheet = excel.tables[firstSheetName];
        if (sheet != null) {
          for (final row in sheet.rows) {
            if (row.isNotEmpty && row[0] != null) {
              final val = row[0]!.value;
              if (val != null) {
                rawEntries.add(val.toString());
              }
            }
          }
        }
      }
    } else {
      throw FormatException('Unsupported file format .$extension. Please use .xlsx, .xls, or .csv');
    }

    // Process raw entries
    final existingLower = existingParticipants.map((p) => p.trim().toLowerCase()).toSet();
    final newlyAdded = <String>[];
    int skippedDuplicates = 0;

    for (int i = 0; i < rawEntries.length; i++) {
      final trimmed = rawEntries[i].trim();
      if (trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();

      // Check if first row is a header like "Name"
      if (i == 0 && _headerKeywords.contains(lower)) {
        continue;
      }

      if (existingLower.contains(lower)) {
        skippedDuplicates++;
      } else {
        existingLower.add(lower);
        newlyAdded.add(trimmed);
      }
    }

    return ImportResult(
      addedNames: newlyAdded,
      addedCount: newlyAdded.length,
      skippedDuplicatesCount: skippedDuplicates,
    );
  }
}
