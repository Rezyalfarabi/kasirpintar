import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/utils/platform_files.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_import_service.dart';

const _xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class ExcelImportState {
  final bool isLoading;
  final bool isImporting;
  final ExcelImportResult? result;
  final Uint8List? fileBytes;
  final String? fileName;
  final String? error;

  ExcelImportState({
    this.isLoading = false,
    this.isImporting = false,
    this.result,
    this.fileBytes,
    this.fileName,
    this.error,
  });

  ExcelImportState copyWith({
    bool? isLoading,
    bool? isImporting,
    ExcelImportResult? result,
    Uint8List? fileBytes,
    String? fileName,
    String? error,
  }) {
    return ExcelImportState(
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      result: result ?? this.result,
      fileBytes: fileBytes ?? this.fileBytes,
      fileName: fileName ?? this.fileName,
      error: error,
    );
  }
}

class ExcelImportController extends StateNotifier<ExcelImportState> {
  final ProductRepository _repository;
  final ExcelImportService _excelService;

  ExcelImportController(this._repository, this._excelService) : super(ExcelImportState());

  void setSelectedFile(Uint8List bytes, String fileName) {
    state = state.copyWith(fileBytes: bytes, fileName: fileName, result: null, error: null);
  }

  Future<void> parseFile() async {
    final bytes = state.fileBytes;
    if (bytes == null) {
      state = state.copyWith(error: 'Pilih file terlebih dahulu');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _excelService.importFromBytes(bytes);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> importValidRows() async {
    final result = state.result;
    if (result == null || result.rows.isEmpty) return false;

    state = state.copyWith(isImporting: true, error: null);
    try {
      int imported = 0;

      for (final row in result.rows) {
        final existing = await _repository.getProductByBarcode(row.barcode);
        if (existing != null) {
          continue;
        }

        await _repository.createProduct(_rowToProduct(row));
        imported++;
      }

      state = state.copyWith(isImporting: false, error: null);
      return imported > 0;
    } catch (e) {
      state = state.copyWith(isImporting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> importWithUpdateDuplicates() async {
    final result = state.result;
    if (result == null || result.rows.isEmpty) return false;

    state = state.copyWith(isImporting: true, error: null);
    try {
      int imported = 0;
      int updated = 0;

      for (final row in result.rows) {
        final existing = await _repository.getProductByBarcode(row.barcode);
        if (existing != null) {
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
        } else {
          await _repository.createProduct(_rowToProduct(row));
          imported++;
        }
      }

      state = state.copyWith(isImporting: false, error: null);
      return imported > 0 || updated > 0;
    } catch (e) {
      state = state.copyWith(isImporting: false, error: e.toString());
      return false;
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
