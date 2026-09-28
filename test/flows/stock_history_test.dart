import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/data/models/transaction.dart';
import 'package:kasir_pintar/data/models/transaction_item.dart';

import '../helpers/test_database.dart';

void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  test('stok awal produk baru tercatat sebagai produk baru', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', stock: 10),
    );

    final movements = await harness.productRepository.getStockMovements();

    expect(movements, hasLength(1));
    expect(movements.single.productId, id);
    expect(movements.single.productName, 'Kopi');
    expect(movements.single.source, StockMovementSource.create);
    expect(movements.single.delta, 10);
    expect(movements.single.stockBefore, 0);
    expect(movements.single.stockAfter, 10);
  });

  test('produk tanpa stok awal tidak membuat baris riwayat', () async {
    await harness.productRepository.createProduct(
      makeProduct(barcode: '111', stock: 0),
    );

    expect(await harness.productRepository.getStockMovements(), isEmpty);
  });

  test('penambahan dari Excel tercatat lengkap dengan nama berkas', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', stock: 10),
    );

    await harness.productRepository.adjustStock(
      id,
      5,
      source: StockMovementSource.excel,
      note: 'stok_agustus.xlsx',
    );

    final latest = (await harness.productRepository.getStockMovements()).first;
    expect(latest.source, StockMovementSource.excel);
    expect(latest.delta, 5);
    expect(latest.stockBefore, 10);
    expect(latest.stockAfter, 15);
    expect(latest.note, 'stok_agustus.xlsx');
  });

  test('ubah stok manual tercatat, nilai yang sama tidak', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', stock: 4),
    );

    await harness.productRepository.updateStock(id, 4);
    expect(await harness.productRepository.getStockMovementsCount(), 1);

    await harness.productRepository.updateStock(id, 9);
    final movements = await harness.productRepository.getStockMovements();
    expect(movements, hasLength(2));
    expect(movements.first.source, StockMovementSource.manual);
    expect(movements.first.delta, 5);
    expect(movements.first.stockAfter, 9);
  });

  test('ubah produk lewat form ikut mencatat perubahan stok', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', stock: 3),
    );
    final product = (await harness.productRepository.getProductById(id))!;

    // Nama berubah tanpa menyentuh stok: tidak boleh ada baris baru.
    await harness.productRepository.updateProduct(
      product.copyWith(name: 'Kopi Susu'),
    );
    expect(await harness.productRepository.getStockMovementsCount(), 1);

    await harness.productRepository.updateProduct(
      product.copyWith(name: 'Kopi Susu', stock: 20),
    );
    final latest = (await harness.productRepository.getStockMovements()).first;
    expect(latest.productName, 'Kopi Susu');
    expect(latest.delta, 17);
    expect(latest.stockBefore, 3);
    expect(latest.stockAfter, 20);
  });

  test('penjualan mengurangi stok dan tercatat sebagai penjualan', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', price: 15000, stock: 10),
    );

    final transactionId = await harness.transactionRepository.createTransaction(
      Transaction(
        id: 0,
        date: DateTime.now(),
        totalPrice: 30000,
        paidAmount: 50000,
        changeAmount: 20000,
        pdfPath: null,
      ),
      [
        TransactionItem(
          id: 0,
          transactionId: 0,
          productId: id,
          productName: 'Kopi',
          qty: 2,
          unitPrice: 15000,
          subtotal: 30000,
        ),
      ],
    );

    final product = (await harness.productRepository.getProductById(id))!;
    expect(product.stock, 8);

    final latest = (await harness.productRepository.getStockMovements()).first;
    expect(latest.source, StockMovementSource.sale);
    expect(latest.delta, -2);
    expect(latest.stockBefore, 10);
    expect(latest.stockAfter, 8);
    expect(latest.note, 'Transaksi #$transactionId');
  });

  test('stok tidak jadi negatif walau jumlah jual melebihi stok', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', price: 15000, stock: 1),
    );

    await harness.transactionRepository.createTransaction(
      Transaction(
        id: 0,
        date: DateTime.now(),
        totalPrice: 45000,
        paidAmount: 50000,
        changeAmount: 5000,
        pdfPath: null,
      ),
      [
        TransactionItem(
          id: 0,
          transactionId: 0,
          productId: id,
          productName: 'Kopi',
          qty: 3,
          unitPrice: 15000,
          subtotal: 45000,
        ),
      ],
    );

    final product = (await harness.productRepository.getProductById(id))!;
    expect(product.stock, 0);

    final latest = (await harness.productRepository.getStockMovements()).first;
    expect(latest.delta, -1);
    expect(latest.stockAfter, 0);
  });

  test('produk yang dihapus mencatat sisa stoknya keluar', () async {
    final id = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', stock: 7),
    );

    await harness.productRepository.deleteProduct(id);

    final latest = (await harness.productRepository.getStockMovements()).first;
    expect(latest.source, StockMovementSource.delete);
    expect(latest.delta, -7);
    expect(latest.stockAfter, 0);
  });

  test('riwayat bisa disaring per produk dan per sumber', () async {
    final kopi = await harness.productRepository.createProduct(
      makeProduct(barcode: '111', name: 'Kopi', stock: 10),
    );
    final teh = await harness.productRepository.createProduct(
      makeProduct(barcode: '222', name: 'Teh', stock: 4),
    );

    await harness.productRepository.adjustStock(
      kopi,
      5,
      source: StockMovementSource.excel,
      note: 'stok.xlsx',
    );
    await harness.productRepository.adjustStock(teh, -1);

    expect(await harness.productRepository.getStockMovementsCount(), 4);

    final kopiOnly = await harness.productRepository.getStockMovements(
      productId: kopi,
    );
    expect(kopiOnly, hasLength(2));
    expect(kopiOnly.every((m) => m.productId == kopi), isTrue);

    final fromExcel = await harness.productRepository.getStockMovements(
      source: StockMovementSource.excel,
    );
    expect(fromExcel, hasLength(1));
    expect(fromExcel.single.note, 'stok.xlsx');
    expect(
      await harness.productRepository.getStockMovementsCount(
        source: StockMovementSource.excel,
      ),
      1,
    );

    // Terbaru lebih dulu supaya yang paling relevan langsung terlihat.
    final all = await harness.productRepository.getStockMovements();
    expect(all.first.productId, teh);
    expect(all.first.delta, -1);
  });
}
