import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes PDF bytes under app external/documents storage. Returns full path.
Future<String?> saveCertificatePdfToDevice(
  List<int> pdfBytes,
  String language,
) async {
  final Directory dir = await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  final String fileName =
      'LinguaFlow_${language}_Certificate_'
      '${DateTime.now().millisecondsSinceEpoch}.pdf';
  final File file = File('${dir.path}/$fileName');
  await file.writeAsBytes(pdfBytes);
  return file.path;
}
