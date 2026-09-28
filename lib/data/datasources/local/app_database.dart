import 'package:drift/drift.dart';

import 'package:kasir_pintar/data/datasources/local/database_connection.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';

part 'app_database.g.dart';

@DataClassName('Product')
class ProductsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get barcode => text().unique()();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()();
  TextColumn get imageSource => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  // Gambar disimpan sebagai byte di database agar terbaca di web maupun native.
  BlobColumn get imageBytes => blob().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('Transaction')
class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalPrice => integer()();
  IntColumn get paidAmount => integer()();
  IntColumn get changeAmount => integer()();
  TextColumn get pdfPath => text().nullable()();
}

@DataClassName('TransactionItemData')
class TransactionItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(TransactionsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  TextColumn get productName => text()();
  IntColumn get qty => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get subtotal => integer()();
}

/// Riwayat perubahan stok. Tabelnya append-only: satu baris dicatat setiap
/// stok berubah, termasuk saat berkurang karena penjualan.
@DataClassName('StockMovementRow')
class StockMovementsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Sengaja tanpa foreign key: riwayat harus tetap utuh walau produknya
  // dihapus, dan productName menyimpan nama saat perubahan terjadi.
  IntColumn get productId => integer()();
  TextColumn get productName => text()();
  IntColumn get delta => integer()();
  IntColumn get stockBefore => integer()();
  IntColumn get stockAfter => integer()();

  /// Salah satu nama nilai [StockMovementSource].
  TextColumn get source => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    ProductsTable,
    TransactionsTable,
    TransactionItemsTable,
    StockMovementsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Untuk produksi gunakan [AppDatabase.create]. Konstruktor ini juga
  /// dipakai test dengan `NativeDatabase.memory()`.
  AppDatabase.withExecutor(super.e);

  static Future<AppDatabase> create() async {
    return AppDatabase.withExecutor(await createDatabaseConnection());
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(productsTable, productsTable.imageBytes);
        }
        if (from < 3) {
          await m.createTable(stockMovementsTable);
        }
      },
    );
  }

  ProductDao get productDao => ProductDao(this);
  TransactionDao get transactionDao => TransactionDao(this);
  StockMovementDao get stockMovementDao => StockMovementDao(this);
}

