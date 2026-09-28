import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  test('tambah produk lalu terbaca kembali lewat id dan barcode', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(
        barcode: '899',
        name: 'Kopi Susu',
        price: 18000,
        stock: 5,
        category: 'Minuman',
      ),
    );

    expect(id, greaterThan(0));

    final byId = await harness.productRepository.getProductById(id);
    expect(byId, isNotNull);
    expect(byId!.name, 'Kopi Susu');
    expect(byId.price, 18000);
    expect(byId.stock, 5);

    final byBarcode = await harness.productRepository.getProductByBarcode('899');
    expect(byBarcode?.id, id);
  });

  test('update produk, stok absolut, dan penyesuaian stok', () async {
    final id = await harness.productRepository
        .createProduct(makeProduct(barcode: 'A1', price: 10000, stock: 3));

    final product = (await harness.productRepository.getProductById(id))!;
    await harness.productRepository
        .updateProduct(product.copyWith(name: 'Nama Baru', price: 12000));
    expect((await harness.productRepository.getProductById(id))!.price, 12000);
    expect((await harness.productRepository.getProductById(id))!.name, 'Nama Baru');

    await harness.productRepository.updateStock(id, 7);
    expect((await harness.productRepository.getProductById(id))!.stock, 7);

    await harness.productRepository.adjustStock(id, -2);
    expect((await harness.productRepository.getProductById(id))!.stock, 5);
  });

  test('daftar, pencarian, kategori distinct, dan hitungan stok', () async {
    await harness.productRepository.createProduct(
      makeProduct(barcode: 'P1', name: 'Apel', price: 5000, stock: 0, category: 'Buah'),
    );
    await harness.productRepository.createProduct(
      makeProduct(barcode: 'P2', name: 'Buku', price: 20000, stock: 3, category: 'Alat'),
    );
    await harness.productRepository.createProduct(
      makeProduct(barcode: 'P3', name: 'Ceri', price: 30000, stock: 10, category: 'Buah'),
    );

    expect((await harness.productRepository.getAllProducts()).length, 3);

    final search = await harness.productRepository.getAllProducts(searchQuery: 'Cer');
    expect(search.single.name, 'Ceri');

    final byCategory = await harness.productRepository.getAllProducts(category: 'Buah');
    expect(byCategory.length, 2);

    final categories = await harness.productRepository.getAllCategories();
    expect(categories.length, 2);
    expect(categories, containsAll(<String>['Buah', 'Alat']));

    expect(await harness.productRepository.getProductsCount(), 3);
    expect(await harness.productRepository.getOutOfStockCount(), 1);
    expect(await harness.productRepository.getLowStockCount(), 1);
  });

  test('hapus produk bersifat soft delete', () async {
    final id = await harness.productRepository.createProduct(makeProduct(barcode: 'DEL'));

    expect(await harness.productRepository.deleteProduct(id), isTrue);
    expect(await harness.productRepository.getProductById(id), isNull);
    expect(await harness.productRepository.getAllProducts(), isEmpty);
  });
}
