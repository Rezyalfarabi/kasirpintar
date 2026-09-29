import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/utils/platform_files.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_import_service.dart';

const _xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Ringkasan hasil impor, supaya layar bisa menyebutkan apa yang benar-benar
/// terjadi pada produk — bukan hanya "berhasil".
class ImportOutcome {
  /// Produk baru yang dibuat.
  final int added;

  /// Produk lama yang diperbarui karena barcode-nya sama.
  final int updated;

  /// Baris sah yang tidak disentuh karena barcode-nya sudah ada dan operator
  /// memilih mode Lewati Duplikat.
  final int skipped;

  /// Baris yang ditolak karena tidak memenuhi ketentuan produk.
  final int rejected;

  const ImportOutcome({
    required this.added,
    required this.updated,
    required this.skipped,
    required this.rejected,
  });

  int get touched => added + updated;
}

class ExcelImportState {
  final bool isLoading;
  final bool isImporting;
  final ExcelImportResult? result;
  final Uint8List? fileBytes;
  final String? fileName;
  final String? error;
  final ImportOutcome? outcome;

  ExcelImportState({
    this.isLoading = false,
    this.isImporting = false,
    this.result,
    this.fileBytes,
    this.fileName,
    this.error,
    this.outcome,
  });

  ExcelImportState copyWith({
    bool? isLoading,
    bool? isImporting,
    ExcelImportResult? result,
    Uint8List? fileBytes,
    String? fileName,
    String? error,
    ImportOutcome? outcome,
  }) {
    return ExcelImportState(
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      result: result ?? this.result,
      fileBytes: fileBytes ?? this.fileBytes,
      fileName: fileName ?? this.fileName,
      error: error,
      outcome: outcome ?? this.outcome,
    );
  }
}

class ExcelImportController extends StateNotifier<ExcelImportState> {
  final ProductRepository _repository;
  final ExcelImportService _excelService;

  ExcelImportController(this._repository, this._excelService) : super(ExcelImportState());

  void setSelectedFile(Uint8List bytes, String fileName) {
    state = state.copyWith(
      fileBytes: bytes,
      fileName: fileName,
      result: null,
      error: null,
      outcome: null,
    );
  }

  Future<void> parseFile() async {
    final bytes = state.fileBytes;
    if (bytes == null) {
      state = state.copyWith(error: 'Pilih file terlebih dahulu');
      return;
    }

    // DEBUG sementara: titik pertama alur — file dari FilePicker.
    debugPrint('[ExcelDebug] FILE NAME: ${state.fileName ?? '(tanpa nama)'}');
    debugPrint('[ExcelDebug] FILE BYTES: ${bytes.length}');

    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _excelService.importFromBytes(bytes);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Menambah semua produk yang lolos validasi. Barcode yang sudah ada di
  /// database dibiarkan apa adanya.
  Future<ImportOutcome?> importValidRows() => _import(updateExisting: false);

  /// Menambah produk baru dan memperbarui produk yang barcode-nya sudah ada.
  /// Perubahan stok pada produk lama dicatat ke riwayat dengan sumber `excel`.
  Future<ImportOutcome?> importWithUpdateDuplicates() =>
      _import(updateExisting: true);

  Future<ImportOutcome?> _import({required bool updateExisting}) async {
    final result = state.result;
    if (result == null || result.rows.isEmpty) return null;

    state = state.copyWith(isImporting: true, error: null, outcome: null);
    try {
      var added = 0;
      var updated = 0;
      var skipped = 0;

      for (final row in result.rows) {
        final existing = await _repository.getProductByBarcode(row.barcode);

        if (existing == null) {
          await _repository.createProduct(_rowToProduct(row));
          added++;
          continue;
        }

        if (!updateExisting) {
          skipped++;
          continue;
        }

        await _repository.updateProduct(
          existing.copyWith(
            name: row.name,
            price: row.price,
            stock: row.stock,
            category: row.category,
            updatedAt: DateTime.now(),
          ),
          source: StockMovementSource.excel,
          note: state.fileName,
        );
        updated++;
      }

      // Hasilnya ikut disimpan supaya layar bisa menampilkan rekap dan
      // mengarahkan operator ke daftar produk, bukan sekadar "berhasil".
      final outcome = ImportOutcome(
        added: added,
        updated: updated,
        skipped: skipped,
        rejected: result.errorCount,
      );
      state = state.copyWith(isImporting: false, error: null, outcome: outcome);
      return outcome;
    } catch (e) {
      state = state.copyWith(isImporting: false, error: e.toString());
      return null;
    }
  }

  /// Mengunduh template Excel. Di native ditulis ke folder Documents,
  /// di web langsung diunduh oleh browser.
  Future<bool> downloadTemplate() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bytes = _excelService.generateTemplateBytes();
      final saved = await saveBytesToDocuments(
        bytes,
        _excelService.templateFileName,
        mimeType: _xlsxMimeType,
      );
      state = state.copyWith(isLoading: false, error: null);
      return saved;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clear() {
    state = ExcelImportState();
  }
  Product _rowToProduct(ExcelImportRow row) {
    final now = DateTime.now();
    return Product(
      id: 0,
      barcode: row.barcode,
      name: row.name,
      price: row.price,
      stock: row.stock,
      category: row.category,
      imageSource: null,
      imagePath: null,
      imageBytes: null,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }
}
