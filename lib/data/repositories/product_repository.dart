import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';

abstract class ProductRepository {
  Future<List<Product>> getAllProducts({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
    int? limit,
    int? offset,
  });

  Future<int> getProductsCount({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    bool? outOfStockOnly,
  });

  Future<Product?> getProductById(int id);

  Future<Product?> getProductByBarcode(String barcode);

  Future<List<String>> getAllCategories();

  Future<int> createProduct(Product product);

  /// [source] menentukan label perubahan stok di riwayat, bukan perilakunya.
  Future<bool> updateProduct(
    Product product, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  });

  Future<int> updateStock(
    int productId,
    int newStock, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  });

  Future<int> adjustStock(
    int productId,
    int delta, {
    StockMovementSource source = StockMovementSource.manual,
    String? note,
  });

  Future<bool> deleteProduct(int id);

  Future<int> getLowStockCount();

  Future<int> getOutOfStockCount();

  /// Riwayat perubahan stok, terbaru lebih dulu.
  Future<List<StockMovement>> getStockMovements({
    int? productId,
    StockMovementSource? source,
    int? limit,
    int? offset,
  });

  Future<int> getStockMovementsCount({
    int? productId,
    StockMovementSource? source,
  });
}