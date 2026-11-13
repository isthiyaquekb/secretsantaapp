import 'dart:io';
import 'package:share_plus/share_plus.dart';

Future<void> downloadOrShareCsv(String filename, String content) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$filename');
  await file.writeAsString(content);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv', name: filename)],
      subject: 'Secret Santa Participants Template',
    ),
  );
}
