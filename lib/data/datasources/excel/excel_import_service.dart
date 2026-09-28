import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';

class ExcelImportService {
  Future<ExcelImportResult> importFromBytes(Uint8List bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return ExcelImportResult(
          success: false,
          error: 'File Excel kosong atau tidak valid',
        );
      }

      final sheet = excel.tables.values.first;
      if (sheet.maxRows < 2) {
        return ExcelImportResult(
          success: false,
          error: 'File Excel tidak memiliki data (hanya header)',
        );
      }

      final headers = _getHeaders(sheet);
      final validation = _validateHeaders(headers);
      if (!validation.isValid) {
        return ExcelImportResult(
          success: false,
          error: validation.error!,
        );
      }

      final rows = <ExcelImportRow>[];
      final errors = <ExcelRowError>[];

      for (var i = 1; i <= sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;

        final rowData = _parseRow(row, headers);
        final rowErrors = _validateRow(rowData, i + 1);

        if (rowErrors.isNotEmpty) {
          errors.add(ExcelRowError(row: i + 1, errors: rowErrors, data: rowData));
        } else {
          rows.add(rowData);
        }
      }

      return ExcelImportResult(
        success: true,
        rows: rows,
        errors: errors,
      );
    } catch (e) {
      return ExcelImportResult(
        success: false,
        error: 'Gagal membaca file: $e',
      );
    }
  }

  List<String> _getHeaders(Sheet sheet) {
    final headerRow = sheet.row(0);
    return headerRow.map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '').toList();
  }

  ({bool isValid, String? error}) _validateHeaders(List<String> headers) {
    for (final required in AppConstants.excelRequiredColumns) {
      if (!headers.contains(required)) {
        return (isValid: false, error: 'Kolom wajib "$required" tidak ditemukan');
      }
    }
    return (isValid: true, error: null);
  }

  ExcelImportRow _parseRow(List<Data?> row, List<String> headers) {
    final Map<String, String> data = {};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      data[headers[i]] = row[i]?.value?.toString().trim() ?? '';
    }
    return ExcelImportRow(
      name: data['nama'] ?? '',
      barcode: data['barcode'] ?? '',
      price: int.tryParse(data['harga']?.replaceAll('.', '').replaceAll(',', '') ?? '') ?? 0,
      stock: int.tryParse(data['stok'] ?? '') ?? 0,
      category: data['kategori']?.isNotEmpty == true ? data['kategori'] : null,
    );
  }

  List<String> _validateRow(ExcelImportRow row, int rowNumber) {
    final errors = <String>[];

    if (row.name.isEmpty) errors.add('Nama kosong');
    if (row.barcode.isEmpty) errors.add('Barcode kosong');
    if (row.price <= 0) errors.add('Harga harus > 0');
    if (row.stock < 0) errors.add('Stok tidak boleh negatif');

    return errors;
  }

  /// Membuat berkas template dalam bentuk byte. Penyimpanan diserahkan ke
  /// pemanggil karena caranya berbeda antara native dan web.
  Uint8List generateTemplateBytes() {
    final excel = Excel.createExcel();
    // Template harus ditulis ke sheet pertama: importer membaca sheet pertama
    // dari berkas, jadi sheet kosong bawaan harus diberi nama ulang, bukan
    // dibiarkan sehingga data template tertimbun di sheet kedua.
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheetName, 'Template Produk');
    final sheet = excel['Template Produk'];

    final headers = ['nama', 'barcode', 'harga', 'stok', 'kategori'];
    final exampleRow = ['Contoh Produk', '1234567890123', '15000', '10', 'Makanan'];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#111111'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
    }

    for (var i = 0; i < exampleRow.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
        .value = TextCellValue(exampleRow[i]);
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  String get templateFileName => AppConstants.excelTemplateName;
}

class ExcelImportRow {
  final String name;
  final String barcode;
  final int price;
  final int stock;
  final String? category;

  ExcelImportRow({
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
    this.category,
  });
}

class ExcelRowError {
  final int row;
  final List<String> errors;
  final ExcelImportRow data;

  ExcelRowError({
    required this.row,
    required this.errors,
    required this.data,
  });
}

class ExcelImportResult {
  final bool success;
  final String? error;
  final List<ExcelImportRow> rows;
  final List<ExcelRowError> errors;

  ExcelImportResult({
    required this.success,
    this.error,
    this.rows = const [],
    this.errors = const [],
  });

  int get validCount => rows.length;
  int get errorCount => errors.length;
  int get totalCount => validCount + errorCount;
}