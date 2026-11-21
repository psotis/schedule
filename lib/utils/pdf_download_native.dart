import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

Future<void> downloadPdfFile(Uint8List bytes, String filename) async {
  await FileSaver.instance.saveFile(
    name: filename,
    bytes: bytes,
    includeExtension: false,
    mimeType: MimeType.pdf,
  );
}
