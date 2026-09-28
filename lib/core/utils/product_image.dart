import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Menentukan sumber gambar produk tanpa menyentuh filesystem, sehingga aman
/// dipakai di web maupun native.
///
/// - `imageSource == 'url'` memakai [NetworkImage] dari [imagePath].
/// - Selain itu memakai byte gambar yang tersimpan di database.
///
/// Mengembalikan `null` bila produk tidak punya gambar yang bisa ditampilkan
/// (termasuk data lama yang hanya menyimpan path berkas di perangkat).
ImageProvider<Object>? productImageProvider({
  required String? imageSource,
  required String? imagePath,
  Uint8List? imageBytes,
}) {
  if (imageSource == 'url' && imagePath != null && imagePath.isNotEmpty) {
    return NetworkImage(imagePath);
  }
  if (imageBytes != null && imageBytes.isNotEmpty) {
    return MemoryImage(imageBytes);
  }
  return null;
}
