import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:kasir_pintar/data/datasources/local/app_database.dart' as local;
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/repositories/impl/product_repository_impl.dart';
import 'package:kasir_pintar/data/repositories/impl/transaction_repository_impl.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/data/repositories/transaction_repository.dart';

/// Perangkat test: database drift in-memory + repository asli (tanpa mock),
/// sehingga logika DAO/query ikut teruji.
class TestHarness {
  TestHarness() : _db = local.AppDatabase.withExecutor(NativeDatabase.memory());

  final local.AppDatabase _db;

  local.AppDatabase get db => _db;

  late final ProductRepository productRepository =
      ProductRepositoryImpl(_db.productDao, _db.stockMovementDao);

  late final TransactionRepository transactionRepository =
      TransactionRepositoryImpl(_db.transactionDao);

  Future<void> dispose() => _db.close();
}

Product makeProduct({
  String barcode = '111',
  String name = 'Kopi',
  int price = 15000,
  int stock = 10,
  String? category,
  String? imageSource,
  String? imagePath,
  Uint8List? imageBytes,
}) {
  final now = DateTime.now();
  return Product(
    id: 0,
    barcode: barcode,
    name: name,
    price: price,
    stock: stock,
    category: category,
    imageSource: imageSource,
    imagePath: imagePath,
    imageBytes: imageBytes,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );
}