@DriftAccessor(tables: [ProductsTable, StockMovementsTable])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<Product>> getAllProducts({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
    int? limit,
    int? offset,
  }) {
    final query = select(productsTable)
      ..where((p) => p.isDeleted.equals(false));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where((p) =>
          p.name.contains(searchQuery) |
          p.barcode.contains(searchQuery),);
    }

    if (category != null && category.isNotEmpty) {
      query.where((p) => p.category.equals(category));
    }

    if (lowStockOnly == true) {
      // Stok 0 sudah punya filternya sendiri, jadi di sini hanya yang masih
      // ada tapi tinggal sedikit.
      query.where((p) => p.stock.isSmallerOrEqualValue(5) & p.stock.isBiggerThanValue(0));
    }

    if (outOfStockOnly == true) {
      query.where((p) => p.stock.equals(0));
    }

    query.orderBy([(p) => OrderingTerm.asc(p.name)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  Future<int> getProductsCount({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
  }) {
    final countExp = productsTable.id.count();
    final query = selectOnly(productsTable)
      ..addColumns([countExp])
      ..where(productsTable.isDeleted.equals(false));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where(
        productsTable.name.contains(searchQuery) |
            productsTable.barcode.contains(searchQuery),
      );
    }

    if (category != null && category.isNotEmpty) {
      query.where(productsTable.category.equals(category));
    }

    if (lowStockOnly == true) {
      query.where(productsTable.stock.isSmallerOrEqualValue(5) &
          productsTable.stock.isBiggerThanValue(0),);
    }

    if (outOfStockOnly == true) {
      query.where(productsTable.stock.equals(0));
    }

    return query.map((row) => row.read(countExp)!).getSingle();
  }

  Future<Product?> getProductById(int id) {
    return (select(productsTable)
          ..where((p) => p.id.equals(id) & p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcode) {
    return (select(productsTable)
          ..where((p) => p.barcode.equals(barcode) & p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<List<String>> getAllCategories() {
    final query = selectOnly(productsTable)
      ..addColumns([productsTable.category])
      ..where(productsTable.isDeleted.equals(false) & productsTable.category.isNotNull())
      ..groupBy([productsTable.category])
      ..orderBy([OrderingTerm.asc(productsTable.category)]);
    return query.map((row) => row.read(productsTable.category)!).get();
  }

  Future<int> insertProduct(ProductsTableCompanion product) {
    return transaction(() async {
      final id = await into(productsTable).insert(product);
      final stock = product.stock.present ? product.stock.value : 0;

      // Stok awal ikut dicatat supaya riwayat selalu bisa menjelaskan angka
      // stok yang sekarang.
      if (stock != 0) {
        await _insertMovement(
          productId: id,
          productName: product.name.present ? product.name.value : '',
          before: 0,
          after: stock,
          source: StockMovementSource.create,
        );
      }
      return id;
    });
  }

  /// Menulis ulang produk. Perubahan stok yang ikut terbawa form dicatat ke
  /// riwayat, jadi stok tidak pernah berubah tanpa jejak.
  Future<bool> updateProduct(
    ProductsTableCompanion product, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async {
    final productId = product.id.value;
    final existing = await getProductById(productId);

    return transaction(() async {
      final updated = await update(productsTable).replace(product);

      if (updated &&
          existing != null &&
          product.stock.present &&
          product.stock.value != existing.stock) {
        await _insertMovement(
          productId: productId,
          productName: product.name.present ? product.name.value : existing.name,
          before: existing.stock,
          after: product.stock.value,
          source: source,
          note: note,
        );
      }
      return updated;
    });
  }

  Future<int> updateStock(
    int productId,
    int newStock, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async {
    final existing = await getProductById(productId);

    return transaction(() async {
      final affected = await (update(productsTable)
            ..where((p) => p.id.equals(productId)))
          .write(ProductsTableCompanion(
        stock: Value(newStock),
        updatedAt: Value(DateTime.now()),
      ),);

      if (affected > 0 && existing != null && existing.stock != newStock) {
        await _insertMovement(
          productId: productId,
          productName: existing.name,
          before: existing.stock,
          after: newStock,
          source: source,
          note: note,
        );
      }
      return affected;
    });
  }

  Future<int> adjustStock(
    int productId,
    int delta, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async {
    final product = await getProductById(productId);
    if (product == null) {
      return 0;
    }
    return updateStock(
      productId,
      product.stock + delta,
      source: source,
      note: note,
    );
  }

  Future<bool> softDeleteProduct(int id) async {
    final existing = await getProductById(id);

    return transaction(() async {
      final affected = await (update(productsTable)
            ..where((p) => p.id.equals(id)))
          .write(ProductsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),);

      // Sisa stok ikut hilang dari peredaran saat produk dihapus, jadi
      // perubahannya perlu tercatat.
      if (affected > 0 && existing != null && existing.stock != 0) {
        await _insertMovement(
          productId: id,
          productName: existing.name,
          before: existing.stock,
          after: 0,
          source: StockMovementSource.delete,
        );
      }
      return affected > 0;
    });
  }

  Future<void> _insertMovement({
    required int productId,
    required String productName,
    required int before,
    required int after,
    required StockMovementSource source,
    String? note,
  }) {
    return into(stockMovementsTable).insert(
      StockMovementsTableCompanion(
        productId: Value(productId),
        productName: Value(productName),
        delta: Value(after - before),
        stockBefore: Value(before),
        stockAfter: Value(after),
        source: Value(source.name),
        note: Value(note),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> getLowStockCount() {
    final countExp = productsTable.id.count();
    final query = selectOnly(productsTable)
      ..addColumns([countExp])
      ..where(productsTable.isDeleted.equals(false) &
          productsTable.stock.isSmallerOrEqualValue(5) &
          productsTable.stock.isBiggerThanValue(0),);
    return query.map((row) => row.read(countExp)!).getSingle();
  }

  Future<int> getOutOfStockCount() {
    final countExp = productsTable.id.count();
    final query = selectOnly(productsTable)
      ..addColumns([countExp])
      ..where(productsTable.isDeleted.equals(false) & productsTable.stock.equals(0));
    return query.map((row) => row.read(countExp)!).getSingle();
  }
}

@DriftAccessor(
  tables: [
    TransactionsTable,
    TransactionItemsTable,
    ProductsTable,
    StockMovementsTable,
  ],
)
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<List<TransactionWithItems>> getAllTransactions({
    int? limit,
    int? offset,
  }) {
    final query = select(transactionsTable)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.join([
      leftOuterJoin(transactionItemsTable, transactionItemsTable.transactionId.equalsExp(transactionsTable.id)),
    ]).map((row) {
      final transaction = row.readTable(transactionsTable);
      final item = row.readTableOrNull(transactionItemsTable);
      return TransactionWithItems(transaction, item);
    }).get();
  }

  Future<TransactionWithItems?> getTransactionById(int id) {
    return (select(transactionsTable)
          ..where((t) => t.id.equals(id)))
        .join([
          leftOuterJoin(transactionItemsTable, transactionItemsTable.transactionId.equalsExp(transactionsTable.id)),
        ])
        .map((row) {
          final transaction = row.readTable(transactionsTable);
          final item = row.readTableOrNull(transactionItemsTable);
          return TransactionWithItems(transaction, item);
        })
        .getSingleOrNull();
  }

  Future<int> insertTransaction(TransactionsTableCompanion transaction) {
    return into(transactionsTable).insert(transaction);
  }

  /// Menyimpan transaksi beserta itemnya, sekaligus mengurangi stok dan
  /// mencatat perubahannya ke riwayat stok.
  ///
  /// Semuanya dalam satu transaksi database: kalau ada satu langkah yang gagal,
  /// stok tidak berkurang tanpa transaksi dan sebaliknya.
  Future<int> insertTransactionWithItems(
    TransactionsTableCompanion transaction,
    List<TransactionItemsTableCompanion> items,
  ) {
    return this.transaction(() async {
      final id = await into(transactionsTable).insert(transaction);

      for (final item in items) {
        await into(transactionItemsTable)
            .insert(item.copyWith(transactionId: Value(id)));

        final productId = item.productId.value;
        final quantity = item.qty.value;
        if (quantity <= 0) continue;

        final product = await (select(productsTable)
              ..where((p) => p.id.equals(productId)))
            .getSingleOrNull();
        if (product == null) continue;

        // Stok tidak boleh jadi negatif walau validasi di keranjang lolos
        // sebelum ada perubahan lain di perangkat kedua.
        final newStock = product.stock - quantity < 0 ? 0 : product.stock - quantity;

        await (update(productsTable)..where((p) => p.id.equals(productId)))
            .write(ProductsTableCompanion(
          stock: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),);

        await into(stockMovementsTable).insert(
          StockMovementsTableCompanion(
            productId: Value(productId),
            productName: Value(product.name),
            delta: Value(newStock - product.stock),
            stockBefore: Value(product.stock),
            stockAfter: Value(newStock),
            source: Value(StockMovementSource.sale.name),
            note: Value('Transaksi #$id'),
            createdAt: Value(DateTime.now()),
          ),
        );
      }

      return id;
    });
  }

  Future<List<TransactionItemData>> getTransactionItems(int transactionId) {
    return (select(transactionItemsTable)
          ..where((ti) => ti.transactionId.equals(transactionId)))
        .get();
  }

  Future<int> getTransactionsCount() {
    final countExp = transactionsTable.id.count();
    final query = selectOnly(transactionsTable)..addColumns([countExp]);
    return query.map((row) => row.read(countExp)!).getSingle();
  }

  Future<int> getTotalSales({DateTime? startDate, DateTime? endDate}) {
    final sumExp = transactionsTable.totalPrice.sum();
    final query = selectOnly(transactionsTable)..addColumns([sumExp]);

    if (startDate != null) {
      query.where(transactionsTable.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactionsTable.date.isSmallerOrEqualValue(endDate));
    }

    return query.map((row) => row.read(sumExp) ?? 0).getSingle();
  }

  Future<void> updatePdfPath(int transactionId, String pdfPath) {
    return (update(transactionsTable)
          ..where((t) => t.id.equals(transactionId)))
        .write(TransactionsTableCompanion(pdfPath: Value(pdfPath)));
  }
}

class TransactionWithItems {
  final Transaction transaction;
  final TransactionItemData? item;

  TransactionWithItems(this.transaction, this.item);
}

@DriftAccessor(tables: [StockMovementsTable])
class StockMovementDao extends DatabaseAccessor<AppDatabase>
    with _$StockMovementDaoMixin {
  StockMovementDao(super.db);

  Future<List<StockMovementRow>> getMovements({
    int? productId,
    StockMovementSource? source,
    int? limit,
    int? offset,
  }) {
    final query = select(stockMovementsTable)
      ..orderBy([
        (m) => OrderingTerm.desc(m.createdAt),
        (m) => OrderingTerm.desc(m.id),
      ]);

    if (productId != null) {
      query.where((m) => m.productId.equals(productId));
    }
    if (source != null) {
      query.where((m) => m.source.equals(source.name));
    }
    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  Future<int> getMovementsCount({
    int? productId,
    StockMovementSource? source,
  }) {
    final countExp = stockMovementsTable.id.count();
    final query = selectOnly(stockMovementsTable)..addColumns([countExp]);

    if (productId != null) {
      query.where(stockMovementsTable.productId.equals(productId));
    }
    if (source != null) {
      query.where(stockMovementsTable.source.equals(source.name));
    }

    return query.map((row) => row.read(countExp)!).getSingle();
  }
}