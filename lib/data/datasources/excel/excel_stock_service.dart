import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_normalizer.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_number.dart';

/// Membaca berkas Excel yang sudah berisi daftar produk — mis. hasil tombol
/// "Ekspor Excel" di halaman Produk — untuk memperbarui stok.
///
/// Berbeda dengan `ExcelImportService` yang membuat produk baru, layanan ini
/// hanya butuh penanda produk (`barcode` atau `nama`) dan satu kolom jumlah.
/// Kolom `harga` dan `kategori` boleh tidak ada, jadi berkas hasil ekspor bisa
/// langsung disunting di kolom stoknya lalu diunggah kembali.
class ExcelStockService {
  /// Nama kolom yang diterima sebagai sumber jumlah stok.
  static const List<String> quantityColumns = ['stok', 'jumlah', 'tambah', 'qty'];
  static const List<String> templateHeaders = ['nama', 'barcode', 'stok'];
  static const String sheetName = 'Tambah Stok';
  static const String templateFileName = 'template_tambah_stok.xlsx';

  StockSheetResult parseFromBytes(Uint8List bytes) {
    try {
      // DEBUG sementara: lihat alur lengkap file -> workbook -> rows -> hasil.
      debugPrint('[ExcelDebug] FILE BYTES: ${bytes.length}');

      final excel = Excel.decodeBytes(normalizeExcelWorkbookTargets(bytes));

      if (excel.tables.isEmpty) {
        return const StockSheetResult(
          success: false,
          error: 'Berkas Excel kosong atau tidak valid',
        );
      }

      // Pembaca memakai sheet pertama dari berkas, apapun namanya.
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables.values.first;

      debugPrint('[ExcelDebug] SHEETS: ${excel.tables.keys.toList()}');
      debugPrint('[ExcelDebug] FIRST SHEET: $sheetName');
      debugPrint('[ExcelDebug] TOTAL RAW ROWS: ${sheet.rows.length}');
      for (var i = 0; i < sheet.rows.length; i++) {
        debugPrint(
          '[ExcelDebug] raw row $i: '
          '${sheet.rows[i].map(_debugCell).toList()}',
        );
      }

      final headers = _readHeaders(sheet);
      debugPrint('[ExcelDebug] HEADERS: $headers');
      for (final column in ['nama', 'barcode', 'harga', 'stok', 'kategori']) {
        debugPrint('[ExcelDebug] INDEX $column = ${headers.indexOf(column)}');
      }

      if (sheet.maxRows < 2) {
        return const StockSheetResult(
          success: false,
          error: 'Berkas hanya berisi baris judul, belum ada data produk',
        );
      }

      final quantityColumn = _firstMatch(headers, quantityColumns);
      if (quantityColumn == null) {
        return StockSheetResult(
          success: false,
          error:
              'Kolom jumlah stok tidak ditemukan. Tambahkan salah satu kolom: ${quantityColumns.join(', ')}',
        );
      }
      debugPrint('[ExcelDebug] QUANTITY COLUMN: $quantityColumn');

      final hasBarcode = headers.contains('barcode');
      final hasName = headers.contains('nama');
      if (!hasBarcode && !hasName) {
        return const StockSheetResult(
          success: false,
          error: 'Kolom "barcode" atau "nama" harus ada untuk mencocokkan produk',
        );
      }

      final rows = <StockSheetRow>[];
      final errors = <StockSheetError>[];
      final seen = <String>{};

      for (var i = 1; i < sheet.maxRows; i++) {
        final rawRow = sheet.row(i);
        final cells = <String, Data?>{};
        for (var c = 0; c < headers.length && c < rawRow.length; c++) {
          cells[headers[c]] = rawRow[c];
        }

        debugPrint(
          '[ExcelDebug] data row excel ${i + 1} (raw index $i): '
          '${rawRow.map(_debugCell).toList()}',
        );

        final barcode = _cellText(cells['barcode']);
        final name = _cellText(cells['nama']);
        final quantity = _cellQuantity(cells[quantityColumn]);

        // Baris kosong di tengah berkas bukan error, cukup dilewati.
        if (barcode.isEmpty && name.isEmpty && quantity == null) continue;

        final rowNumber = i + 1;
        final rowErrors = <String>[];

        if (barcode.isEmpty && name.isEmpty) {
          rowErrors.add('Barcode dan nama kosong');
        }
        if (quantity == null) {
          rowErrors.add('Jumlah stok "${_cellText(cells[quantityColumn])}" bukan angka');
        }

        final key = barcode.isNotEmpty ? 'barcode:$barcode' : 'nama:${name.toLowerCase()}';
        if (!seen.add(key)) {
          rowErrors.add('Produk ini muncul lebih dari sekali di berkas');
        }

        if (rowErrors.isEmpty) {
          rows.add(StockSheetRow(
            row: rowNumber,
            barcode: barcode,
            name: name,
            quantity: quantity!,
          ),);
        } else {
          errors.add(StockSheetError(row: rowNumber, errors: rowErrors));
        }
      }

      if (rows.isEmpty && errors.isEmpty) {
        return const StockSheetResult(
          success: false,
          error: 'Tidak ada baris produk yang bisa dibaca',
        );
      }

      debugPrint('[ExcelDebug] DATA ROWS: ${rows.length + errors.length}');
      debugPrint('[ExcelDebug] VALID ROWS: ${rows.length}');
      debugPrint('[ExcelDebug] ERROR ROWS: ${errors.length}');

      return StockSheetResult(
        success: true,
        rows: rows,
        errors: errors,
        quantityColumn: quantityColumn,
      );
    } catch (e) {
      debugPrint('[ExcelDebug] EXCEL PARSE ERROR: $e');
      return StockSheetResult(success: false, error: 'Gagal membaca berkas: $e');
    }
  }

