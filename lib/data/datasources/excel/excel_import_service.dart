import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_normalizer.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_number.dart';

class ExcelImportService {
  Future<ExcelImportResult> importFromBytes(Uint8List bytes) async {
    try {
      // DEBUG sementara: lihat alur lengkap file -> workbook -> rows -> hasil.
      debugPrint('[ExcelDebug] FILE BYTES: ${bytes.length}');

      final excel = Excel.decodeBytes(normalizeExcelWorkbookTargets(bytes));

      if (excel.tables.isEmpty) {
        return ExcelImportResult(
          success: false,
          error: 'File Excel kosong atau tidak valid',
        );
      }

      // Importer membaca sheet pertama dari berkas, apapun namanya.
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

      final headers = _getHeaders(sheet);
      debugPrint('[ExcelDebug] HEADERS: $headers');
      for (final column in ['nama', 'barcode', 'harga', 'stok', 'kategori']) {
        debugPrint('[ExcelDebug] INDEX $column = ${headers.indexOf(column)}');
      }

      if (sheet.maxRows < 2) {
        return ExcelImportResult(
          success: false,
          error: 'File Excel tidak memiliki data (hanya header)',
        );
      }

      final validation = _validateHeaders(headers);
      if (!validation.isValid) {
        return ExcelImportResult(
          success: false,
          error: validation.error!,
        );
      }

      final rows = <ExcelImportRow>[];
      final errors = <ExcelRowError>[];

      // Barcode sudah menjadi kunci pencocokan produk di database, jadi dua
      // baris dengan barcode sama di dalam satu berkas pasti bermaksud satu
      // produk. Tanpa daftar ini baris kedua lolos validasi lalu diam-diam
      // menimpa baris pertama, tergantung mode impor yang dipilih.
      final firstRowByBarcode = <String, int>{};

      // Dibatasi `i < sheet.maxRows` — maxRows adalah JUMLAH baris, sedangkan
      // `sheet.row()` memakai index mulai 0, jadi index terakhir yang sah
      // adalah maxRows - 1.
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        final cells = _readCells(row, headers);

        debugPrint(
          '[ExcelDebug] data row excel ${i + 1} (raw index $i): '
          '${row.map(_debugCell).toList()}',
        );

        // `sheet.row()` selalu mengembalikan list selebar maxColumns dan
        // mengisinya dengan null untuk sel kosong, jadi `row.isEmpty` tidak
        // pernah benar. Baris yang semua selnya kosong dilewati, bukan
        // dihitung sebagai error.
        final headerCells = cells.entries.where((e) => e.key.isNotEmpty);
        if (headerCells.every((e) => e.value.trim().isEmpty)) continue;

        final rowNumber = i + 1;
        final rowData = _parseRow(cells);
        final rowErrors = _validateRow(
          rowData,
          rowNumber,
          cells,
          firstRowByBarcode,
        );

        if (rowErrors.isNotEmpty) {
          errors.add(ExcelRowError(row: rowNumber, errors: rowErrors, data: rowData));
        } else {
          rows.add(rowData);
        }
      }

      debugPrint('[ExcelDebug] DATA ROWS: ${rows.length + errors.length}');
      debugPrint('[ExcelDebug] VALID ROWS: ${rows.length}');
      debugPrint('[ExcelDebug] ERROR ROWS: ${errors.length}');

      return ExcelImportResult(
        success: true,
        rows: rows,
        errors: errors,
      );
    } catch (e) {
      debugPrint('[ExcelDebug] EXCEL PARSE ERROR: $e');
      return ExcelImportResult(
        success: false,
        error: 'Gagal membaca file: $e',
      );
    }
  }

  /// Bentuk teks satu sel untuk log debug: nilai + tipe aslinya (IntCellValue,
  /// DoubleCellValue, TextCellValue, dst) supaya kelihatan apakah angka datang
  /// sebagai int, double, atau teks.
  String _debugCell(Data? cell) {
    if (cell == null) return 'null';
    return '${cell.value}(${cell.value.runtimeType})';
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

  /// Mengumpulkan sel satu baris menjadi peta judul kolom ke teks sel. Judul
  /// kolom sudah dinormalkan oleh [_getHeaders], jadi kunci peta ini sama dengan
  /// nama kolom yang diminta pengguna.
  Map<String, String> _readCells(List<Data?> row, List<String> headers) {
    final Map<String, String> cells = {};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      cells[headers[i]] = _cellText(row[i]);
    }
    return cells;
  }

  /// Teks sebuah sel. Angka bulat yang disimpan spreadsheet sebagai `DoubleCellValue`
  /// (mis. `3500.0`) diformat tanpa `0` desimal, supaya tidak salah ditolak
  /// sebagai "bukan angka" padahal nilainya bulat.
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

  ExcelImportRow _parseRow(Map<String, String> cells) {
    // Angka yang gagal dibaca menjadi nol supaya baris ini masih bisa
    // ditampilkan di tabel preview. Alasan penolakannya dikumpulkan di
    // [_validateRow] dari teks aslinya, bukan dari angka hasil parse.
    return ExcelImportRow(
      name: cells['nama'] ?? '',
      barcode: cells['barcode'] ?? '',
      price: parseExcelInt(cells['harga'] ?? '') ?? 0,
      stock: parseExcelInt(cells['stok'] ?? '') ?? 0,
      category: cells['kategori']?.isNotEmpty == true ? cells['kategori'] : null,
    );
  }

  List<String> _validateRow(
    ExcelImportRow row,
    int rowNumber,
    Map<String, String> cells,
    Map<String, int> firstRowByBarcode,
  ) {
    final errors = <String>[];

    // Aturan di sini sengaja mengikuti `Validators` yang dipakai form tambah
    // produk. Dua pintu masuk produk harus menolak nilai yang sama, kalau tidak
    // operator bisa memasukkan produk lewat Excel yang akan ditolak form.
    if (row.name.isEmpty) {
      errors.add('Nama kosong');
    } else if (row.name.length > AppConstants.maxNameLength) {
      errors.add('Nama maksimal ${AppConstants.maxNameLength} karakter');
    }

    if (row.barcode.isEmpty) {
      errors.add('Barcode kosong');
    } else if (row.barcode.length > AppConstants.maxBarcodeLength) {
      errors.add('Barcode maksimal ${AppConstants.maxBarcodeLength} karakter');
    }

    errors.addAll(
      _numberErrors(
        label: 'Harga',
        text: cells['harga'] ?? '',
        value: row.price,
        minInclusive: 1,
        max: AppConstants.maxPrice,
        belowMinimum: 'Harga harus lebih dari 0',
        aboveMaximum: 'Harga maksimal ${AppConstants.maxPrice}',
      ),
    );

    errors.addAll(
      _numberErrors(
        label: 'Stok',
        text: cells['stok'] ?? '',
        value: row.stock,
        // Stok boleh nol: produk yang baru didaftarkan belum tentu punya stok.
        minInclusive: 0,
        max: AppConstants.maxStock,
        belowMinimum: 'Stok tidak boleh negatif',
        aboveMaximum: 'Stok maksimal ${AppConstants.maxStock}',
      ),
    );
    if (row.category != null && row.category!.length > AppConstants.maxCategoryLength) {
      errors.add('Kategori maksimal ${AppConstants.maxCategoryLength} karakter');
    }

    // Barcode baru diklaim setelah baris ini lolos semua pemeriksaan lain.
    // Kalau baris yang gagal validasi ikut diklaim, baris sah berikutnya yang
    // memakai barcode sama akan ditandai duplikat padahal pendahulunya tidak
    // pernah masuk ke database.
    if (errors.isNotEmpty || row.barcode.isEmpty) return errors;

    // Pencocokan sengaja case-sensitive agar sama dengan constraint UNIQUE di
    // SQLite, yang juga membedakan huruf besar dan kecil. Baris pertama tetap
    // dipakai; hanya baris berikutnya yang ditandai supaya operator memilih,
    // bukan membiarkan baris terakhir diam-diam menang.
    final firstRow = firstRowByBarcode.putIfAbsent(row.barcode, () => rowNumber);
    if (firstRow != rowNumber) {
      errors.add('Barcode sama dengan baris $firstRow');
    }

    return errors;
  }

  /// Memisahkan kondisi yang sering tertukar saat mem-parsing Excel: teksnya
  /// bukan angka, angkanya di luar rentang yang diizinkan, dan angkanya tidak
  /// terbaca karena desimal. Kolom `harga` dengan isi `15000.50` misalnya bukan
  /// "harga 15 juta" — itu harus ditolak, bukan diam-diam jadi `1500050`.
  List<String> _numberErrors({
    required String label,
    required String text,
    required int value,
    required int minInclusive,
    required int max,
    required String belowMinimum,
    required String aboveMaximum,
  }) {
    if (parseExcelInt(text) == null) {
      return ['$label bukan angka: "$text"'];
    }
    if (value >= minInclusive && value <= max) return const [];
    // Batas bawah dan batas atas dibedakan karena keduanya punya perbaikan
    // yang berbeda: harga nol perlu dinaikkan, sedangkan harga di atas batas
    // perlu dipotong. Ditolak dengan pesan yang sama akan membuat operator
    // menebak angka yang salah.
    return [if (value < minInclusive) belowMinimum else aboveMaximum];
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