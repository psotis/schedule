import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadPdfFile(Uint8List bytes, String filename) async {
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..rel = 'noopener'
    ..style.display = 'none';
  try {
    web.document.body!.appendChild(anchor);
    anchor.click();
  } catch (_) {
    web.URL.revokeObjectURL(url);
    rethrow;
  } finally {
    anchor.remove();
  }
  // Safari may consume the blob after click() returns. Keep it alive long enough.
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}
