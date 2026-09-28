import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> persistReceiptPdfImpl(int transactionId, Uint8List bytes) async {
  final appDir = await getApplicationDocumentsDirectory();
  final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
  if (!await receiptsDir.exists()) {
    await receiptsDir.create(recursive: true);
  }
  final file = File(p.join(receiptsDir.path, 'receipt_$transactionId.pdf'));
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<bool> saveBytesToDocumentsImpl(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final appDir = await getApplicationDocumentsDirectory();
  final file = File(p.join(appDir.path, fileName));
  await file.writeAsBytes(bytes);
  return true;
}
