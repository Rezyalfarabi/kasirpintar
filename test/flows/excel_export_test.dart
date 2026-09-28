import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_export_service.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_import_service.dart';

import '../helpers/test_database.dart';

void main() {
  final exporter = ExcelExportService();
  final importer = ExcelImportService();

  test('berkas ekspor adalah xlsx yang valid', () {
    final bytes = exporter.exportProducts([makeProduct(barcode: '111')]);

    // Arsip zip selalu diawali 'PK'.
    expect(bytes.length, greaterThan(0));
    expect(bytes.sublist(0, 2), [0x50, 0x4B]);
  });

  test('berkas ekspor bisa dibaca kembali oleh importer', () async {
    final products = [
      makeProduct(barcode: '111', name: 'Kopi Susu', price: 18000, stock: 12, category: 'Minuman'),
      makeProduct(barcode: '222', name: 'Roti Bakar', price: 25000, stock: 4, category: 'Makanan'),
    ];

    final bytes = exporter.exportProducts(products);
    final result = await importer.importFromBytes(bytes);

    expect(result.success, isTrue);
    expect(result.errorCount, 0);
    expect(result.validCount, 2);

    final first = result.rows.first;
    expect(first.name, 'Kopi Susu');
    expect(first.barcode, '111');
    expect(first.price, 18000);
    expect(first.stock, 12);
    expect(first.category, 'Minuman');

    final second = result.rows[1];
    expect(second.name, 'Roti Bakar');
    expect(second.price, 25000);
    expect(second.stock, 4);
  });

  test('barcode panjang tetap utuh sebagai teks', () async {
    const longBarcode = '8991002101234';
    final bytes = exporter.exportProducts([makeProduct(barcode: longBarcode)]);

    final result = await importer.importFromBytes(bytes);

    expect(result.rows.single.barcode, longBarcode);
  });

  test('produk tanpa kategori tidak dianggap error', () async {
    final bytes = exporter.exportProducts([makeProduct(barcode: '333', category: null)]);

    final result = await importer.importFromBytes(bytes);

    expect(result.validCount, 1);
    expect(result.rows.single.category, isNull);
  });

  test('nama berkas memuat tanggal agar ekspor tidak saling menimpa', () {
    expect(
      exporter.fileNameFor(DateTime(2026, 3, 7)),
      'produk_20260307.xlsx',
    );
  });

  test('ekspor tanpa produk tetap menghasilkan berkas berheader saja', () async {
    final Uint8List bytes = exporter.exportProducts([]);
    final result = await importer.importFromBytes(bytes);

    // Hanya header, jadi tidak ada data untuk diimpor.
    expect(result.success, isFalse);
    expect(result.error, contains('tidak memiliki data'));
  });
}
