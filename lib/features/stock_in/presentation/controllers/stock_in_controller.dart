import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/utils/platform_files.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_export_service.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_stock_service.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';

const _xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Cara membaca kolom jumlah pada berkas: ditambahkan ke stok sekarang, atau
/// menggantikan stok sekarang.
enum StockUpdateMode { add, replace }

extension StockUpdateModeLabel on StockUpdateMode {
  String get label => switch (this) {
        StockUpdateMode.add => 'Tambah ke stok',
        StockUpdateMode.replace => 'Set stok baru',
      };
}

/// Satu baris berkas setelah dicocokkan dengan produk di database.
class StockInItem {
  final StockSheetRow row;
  final Product? product;
  final int currentStock;
  final int resultStock;

  const StockInItem({
    required this.row,
    required this.product,
    required this.currentStock,
    required this.resultStock,
  });

  bool get isMatched => product != null;

  int get delta => resultStock - currentStock;
}

class StockInReport {
  final int applied;
  final int notFound;
  final int failed;
  final int stockDelta;

  const StockInReport({
    required this.applied,
    required this.notFound,
    required this.failed,
    required this.stockDelta,
  });
}

class StockInState {
  final String? fileName;
  final Uint8List? fileBytes;
  final StockUpdateMode mode;
  final List<StockInItem> items;
  final List<StockSheetError> parseErrors;
  final String? quantityColumn;
  final bool isParsing;
  final bool isApplying;
  final bool isDownloading;
  final String? error;
  final StockInReport? report;

  const StockInState({
    this.fileName,
    this.fileBytes,
    this.mode = StockUpdateMode.add,
    this.items = const [],
    this.parseErrors = const [],
    this.quantityColumn,
    this.isParsing = false,
    this.isApplying = false,
    this.isDownloading = false,
    this.error,
    this.report,
  });

  StockInState copyWith({
    String? fileName,
    Uint8List? fileBytes,
    StockUpdateMode? mode,
    List<StockInItem>? items,
    List<StockSheetError>? parseErrors,
    String? quantityColumn,
    bool? isParsing,
    bool? isApplying,
    bool? isDownloading,
    String? error,
    StockInReport? report,
    bool clearReport = false,
  }) {
    return StockInState(
      fileName: fileName ?? this.fileName,
      fileBytes: fileBytes ?? this.fileBytes,
      mode: mode ?? this.mode,
      items: items ?? this.items,
      parseErrors: parseErrors ?? this.parseErrors,
      quantityColumn: quantityColumn ?? this.quantityColumn,
      isParsing: isParsing ?? this.isParsing,
      isApplying: isApplying ?? this.isApplying,
      isDownloading: isDownloading ?? this.isDownloading,
      error: error,
      report: clearReport ? null : (report ?? this.report),
    );
  }

  bool get hasFile => fileBytes != null;

  /// Baris yang produknya ada di database — hanya ini yang bisa diterapkan.
  List<StockInItem> get matchedItems =>
      items.where((item) => item.isMatched).toList();

  List<StockInItem> get unmatchedItems =>
      items.where((item) => !item.isMatched).toList();

  int get totalQuantity => matchedItems.fold(0, (sum, item) => sum + item.row.quantity);

  bool get canApply =>
      !isApplying && !isParsing && matchedItems.isNotEmpty && error == null;
}

class StockInController extends StateNotifier<StockInState> {
  final ProductRepository _repository;
  final ExcelStockService _stockService;
  final ExcelExportService _exportService;

  StockInController(this._repository, this._stockService, this._exportService)
      : super(const StockInState());

  /// Memuat berkas dan langsung menyusun pratinjau: baris mana yang cocok
  /// dengan produk mana, dan berapa stok akhirnya.
  Future<void> loadFile(Uint8List bytes, String fileName) async {
    state = StockInState(fileName: fileName, fileBytes: bytes, isParsing: true);

    // DEBUG sementara: titik pertama alur — file dari FilePicker.
    debugPrint('[ExcelDebug] FILE NAME: $fileName');
    debugPrint('[ExcelDebug] EXTENSION: ${fileName.contains('.') ? fileName.split('.').last : '(tidak ada)'}');
    debugPrint('[ExcelDebug] FILE BYTES: ${bytes.length}');

    final result = _stockService.parseFromBytes(bytes);
    if (!result.success) {
      state = state.copyWith(isParsing: false, error: result.error);
      return;
    }

    for (final row in result.rows) {
      debugPrint(
        '[ExcelDebug] parsed: baris ${row.row} '
        'barcode="${row.barcode}" nama="${row.name}" qty=${row.quantity}',
      );
    }

    final products = await _repository.getAllProducts();
    final byBarcode = <String, Product>{};
    final byName = <String, Product>{};
    for (final product in products) {
      byBarcode[product.barcode.trim().toLowerCase()] = product;
      byName.putIfAbsent(product.name.trim().toLowerCase(), () => product);
    }

    final items = result.rows
        .map((row) => _match(row, byBarcode, byName, state.mode))
        .toList();

    // DEBUG sementara: bedakan VALIDATION ERROR vs DATABASE NOT FOUND.
    debugPrint('[ExcelDebug] PRODUK COCOK: ${items.where((i) => i.isMatched).length}');
    debugPrint('[ExcelDebug] TIDAK DITEMUKAN: ${items.where((i) => !i.isMatched).length}');
    debugPrint('[ExcelDebug] BARIS ERROR: ${result.errors.length}');

    state = state.copyWith(
      isParsing: false,
      items: items,
      parseErrors: result.errors,
      quantityColumn: result.quantityColumn,
    );
  }

