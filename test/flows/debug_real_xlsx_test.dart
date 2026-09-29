import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_import_service.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_normalizer.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_stock_service.dart';

/// Regression untuk file ASLI sample_import_produk.xlsx (6560 bytes, dua
/// sheet: Produk + Petunjuk, 11 baris pada sheet Produk). Sebelum normalizer
/// dipasang, file ini GAGAL di-decode oleh package excel 4.0.6 karena menulis
/// `Target="/xl/...` absolut di workbook.xml.rels (Null check di table parser
/// package tersebut). Kini harus terbaca penuh tanpa barang yang jatuh.
///
/// Log tahap-demi-tahap (prefiks ExcelDebug) dikeluarkan service sendiri,
/// lihat konsol test sambil file ini berjalan.
void main() {
  test('file asli: decode -> sheet Produk (11 baris) -> 10 valid, 0 error', () async {
    final file = File('test/fixtures/sample_import_produk.xlsx');
    final byteData = Uint8List.fromList(await file.readAsBytes());

    final excel = Excel.decodeBytes(normalizeExcelWorkbookTargets(byteData));
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;
    final headers = sheet.rows.first
        .map((c) => c?.value.toString().trim().toLowerCase() ?? '')
        .toList();

    final stock = ExcelStockService().parseFromBytes(byteData);
    final importResult = await ExcelImportService().importFromBytes(byteData);

    expect(sheetName, 'Produk');
    expect(excel.tables.keys.toList(), ['Produk', 'Petunjuk']);
    expect(sheet.rows.length, 11);
    expect(headers, ['nama', 'barcode', 'harga', 'stok', 'kategori']);
    expect(headers.indexOf('stok'), 3);

    expect(stock.success, isTrue);
    expect(stock.rows.length, 10);
    expect(stock.errorCount, 0);
    expect(stock.quantityColumn, 'stok');

    expect(importResult.success, isTrue);
    expect(importResult.validCount, 10);
    expect(importResult.errorCount, 0);
  });
}