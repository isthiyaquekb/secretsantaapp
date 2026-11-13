import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Sanitizes an .xlsx file in memory by removing `<numFmt .../>` elements
/// whose numFmtId is less than 164 from `xl/styles.xml`.
///
/// This works around a known issue in the `excel` package (as of v4.0.6)
/// where custom number format IDs below 164 (produced by Apple Numbers,
/// WPS Office, and other spreadsheet tools) cause `Excel.decodeBytes` to throw
/// "Exception: custom numFmtId starts at 164 but found a value of X".
Uint8List sanitizeXlsx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final newArchive = Archive();

  final numFmtRegex = RegExp(
    r'<numFmt\b[^>]*\bnumFmtId="(\d+)"[^>]*/>',
    caseSensitive: false,
  );

  for (final file in archive.files) {
    final normalized = file.name.replaceAll('\\', '/').replaceFirst(RegExp(r'^/'), '');
    if (file.isFile && normalized == 'xl/styles.xml') {
      final raw = file.content;
      final List<int> contentBytes;
      if (raw is List<int>) {
        contentBytes = raw;
      } else if (raw is InputStreamBase) {
        contentBytes = raw.toUint8List();
      } else {
        contentBytes = utf8.encode(raw.toString());
      }

      final xmlString = utf8.decode(contentBytes);
      final sanitizedXml = xmlString.replaceAllMapped(numFmtRegex, (match) {
        final id = int.tryParse(match.group(1) ?? '');
        if (id != null && id < 164) {
          return '';
        }
        return match.group(0)!;
      });

      final encoded = utf8.encode(sanitizedXml);
      newArchive.addFile(ArchiveFile(file.name, encoded.length, encoded));
    } else {
      newArchive.addFile(file);
    }
  }

  final outBytes = ZipEncoder().encode(newArchive);
  return Uint8List.fromList(outBytes ?? const <int>[]);
}
