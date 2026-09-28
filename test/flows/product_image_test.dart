import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  final imageBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3]);

  test('byte gambar tersimpan dan terbaca kembali dari database', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: 'G1', imageSource: 'camera', imageBytes: imageBytes),
    );

    final loaded = (await harness.productRepository.getProductById(id))!;

    expect(loaded.imageBytes, isNotNull);
    expect(loaded.imageBytes, imageBytes);
    expect(loaded.imageSource, 'camera');
    expect(loaded.hasImage, isTrue);
  });

  test('gambar bisa diganti dan dihapus lewat copyWith', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: 'G2', imageSource: 'gallery', imageBytes: imageBytes),
    );
    final loaded = (await harness.productRepository.getProductById(id))!;

    final otherBytes = Uint8List.fromList([9, 9, 9]);
    final replaced = loaded.copyWith(imageBytes: otherBytes);
    expect(replaced.imageBytes, otherBytes);

    final cleared = loaded.copyWith(clearImage: true);
    expect(cleared.imageBytes, isNull);
    expect(cleared.imagePath, isNull);
    expect(cleared.imageSource, isNull);
    expect(cleared.hasImage, isFalse);
  });
}