  /// Bentuk teks satu sel untuk log debug: nilai + tipe aslinya.
  String _debugCell(Data? cell) {
    if (cell == null) return 'null';
    return '${cell.value}(${cell.value.runtimeType})';
  }

  /// Template kosong: pengguna yang belum pernah mengekspor tetap punya
  /// contoh bentuk berkas yang benar.
  Uint8List generateTemplateBytes() {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheetName, sheetName);
    final sheet = excel[sheetName];

    for (var i = 0; i < templateHeaders.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(templateHeaders[i])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#111111'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
    }

    final example = ['Contoh Produk', '1234567890123', '24'];
    for (var i = 0; i < example.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          .value = TextCellValue(example[i]);
    }

    for (var i = 0; i < templateHeaders.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  List<String> _readHeaders(Sheet sheet) {
    return sheet
        .row(0)
        .map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
        .toList();
  }

  String? _firstMatch(List<String> headers, List<String> candidates) {
    for (final candidate in candidates) {
      if (headers.contains(candidate)) return candidate;
    }
    return null;
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) {
      final rounded = value.value.round();
      if (value.value == rounded.toDouble()) return rounded.toString();
      return value.value.toString();
    }
    return value.toString().trim();
  }

  int? _cellQuantity(Data? cell) {
    final value = cell?.value;
    if (value == null) return null;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.round();
    return parseExcelInt(value.toString(), roundDecimal: true);
  }
}

class StockSheetRow {
  /// Nomor baris seperti yang terlihat di Excel, dipakai untuk pesan error.
  final int row;
  final String barcode;
  final String name;
  final int quantity;

  const StockSheetRow({
    required this.row,
    required this.barcode,
    required this.name,
    required this.quantity,
  });
}

class StockSheetError {
  final int row;
  final List<String> errors;

  const StockSheetError({required this.row, required this.errors});
}

class StockSheetResult {
  final bool success;
  final String? error;
  final List<StockSheetRow> rows;
  final List<StockSheetError> errors;
  final String? quantityColumn;

  const StockSheetResult({
    required this.success,
    this.error,
    this.rows = const [],
    this.errors = const [],
    this.quantityColumn,
  });

  int get validCount => rows.length;
  int get errorCount => errors.length;
}
