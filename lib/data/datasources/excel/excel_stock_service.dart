import 'dart:typed_data';

import 'package:excel/excel.dart';

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
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return const StockSheetResult(
          success: false,
          error: 'Berkas Excel kosong atau tidak valid',
        );
      }

      final sheet = excel.tables.values.first;
      if (sheet.maxRows < 2) {
        return const StockSheetResult(
          success: false,
          error: 'Berkas hanya berisi baris judul, belum ada data produk',
        );
      }

      final headers = _readHeaders(sheet);
      final quantityColumn = _firstMatch(headers, quantityColumns);
      if (quantityColumn == null) {
        return StockSheetResult(
          success: false,
          error:
              'Kolom jumlah stok tidak ditemukan. Tambahkan salah satu kolom: ${quantityColumns.join(', ')}',
        );
      }

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

      return StockSheetResult(
        success: true,
        rows: rows,
        errors: errors,
        quantityColumn: quantityColumn,
      );
    } catch (e) {
      return StockSheetResult(success: false, error: 'Gagal membaca berkas: $e');
    }
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
    return value.toString().trim();
  }

  int? _cellQuantity(Data? cell) {
    final value = cell?.value;
    if (value == null) return null;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.round();
    return _parseQuantity(value.toString());
  }

  /// Angka dari Excel bisa datang sebagai `24`, `24,0`, atau `1.024`.
  /// Stok selalu bilangan bulat, jadi titik/koma ribuan dibuang dan desimal
  /// dibulatkan — bukan dipotong begitu saja seperti pada kolom harga.
  int? _parseQuantity(String raw) {
    final text = raw.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;

    final thousands = RegExp(r'^\d{1,3}(?:\.\d{3})+$|^\d{1,3}(?:,\d{3})+$');
    if (thousands.hasMatch(text)) {
      return int.tryParse(text.replaceAll('.', '').replaceAll(',', ''));
    }

    final decimal = double.tryParse(text.replaceAll(',', '.'));
    return decimal?.round();
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
