import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/core/utils/product_image.dart';

void main() {
  final imageBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3]);

  test('URL gambar menang atas byte dan tetap bisa ditampilkan', () {
    final provider = productImageProvider(
      imageSource: 'url',
      imagePath: 'https://example.com/kopi.jpg',
      imageBytes: imageBytes,
    );

    expect(provider, isA<NetworkImage>());
  });

  test('resolver memakai byte gambar untuk sumber kamera atau galeri', () {
    final provider = productImageProvider(
      imageSource: 'camera',
      imagePath: null,
      imageBytes: imageBytes,
    );

    expect(provider, isA<MemoryImage>());
  });

  test('produk tanpa gambar yang bisa dibaca mengembalikan null', () {
    expect(
      productImageProvider(imageSource: 'camera', imagePath: null, imageBytes: null),
      isNull,
    );
    // Data lama: hanya menyimpan path relatif di perangkat, byte-nya tidak ada.
    expect(
      productImageProvider(
        imageSource: 'gallery',
        imagePath: 'images/produk_1.jpg',
        imageBytes: null,
      ),
      isNull,
    );
    // URL kosong tidak dianggap gambar.
    expect(
      productImageProvider(imageSource: 'url', imagePath: '', imageBytes: null),
      isNull,
    );
  });
}