  void setMode(StockUpdateMode mode) {
    if (state.mode == mode) return;
    final rematched = state.items
        .map((item) => StockInItem(
              row: item.row,
              product: item.product,
              currentStock: item.currentStock,
              resultStock: item.product == null
                  ? 0
                  : mode == StockUpdateMode.add
                      ? item.currentStock + item.row.quantity
                      : item.row.quantity,
            ),)
        .toList();
    state = state.copyWith(mode: mode, items: rematched, clearReport: true);
  }

  Future<bool> apply() async {
    if (!state.canApply) return false;

    final mode = state.mode;
    final items = state.matchedItems;
    // Nama berkas dipakai sebagai catatan di riwayat stok supaya penambahan
    // bisa ditelusuri ke berkas Excel asalnya.
    final note = state.fileName;
    state = state.copyWith(isApplying: true, error: null, clearReport: true);

    var applied = 0;
    var failed = 0;
    var stockDelta = 0;

    for (final item in items) {
      final product = item.product!;
      try {
        final affected = mode == StockUpdateMode.add
            ? await _repository.adjustStock(
                product.id,
                item.row.quantity,
                source: StockMovementSource.excel,
                note: note,
              )
            : await _repository.updateStock(
                product.id,
                item.row.quantity,
                source: StockMovementSource.excel,
                note: note,
              );
        if (affected > 0) {
          applied++;
          stockDelta += item.delta;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }

    state = state.copyWith(
      isApplying: false,
      report: StockInReport(
        applied: applied,
        notFound: state.unmatchedItems.length,
        failed: failed,
        stockDelta: stockDelta,
      ),
    );

    return applied > 0;
  }

  /// Mengunduh daftar produk sekarang dalam bentuk .xlsx — berkas inilah yang
  /// disunting kolom stoknya lalu diunggah kembali ke halaman ini.
  Future<bool> downloadProductSheet() async {
    state = state.copyWith(isDownloading: true, error: null);
    try {
      final products = await _repository.getAllProducts();
      if (products.isEmpty) {
        state = state.copyWith(
          isDownloading: false,
          error: 'Belum ada produk yang bisa diekspor',
        );
        return false;
      }

      final bytes = _exportService.exportProducts(products);
      final saved = await saveBytesToDocuments(
        bytes,
        _exportService.fileNameFor(DateTime.now()),
        mimeType: _xlsxMimeType,
      );
      state = state.copyWith(isDownloading: false);
      return saved;
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> downloadTemplate() async {
    state = state.copyWith(isDownloading: true, error: null);
    try {
      final saved = await saveBytesToDocuments(
        _stockService.generateTemplateBytes(),
        ExcelStockService.templateFileName,
        mimeType: _xlsxMimeType,
      );
      state = state.copyWith(isDownloading: false);
      return saved;
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
      return false;
    }
  }

  /// Membuang hasil unggahan supaya operator bisa memilih berkas berikutnya.
  void clearFile() {
    state = StockInState(mode: state.mode);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  StockInItem _match(
    StockSheetRow row,
    Map<String, Product> byBarcode,
    Map<String, Product> byName,
    StockUpdateMode mode,
  ) {
    Product? product;
    if (row.barcode.isNotEmpty) {
      product = byBarcode[row.barcode.trim().toLowerCase()];
    }
    if (product == null && row.name.isNotEmpty) {
      product = byName[row.name.trim().toLowerCase()];
    }

    if (product == null) {
      return StockInItem(row: row, product: null, currentStock: 0, resultStock: 0);
    }

    return StockInItem(
      row: row,
      product: product,
      currentStock: product.stock,
      resultStock: mode == StockUpdateMode.add
          ? product.stock + row.quantity
          : row.quantity,
    );
  }
}

final stockInControllerProvider =
    StateNotifierProvider<StockInController, StockInState>((ref) {
  return StockInController(
    ref.read(productRepositoryProvider),
    ref.read(excelStockServiceProvider),
    ref.read(excelExportServiceProvider),
  );
});
