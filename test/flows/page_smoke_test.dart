import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/theme/app_theme.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/data/models/transaction.dart';
import 'package:kasir_pintar/data/models/transaction_item.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/data/repositories/transaction_repository.dart';
import 'package:kasir_pintar/features/product/presentation/pages/product_list_page.dart';
import 'package:kasir_pintar/features/stock_history/presentation/pages/stock_history_page.dart';
import 'package:kasir_pintar/features/stock_in/presentation/pages/stock_in_page.dart';
import 'package:kasir_pintar/features/transaction/presentation/pages/transaction_page.dart';

import '../helpers/test_database.dart';

/// Test asap untuk layar utama: memastikan halaman benar-benar bisa dirender
/// dan tata letaknya tidak meluber pada lebar layar kasir yang umum.
///
/// Repository palsu dipakai supaya test tidak menunggu database; yang diuji di
/// sini adalah tampilan dan interaksi, bukan query.
void main() {
  final products = [
    makeProduct(barcode: '111', name: 'Kopi Susu', price: 15000, stock: 12),
    makeProduct(barcode: '222', name: 'Teh Manis', price: 8000, stock: 0),
  ];

  testWidgets('layar kasir menampilkan katalog dan bisa menambah ke keranjang', (
    tester,
  ) async {
    await tester.pumpWidget(_app(products: products));
    await tester.pump();

    expect(find.text('Kasir Pintar'), findsOneWidget);
    expect(find.text('KATALOG'), findsOneWidget);
    expect(find.text('Kopi Susu'), findsOneWidget);

    // Produk yang stoknya habis tidak boleh bisa diketuk.
    expect(find.text('STOK HABIS'), findsOneWidget);

    await tester.tap(find.text('Kopi Susu'));
    await tester.pump();
    expect(find.text('Kopi Susu ditambahkan'), findsOneWidget);

    await tester.tap(find.text('Keranjang (1)'));
    await tester.pump();

    expect(find.text('KERANJANG'), findsOneWidget);
    expect(find.text('RINGKASAN'), findsOneWidget);
    expect(find.text('Rp 15.000'), findsWidgets);
  });

  testWidgets('layar kasir di layar lebar menampilkan katalog dan keranjang bersamaan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(products: products));
    await tester.pump();

    expect(find.text('KATALOG'), findsOneWidget);
    expect(find.text('KERANJANG'), findsOneWidget);
    expect(find.text('RINGKASAN'), findsOneWidget);
  });

  testWidgets('tombol bayar muncul setelah ada barang di keranjang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(products: products));
    await tester.pump();

    await tester.tap(find.text('Kopi Susu'));
    await tester.pump();

    expect(find.text('BAYAR'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
  });

  testWidgets('halaman produk menampilkan ringkasan stok dan daftar produk', (
    tester,
  ) async {
    await tester.pumpWidget(_app(products: products, initialLocation: '/products'));
    await tester.pump();

    expect(find.text('TOTAL PRODUK'), findsOneWidget);
    expect(find.text('STOK MENIPIS'), findsOneWidget);
    expect(find.text('STOK HABIS'), findsOneWidget);
    expect(find.text('2 dari 2 produk'), findsOneWidget);

    expect(find.text('Kopi Susu'), findsOneWidget);
    expect(find.text('Rp 15.000'), findsOneWidget);
    expect(find.text('STOK 12'), findsOneWidget);
  });

  testWidgets('halaman tambah stok menampilkan langkah unduh dan pilih berkas', (
    tester,
  ) async {
    await tester.pumpWidget(_app(products: products, initialLocation: '/stock-in'));
    await tester.pump();

    expect(find.text('Tambah Stok'), findsOneWidget);
    expect(find.text('Unduh Daftar Produk (.xlsx)'), findsOneWidget);
    expect(find.text('Unduh Template Kosong'), findsOneWidget);
    expect(find.text('Ketuk untuk memilih berkas .xlsx'), findsOneWidget);
  });

  testWidgets('tab Produk menampilkan kondisi kosong saat belum ada produk', (
    tester,
  ) async {
    await tester.pumpWidget(_app(initialLocation: '/products'));
    await tester.pump();

    expect(find.text('Belum Ada Produk'), findsOneWidget);
  });

  testWidgets('tata letak ponsel sempit tidak meluber', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(products: products));
    await tester.pump();
    expect(find.text('KATALOG'), findsOneWidget);

    await tester.tap(find.text('Kopi Susu'));
    await tester.pump();
    await tester.tap(find.text('Keranjang (1)'));
    await tester.pump();
    expect(find.text('RINGKASAN'), findsOneWidget);

    await tester.pumpWidget(_app(products: products, initialLocation: '/products'));
    await tester.pump();
    expect(find.text('TOTAL PRODUK'), findsOneWidget);

    await tester.pumpWidget(_app(products: products, initialLocation: '/stock-in'));
    await tester.pump();
    expect(find.text('Unduh Daftar Produk (.xlsx)'), findsOneWidget);
  });

  testWidgets('halaman riwayat stok menampilkan kosong dan saringan sumber', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(products: products, initialLocation: '/stock-history'),
    );
    await tester.pump();

    expect(find.text('Riwayat Stok'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Dari Excel'), findsOneWidget);
    expect(find.text('Penjualan'), findsOneWidget);
    expect(find.text('Belum Ada Riwayat Stok'), findsOneWidget);
  });
}

