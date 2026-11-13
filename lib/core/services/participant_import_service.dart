import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:excel/excel.dart' as excel_pkg;
import 'package:secretsantaapp/core/utils/xlsx_sanitizer.dart';

/// Represents a parsed spreadsheet or CSV table with a header row and data rows.
class ParsedTable {
  final List<String> headers;
  final List<List<String>> rows;

  const ParsedTable({
    required this.headers,
    required this.rows,
  });

  int get columnCount => headers.length;
  int get rowCount => rows.length;

  /// Returns the first non-empty sample value for the specified column index.
  String getSampleValue(int colIndex) {
    for (final row in rows) {
      if (colIndex < row.length) {
        final val = row[colIndex].trim();
        if (val.isNotEmpty) return val;
      }
    }
    return '';
  }
}

enum ColumnSelectionType {
  single,
  combinedFirstLast,
}

class ColumnSelection {
  final ColumnSelectionType type;
  final int columnIndex; // for single
  final int firstNameColumnIndex; // for combined
  final int lastNameColumnIndex; // for combined
  final String label;

  const ColumnSelection.single({
    required this.columnIndex,
    required this.label,
  })  : type = ColumnSelectionType.single,
        firstNameColumnIndex = -1,
        lastNameColumnIndex = -1;

  const ColumnSelection.combined({
    required this.firstNameColumnIndex,
    required this.lastNameColumnIndex,
    required this.label,
  })  : type = ColumnSelectionType.combinedFirstLast,
        columnIndex = -1;

  @override
  String toString() => 'ColumnSelection($label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnSelection &&
          type == other.type &&
          columnIndex == other.columnIndex &&
          firstNameColumnIndex == other.firstNameColumnIndex &&
          lastNameColumnIndex == other.lastNameColumnIndex &&
          label == other.label;

  @override
  int get hashCode =>
      Object.hash(type, columnIndex, firstNameColumnIndex, lastNameColumnIndex, label);
}

class ImportResult {
  final List<String> addedNames;
  final int addedCount;
  final int skippedDuplicatesCount;
  final bool reachedLimit;

  ImportResult({
    required this.addedNames,
    required this.addedCount,
    required this.skippedDuplicatesCount,
    this.reachedLimit = false,
  });

  String get summaryMessage {
    if (reachedLimit) {
      return 'Added $addedCount, skipped $skippedDuplicatesCount (limit of 500 reached)';
    }
    return 'Added $addedCount, skipped $skippedDuplicatesCount';
  }
}

class ParticipantImportService {
  ParticipantImportService._();

  static const int maxParticipantsLimit = 500;

  static const _singleNameHeaders = {
    'name',
    'full name',
    'fullname',
    'employee',
    'employee name',
    'participant',
    'participant name',
    'first name last name',
    'first name + last name',
    'first and last name',
    'first name & last name',
    'first & last name',
  };

  static const _firstNameHeaders = {
    'first name',
    'firstname',
    'first',
    'given name',
    'givenname',
  };

  static const _lastNameHeaders = {
    'last name',
    'lastname',
    'last',
    'surname',
    'family name',
    'familyname',
  };

