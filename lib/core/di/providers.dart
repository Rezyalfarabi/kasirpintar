import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/data/datasources/local/app_database.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_export_service.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_import_service.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_stock_service.dart';
import 'package:kasir_pintar/data/datasources/pdf/receipt_pdf_generator.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/data/repositories/transaction_repository.dart';
import 'package:kasir_pintar/data/repositories/impl/product_repository_impl.dart';
import 'package:kasir_pintar/data/repositories/impl/transaction_repository_impl.dart';
import 'package:kasir_pintar/features/barcode/presentation/controllers/barcode_scan_controller.dart';
import 'package:kasir_pintar/features/excel_import/presentation/controllers/excel_import_controller.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/cart_controller.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/transaction_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Initialize with override in main.dart');
});

final productDaoProvider = Provider<ProductDao>((ref) {
  return ref.watch(databaseProvider).productDao;
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(databaseProvider).transactionDao;
});

final stockMovementDaoProvider = Provider<StockMovementDao>((ref) {
  return ref.watch(databaseProvider).stockMovementDao;
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    ref.watch(productDaoProvider),
    ref.watch(stockMovementDaoProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(transactionDaoProvider));
});

final excelImportServiceProvider = Provider<ExcelImportService>((ref) {
  return ExcelImportService();
});

final excelExportServiceProvider = Provider<ExcelExportService>((ref) {
  return ExcelExportService();
});

final excelStockServiceProvider = Provider<ExcelStockService>((ref) {
  return ExcelStockService();
});

final receiptPdfGeneratorProvider = Provider<ReceiptPdfGenerator>((ref) {
  return ReceiptPdfGenerator();
});

final cartControllerProvider = StateNotifierProvider<CartController, CartState>((ref) {
  return CartController(ref.read(productRepositoryProvider));
});

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, TransactionState>((ref) {
  return TransactionController(
    ref.read(transactionRepositoryProvider),
    ref.read(cartControllerProvider.notifier),
  );
});

final excelImportControllerProvider =
    StateNotifierProvider<ExcelImportController, ExcelImportState>((ref) {
  return ExcelImportController(
    ref.read(productRepositoryProvider),
    ref.read(excelImportServiceProvider),
  );
});

final barcodeScanControllerProvider =
    StateNotifierProvider<BarcodeScanController, BarcodeScanState>((ref) {
  return BarcodeScanController(ref.read(productRepositoryProvider));
});

Future<AppDatabase> createDatabase() async {
  return AppDatabase.create();
}