Widget _app({
  List<Product> products = const [],
  String initialLocation = '/',
}) {
  return ProviderScope(
    overrides: [
      productRepositoryProvider.overrideWithValue(_FakeProductRepository(products)),
      transactionRepositoryProvider.overrideWithValue(_FakeTransactionRepository()),
    ],
    child: MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TransactionPage()),
          GoRoute(path: '/products', builder: (_, __) => const ProductListPage()),
          GoRoute(path: '/stock-in', builder: (_, __) => const StockInPage()),
          GoRoute(
            path: '/stock-history',
            builder: (_, __) => const StockHistoryPage(),
          ),
        ],
      ),
    ),
  );
}

class _FakeProductRepository implements ProductRepository {
  final List<Product> products;

  _FakeProductRepository(this.products);

  @override
  Future<List<Product>> getAllProducts({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
    int? limit,
    int? offset,
  }) async {
    var result = products;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              p.barcode.contains(searchQuery),)
          .toList();
    }
    if (lowStockOnly == true) {
      result = result.where((p) => p.stock <= 5 && p.stock > 0).toList();
    }
    if (outOfStockOnly == true) {
      result = result.where((p) => p.stock == 0).toList();
    }
    if (offset != null && offset < result.length) {
      result = result.sublist(offset);
    }
    if (limit != null && limit < result.length) {
      result = result.sublist(0, limit);
    }
    return result;
  }

  @override
  Future<int> getProductsCount({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
  }) async {
    final matched = await getAllProducts(
      searchQuery: searchQuery,
      category: category,
      lowStockOnly: lowStockOnly,
      outOfStockOnly: outOfStockOnly,
    );
    return matched.length;
  }

  @override
  Future<Product?> getProductById(int id) async {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    for (final product in products) {
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  @override
  Future<List<String>> getAllCategories() async => const [];

  @override
  Future<int> createProduct(Product product) async => 1;

  @override
  Future<bool> updateProduct(
    Product product, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async =>
      true;

  @override
  Future<int> updateStock(
    int productId,
    int newStock, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async =>
      1;

  @override
  Future<int> adjustStock(
    int productId,
    int delta, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async =>
      1;

  @override
  Future<List<StockMovement>> getStockMovements({
    int? productId,
    StockMovementSource? source,
    int? limit,
    int? offset,
  }) async =>
      const [];

  @override
  Future<int> getStockMovementsCount({
    int? productId,
    StockMovementSource? source,
  }) async =>
      0;

  @override
  Future<bool> deleteProduct(int id) async => true;

  @override
  Future<int> getLowStockCount() async =>
      products.where((p) => p.stock <= 5 && p.stock > 0).length;

  @override
  Future<int> getOutOfStockCount() async =>
      products.where((p) => p.stock == 0).length;
}

class _FakeTransactionRepository implements TransactionRepository {
  @override
  Future<List<TransactionWithItems>> getAllTransactions({
    int? limit,
    int? offset,
  }) async =>
      const [];

  @override
  Future<TransactionWithItems?> getTransactionById(int id) async => null;

  @override
  Future<int> createTransaction(
    Transaction transaction,
    List<TransactionItem> items,
  ) async =>
      1;

  @override
  Future<void> updatePdfPath(int transactionId, String pdfPath) async {}

  @override
  Future<List<TransactionItem>> getTransactionItems(int transactionId) async =>
      const [];

  @override
  Future<int> getTransactionsCount() async => 0;

  @override
  Future<int> getTotalSales({DateTime? startDate, DateTime? endDate}) async => 0;
}