  static const _skipKeywords = [
    'id',
    'index',
    '#',
    'no',
    'no.',
    'sl',
    'sl.',
    'serial',
    'email',
    'mail',
    'phone',
    'mobile',
    'dob',
    'birth',
    'sex',
    'gender',
    'title',
    'role',
    'department',
    'designation',
  ];

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
    'first name',
    'last name',
    'first',
    'last',
    'person',
  };

  /// Parses bytes from CSV, XLSX, or XLS into a [ParsedTable].
  /// Handles UTF-8 BOM, quoted fields with commas, and semicolon-delimited CSVs.
  static ParsedTable parseTable({
    required Uint8List bytes,
    required String fileName,
  }) {
    final extension = fileName.split('.').last.toLowerCase();
    final rawRows = <List<String>>[];

    if (extension == 'csv') {
      var content = utf8.decode(bytes, allowMalformed: true);
      // Strip UTF-8 BOM if present
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }

      // Check header line to detect delimiter (comma vs semicolon)
      final firstLine = content
          .split(RegExp(r'\r?\n'))
          .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');

      int commaCount = 0;
      int semiCount = 0;
      bool inQuote = false;
      for (int i = 0; i < firstLine.length; i++) {
        final char = firstLine[i];
        if (char == '"') {
          inQuote = !inQuote;
        } else if (!inQuote) {
          if (char == ',') commaCount++;
          if (char == ';') semiCount++;
        }
      }

      final delimiter = (semiCount > commaCount) ? ';' : ',';
      final rows = csv_pkg.Csv(
        fieldDelimiter: delimiter,
        autoDetect: false,
      ).decode(content);

      for (final row in rows) {
        final rowList = <String>[];
        for (final cell in row) {
          rowList.add(cell?.toString().trim() ?? '');
        }
        if (rowList.any((c) => c.isNotEmpty)) {
          rawRows.add(rowList);
        }
      }
    } else if (extension == 'xlsx' || extension == 'xls') {
      excel_pkg.Excel excel;
      try {
        excel = excel_pkg.Excel.decodeBytes(bytes);
      } catch (_) {
        try {
          excel = excel_pkg.Excel.decodeBytes(sanitizeXlsx(bytes));
        } catch (_) {
          throw const FormatException(
            "Couldn't read this file. Check the format or use the template.",
          );
        }
      }

      if (excel.tables.isNotEmpty) {
        final firstSheetName = excel.tables.keys.first;
        final sheet = excel.tables[firstSheetName];
        if (sheet != null) {
          for (final row in sheet.rows) {
            final rowList = <String>[];
            for (final cell in row) {
              rowList.add(cell?.value?.toString().trim() ?? '');
            }
            if (rowList.any((c) => c.isNotEmpty)) {
              rawRows.add(rowList);
            }
          }
        }
      }
    } else {
      throw FormatException(
        "Couldn't read this file. Check the format or use the template.",
      );
    }

    if (rawRows.isEmpty) {
      throw const FormatException(
        "Couldn't read this file. Check the format or use the template.",
      );
    }

    final maxCols = rawRows.fold<int>(
      0,
      (max, r) => r.length > max ? r.length : max,
    );

    final normalized = <List<String>>[];
    for (final r in rawRows) {
      final list = List<String>.from(r);
      while (list.length < maxCols) {
        list.add('');
      }
      normalized.add(list);
    }

    final headers = List<String>.from(normalized.first);
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].isEmpty) {
        headers[i] = 'Column ${i + 1}';
      }
    }

    final dataRows = normalized.length > 1 ? normalized.sublist(1) : <List<String>>[];
    return ParsedTable(headers: headers, rows: dataRows);
  }

  /// Detects the name column in the given [table] following the specified order:
  /// 2a. Header equal to name, full name, employee, etc.
  /// 2b. Both First Name and Last Name columns exist.
  /// 2c. First column whose values are mostly text (>= 80%), ignoring skip headers.
  /// 2d. Returns null if nothing qualifies (prompting user selection).
  static ColumnSelection? detectNameColumn(ParsedTable table) {
    if (table.headers.isEmpty) return null;

    // 2a: Check single header matching name keywords
    for (int i = 0; i < table.headers.length; i++) {
      final h = table.headers[i].trim().toLowerCase();
      if (_singleNameHeaders.contains(h)) {
        return ColumnSelection.single(
          columnIndex: i,
          label: table.headers[i],
        );
      }
    }

    // 2b: Check if both First Name and Last Name columns exist
    int firstIdx = -1;
    int lastIdx = -1;
    for (int i = 0; i < table.headers.length; i++) {
      final h = table.headers[i].trim().toLowerCase();
      if (firstIdx == -1 && _firstNameHeaders.contains(h)) {
        firstIdx = i;
      } else if (lastIdx == -1 && _lastNameHeaders.contains(h)) {
        lastIdx = i;
      }
    }
    if (firstIdx != -1 && lastIdx != -1) {
      return ColumnSelection.combined(
        firstNameColumnIndex: firstIdx,
        lastNameColumnIndex: lastIdx,
        label: '${table.headers[firstIdx]} + ${table.headers[lastIdx]}',
      );
    }

    // 2c: Choose first column whose values are mostly text (>= 80%)
    for (int col = 0; col < table.columnCount; col++) {
      if (_isHeaderSkipped(table.headers[col])) {
        continue;
      }

      final values = <String>[];
      for (final row in table.rows) {
        if (col < row.length) {
          final v = row[col].trim();
          if (v.isNotEmpty) values.add(v);
        }
      }

      if (values.isEmpty) continue;

      int validTextCount = 0;
      for (final v in values) {
        if (isValidNameCandidate(v)) {
          validTextCount++;
        }
      }

      final ratio = validTextCount / values.length;
      if (ratio >= 0.8) {
        return ColumnSelection.single(
          columnIndex: col,
          label: table.headers[col],
        );
      }
    }

    // 2d: Nothing qualifies
    return null;
  }

  /// Returns whether a column header matches skip keywords (id, email, phone, etc.)
  static bool _isHeaderSkipped(String header) {
    final clean = header.trim().toLowerCase();
    if (clean.isEmpty) return false;
    for (final skip in _skipKeywords) {
      if (clean == skip) return true;
      if (skip == '#' && clean.contains('#')) return true;
      // Word boundary match: e.g. "user id", "phone number", "job title"
      if (clean.contains(RegExp('\\b${RegExp.escape(skip)}\\b'))) return true;
    }
    return false;
  }

  /// Checks if a string looks like a candidate name:
  /// - 2 to 40 characters
  /// - contains letters
  /// - does not contain '@'
  /// - is not purely numeric
  static bool isValidNameCandidate(String val) {
    final trimmed = val.trim();
    if (trimmed.length < 2 || trimmed.length > 40) return false;
    if (trimmed.contains('@')) return false;
    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmed)) return false;
    // Disallow purely numeric strings (including phone formatting like +1 234-567)
    if (RegExp(r'^[0-9\s.,+()/-]+$').hasMatch(trimmed)) return false;
    return true;
  }

  /// Returns all available column options for user selection, including
  /// combined First + Last Name if both columns exist.
  static List<ColumnSelection> getAvailableColumnSelections(ParsedTable table) {
    final selections = <ColumnSelection>[];

    int firstIdx = -1;
    int lastIdx = -1;
    for (int i = 0; i < table.headers.length; i++) {
      final h = table.headers[i].trim().toLowerCase();
      if (firstIdx == -1 && _firstNameHeaders.contains(h)) firstIdx = i;
      if (lastIdx == -1 && _lastNameHeaders.contains(h)) lastIdx = i;
    }

    if (firstIdx != -1 && lastIdx != -1) {
      selections.add(
        ColumnSelection.combined(
          firstNameColumnIndex: firstIdx,
          lastNameColumnIndex: lastIdx,
          label: '${table.headers[firstIdx]} + ${table.headers[lastIdx]}',
        ),
      );
    }

    for (int i = 0; i < table.headers.length; i++) {
      selections.add(
        ColumnSelection.single(
          columnIndex: i,
          label: table.headers[i],
        ),
      );
    }

    return selections;
  }

  /// Extracts cleaned names from [table] based on the chosen [selection].
  /// Trims, collapses repeated whitespace, drops empty cells, and drops headers.
  static List<String> extractRawNames(
    ParsedTable table,
    ColumnSelection selection,
  ) {
    final names = <String>[];

    for (final row in table.rows) {
      String raw = '';
      if (selection.type == ColumnSelectionType.single) {
        if (selection.columnIndex < row.length) {
          raw = row[selection.columnIndex];
        }
      } else {
        final first = selection.firstNameColumnIndex < row.length
            ? row[selection.firstNameColumnIndex]
            : '';
        final last = selection.lastNameColumnIndex < row.length
            ? row[selection.lastNameColumnIndex]
            : '';
        raw = '$first $last';
      }

      final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isEmpty) continue;

      final lower = cleaned.toLowerCase();
      if (selection.type == ColumnSelectionType.single) {
        if (lower == table.headers[selection.columnIndex].trim().toLowerCase()) {
          continue;
        }
      }
      if (_headerKeywords.contains(lower)) {
        continue;
      }

      names.add(cleaned);
    }

    return names;
  }

  /// Counts the number of duplicate names that would collide
  /// (either within the extracted names or against [existingParticipants]).
  static int countDuplicates(
    List<String> extractedNames,
    List<String> existingParticipants,
  ) {
    final seen = existingParticipants.map((p) => p.trim().toLowerCase()).toSet();
    int duplicateCount = 0;

    for (final name in extractedNames) {
      final lower = name.toLowerCase();
      if (seen.contains(lower)) {
        duplicateCount++;
      } else {
        seen.add(lower);
      }
    }
    return duplicateCount;
  }

  /// Finalizes import by resolving duplicates and applying the 500-participant limit.
  /// - [renumberDuplicates]: if true, appends " 2", " 3" (e.g. "John Smith 2")
  /// - if false, skips duplicate names
  static ImportResult finalizeImport({
    required List<String> extractedNames,
    required List<String> existingParticipants,
    required bool renumberDuplicates,
  }) {
    final existingLower = existingParticipants.map((p) => p.trim().toLowerCase()).toSet();
    final newlyAdded = <String>[];
    int skippedDuplicates = 0;

    if (renumberDuplicates) {
      final workingSet = Set<String>.from(existingLower);
      for (final name in extractedNames) {
        var candidate = name;
        var lower = candidate.toLowerCase();
        int counter = 2;
        while (workingSet.contains(lower)) {
          candidate = '$name $counter';
          lower = candidate.toLowerCase();
          counter++;
        }
        workingSet.add(lower);
        newlyAdded.add(candidate);
      }
    } else {
      final workingSet = Set<String>.from(existingLower);
      for (final name in extractedNames) {
        final lower = name.toLowerCase();
        if (workingSet.contains(lower)) {
          skippedDuplicates++;
        } else {
          workingSet.add(lower);
          newlyAdded.add(name);
        }
      }
    }

    // Apply 500 max limit
    final availableSlots = maxParticipantsLimit - existingParticipants.length;
    bool reachedLimit = false;
    List<String> finalAdded = newlyAdded;

    if (availableSlots <= 0) {
      reachedLimit = true;
      finalAdded = [];
    } else if (newlyAdded.length > availableSlots) {
      reachedLimit = true;
      finalAdded = newlyAdded.sublist(0, availableSlots);
    }

    return ImportResult(
      addedNames: finalAdded,
      addedCount: finalAdded.length,
      skippedDuplicatesCount: skippedDuplicates,
      reachedLimit: reachedLimit,
    );
  }

  /// Convenience method for parsing and processing in a single call.
  static ImportResult parseFileBytes({
    required Uint8List bytes,
    required String fileName,
    required List<String> existingParticipants,
    bool renumberDuplicates = false,
    ColumnSelection? explicitSelection,
  }) {
    final table = parseTable(bytes: bytes, fileName: fileName);
    final selection = explicitSelection ?? detectNameColumn(table) ?? (
      table.columnCount > 0
          ? ColumnSelection.single(columnIndex: 0, label: table.headers.first)
          : null
    );

    if (selection == null) {
      throw const FormatException(
        "Couldn't read this file. Check the format or use the template.",
      );
    }

    final rawNames = extractRawNames(table, selection);
    return finalizeImport(
      extractedNames: rawNames,
      existingParticipants: existingParticipants,
      renumberDuplicates: renumberDuplicates,
    );
  }
}
