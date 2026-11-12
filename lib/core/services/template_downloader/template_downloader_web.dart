import 'dart:convert';
import 'package:web/web.dart' as web;

Future<void> downloadOrShareCsv(String filename, String content) async {
  final uri = Uri.dataFromString(content, mimeType: 'text/csv', encoding: utf8).toString();
  final anchor = web.HTMLAnchorElement()
    ..href = uri
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

