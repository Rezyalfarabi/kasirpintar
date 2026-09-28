import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Di web tidak ada folder dokumen aplikasi; struk dibuat ulang dari data
/// transaksi saat halaman struk dibuka.
Future<String?> persistReceiptPdfImpl(int transactionId, Uint8List bytes) async =>
    null;

Future<bool> saveBytesToDocumentsImpl(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
