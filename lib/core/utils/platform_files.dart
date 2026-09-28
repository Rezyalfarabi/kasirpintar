import 'dart:typed_data';

import 'package:kasir_pintar/core/utils/platform_files_native.dart'
    if (dart.library.js_interop) 'package:kasir_pintar/core/utils/platform_files_web.dart';

/// Menyimpan struk PDF ke folder dokumen aplikasi. Di web tidak ada
/// filesystem, jadi struk tidak dipersistensi ke disk.
///
/// Mengembalikan lokasi berkas, atau `null` bila platform tidak mendukung.
/// Halaman struk tetap bisa membuat ulang PDF dari data transaksi.
Future<String?> persistReceiptPdf(int transactionId, Uint8List bytes) =>
    persistReceiptPdfImpl(transactionId, bytes);

/// Menyimpan byte atas permintaan pengguna: ditulis ke folder Documents di
/// native, diunduh lewat browser di web.
///
/// Mengembalikan `true` bila berkas berhasil disimpan atau unduhan dimulai.
Future<bool> saveBytesToDocuments(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) =>
    saveBytesToDocumentsImpl(bytes, fileName, mimeType);
