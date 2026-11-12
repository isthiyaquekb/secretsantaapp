import 'package:xmasfriend/core/services/template_downloader/template_downloader.dart';

class TemplateService {
  TemplateService._();

  static const String templateFilename = 'secret-santa-employees-template.csv';

  static const String sampleCsvContent = 'Name\n'
      'Amit\n'
      'Ayesha\n'
      'Arjun\n'
      'Issac\n'
      'Gopika\n'
      'Mujeeb\n'
      'Sareefa\n';

  static Future<void> downloadOrShareSampleTemplate() async {
    await downloadOrShareCsv(templateFilename, sampleCsvContent);
  }
}
