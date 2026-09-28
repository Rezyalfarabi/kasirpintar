import 'package:drift/drift.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/data/datasources/local/app_database.dart' as db;
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/core/errors/exception_handler.dart';

class ProductRepositoryImpl implements ProductRepository {
  final db.ProductDao _dao;
  final db.StockMovementDao _movementDao;

  ProductRepositoryImpl(this._dao, this._movementDao);

  @override
  Future<List<Product>> getAllProducts({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
    int? limit,
    int? offset,
  }) async {
    try {
      final dbProducts = await _dao.getAllProducts(
        searchQuery: searchQuery,
        category: category,
        lowStockOnly: lowStockOnly,
        outOfStockOnly: outOfStockOnly,
        limit: limit,
        offset: offset,
      );
      return dbProducts.map(_mapToProduct).toList();
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> getProductsCount({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
  }) async {
    try {
      return await _dao.getProductsCount(
        searchQuery: searchQuery,
        category: category,
        lowStockOnly: lowStockOnly,
        outOfStockOnly: outOfStockOnly,
      );
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<Product?> getProductById(int id) async {
    try {
      final dbProduct = await _dao.getProductById(id);
      return dbProduct != null ? _mapToProduct(dbProduct) : null;
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final dbProduct = await _dao.getProductByBarcode(barcode);
      return dbProduct != null ? _mapToProduct(dbProduct) : null;
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    try {
      return await _dao.getAllCategories();
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> createProduct(Product product) async {
    try {
      final companion = db.ProductsTableCompanion(
        barcode: Value(product.barcode),
        name: Value(product.name),
        price: Value(product.price),
        stock: Value(product.stock),
        category: Value(product.category),
        imageSource: Value(product.imageSource),
        imagePath: Value(product.imagePath),
        imageBytes: Value(product.imageBytes),
        createdAt: Value(product.createdAt),
        updatedAt: Value(product.updatedAt),
        isDeleted: Value(product.isDeleted),
      );
      return await _dao.insertProduct(companion);
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<bool> updateProduct(
    Product product, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async {
    try {
      final companion = db.ProductsTableCompanion(
        id: Value(product.id),
        barcode: Value(product.barcode),
        name: Value(product.name),
        price: Value(product.price),
        stock: Value(product.stock),
        category: Value(product.category),
        imageSource: Value(product.imageSource),
        imagePath: Value(product.imagePath),
        imageBytes: Value(product.imageBytes),
        createdAt: Value(product.createdAt),
        updatedAt: Value(DateTime.now()),
        isDeleted: Value(product.isDeleted),
      );
      return await _dao.updateProduct(companion, source: source, note: note);
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> updateStock(
    int productId,
    int newStock, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async {
    try {
      return await _dao.updateStock(
        productId,
        newStock,
        source: source,
        note: note,
      );
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> adjustStock(
    int productId,
    int delta, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  }) async {
    try {
      return await _dao.adjustStock(
        productId,
        delta,
        source: source,
        note: note,
      );
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<bool> deleteProduct(int id) async {
    try {
      return await _dao.softDeleteProduct(id);
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> getLowStockCount() async {
    try {
      return await _dao.getLowStockCount();
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> getOutOfStockCount() async {
    try {
      return await _dao.getOutOfStockCount();
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<List<StockMovement>> getStockMovements({
    int? productId,
    StockMovementSource? source,
    int? limit,
    int? offset,
  }) async {
    try {
      final rows = await _movementDao.getMovements(
        productId: productId,
        source: source,
        limit: limit,
        offset: offset,
      );
      return rows.map(_mapToMovement).toList();
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> getStockMovementsCount({
    int? productId,
    StockMovementSource? source,
  }) async {
    try {
      return await _movementDao.getMovementsCount(
        productId: productId,
        source: source,
      );
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  StockMovement _mapToMovement(db.StockMovementRow row) {
    return StockMovement(
      id: row.id,
      productId: row.productId,
      productName: row.productName,
      delta: row.delta,
      stockBefore: row.stockBefore,
      stockAfter: row.stockAfter,
      source: StockMovementSourceLabel.fromName(row.source),
      note: row.note,
      createdAt: row.createdAt,
    );
  }

  Product _mapToProduct(db.Product dbProduct) {
    return Product(
      id: dbProduct.id,
      barcode: dbProduct.barcode,
      name: dbProduct.name,
      price: dbProduct.price,
      stock: dbProduct.stock,
      category: dbProduct.category,
      imageSource: dbProduct.imageSource,
      imagePath: dbProduct.imagePath,
      imageBytes: dbProduct.imageBytes,
      createdAt: dbProduct.createdAt,
      updatedAt: dbProduct.updatedAt,
      isDeleted: dbProduct.isDeleted,
    );
  }
}