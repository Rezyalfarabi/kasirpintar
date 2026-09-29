import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_import_service.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_stock_service.dart';

/// Reproduksi dari laporan "0 baris dibaca": berkas .xlsx dengan sheet pertama
/// bernama "Produk", baris 1 header, baris 2-11 data produk. Berkas seperti ini
/// harus terbaca 10 baris data, 10 valid, 0 error — baik di impor produk maupun
/// di tambah stok.
void main() {
  const products = <({String name, String barcode, int harga, int stok, String kategori})>[
    (name: 'Indomie Goreng', barcode: '8991002101011', harga: 3500, stok: 48, kategori: 'Makanan'),
    (name: 'Aqua 600ml', barcode: '8996001600017', harga: 4000, stok: 30, kategori: 'Minuman'),
    (name: 'Teh Botol Sosro', barcode: '8998009010012', harga: 5000, stok: 25, kategori: 'Minuman'),
    (name: 'Pop Mie', barcode: '8991009123456', harga: 6000, stok: 40, kategori: 'Makanan'),
    (name: 'Sari Roti Coklat', barcode: '8991009100113', harga: 13000, stok: 15, kategori: 'Roti'),
    (name: 'Chitato 68gr', barcode: '8991009100571', harga: 7500, stok: 22, kategori: 'Snack'),
    (name: 'Bimoli 2L', barcode: '8992773000135', harga: 42000, stok: 8, kategori: 'Bahan Pokok'),
    (name: 'Beras Ramos 5kg', barcode: '8992773000401', harga: 75000, stok: 12, kategori: 'Bahan Pokok'),
    (name: 'Kapal Api 200g', barcode: '8997007100101', harga: 18000, stok: 20, kategori: 'Bahan Pokok'),
    (name: 'ABC Saus Sambal', barcode: '8992734002013', harga: 9500, stok: 18, kategori: 'Bumbu'),
  ];

  /// Membuat workbook dengan sheet pertama bernama [sheetName] dan header
  /// sesuai [headerOrder]. Nilai kolom mengikuti [headerOrder]; `harga` dan
  /// `stok` memakai [IntCellValue] seperti yang dihasilkan pembaca Excel
  /// untuk bilangan bulat.
  Uint8List workbook({
    required String sheetName,
    required List<String> headerOrder,
    bool numbersAsText = false,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    sheet.appendRow(headerOrder.map(TextCellValue.new).toList());

    String valueOf(String header, ({String name, String barcode, int harga, int stok, String kategori}) p) =>
        switch (header.toLowerCase()) {
          'nama' => p.name,
          'barcode' => p.barcode,
          'harga' => p.harga.toString(),
          'stok' => p.stok.toString(),
          'kategori' => p.kategori,
          _ => '',
        };

    for (final product in products) {
      sheet.appendRow([
        for (final header in headerOrder)
          if (numbersAsText)
            TextCellValue(valueOf(header, product))
          else if (header.toLowerCase() == 'harga')
            IntCellValue(product.harga)
          else if (header.toLowerCase() == 'stok')
            IntCellValue(product.stok)
          else
            TextCellValue(valueOf(header, product)),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  group('impor produk — berkas contoh 10 baris', () {
    test('sheet Produk, header urut normal: 10 data, 10 valid, 0 error', () async {
      final bytes = workbook(
        sheetName: 'Produk',
        headerOrder: ['nama', 'barcode', 'harga', 'stok', 'kategori'],
      );

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.success, isTrue);
      expect(result.totalCount, 10, reason: 'total baris data harus 10');
      expect(result.validCount, 10, reason: 'semua baris valid');
      expect(result.errorCount, 0, reason: 'tidak boleh ada baris error');
      expect(result.rows.first.name, 'Indomie Goreng');
      expect(result.rows.first.barcode, '8991002101011');
      expect(result.rows.first.price, 3500);
      expect(result.rows.first.stock, 48);
      expect(result.rows.last.name, 'ABC Saus Sambal');
    });

    test('header huruf besar dan urutan kolom bebas tetap terbaca', () async {
      final bytes = workbook(
        sheetName: 'Produk',
        headerOrder: ['STOK', 'NAMA', 'KATEGORI', 'BARCODE', 'HARGA'],
      );

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.success, isTrue);
      expect(result.totalCount, 10);
      expect(result.validCount, 10);
      expect(result.errorCount, 0);
      expect(result.rows.first.price, 3500);
      expect(result.rows.first.stock, 48);
      expect(result.rows.first.category, 'Makanan');
    });

    test('kolom tambahan diabaikan', () async {
      final bytes = workbook(
        sheetName: 'Produk',
        headerOrder: ['nama', 'barcode', 'harga', 'stok', 'kategori', 'keterangan'],
      );

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.success, isTrue);
      expect(result.validCount, 10);
      expect(result.errorCount, 0);
    });

    test('angka yang disimpan sebagai teks tetap sama-sama 10 valid', () async {
      final bytes = workbook(
        sheetName: 'Produk',
        headerOrder: ['nama', 'barcode', 'harga', 'stok', 'kategori'],
        numbersAsText: true,
      );

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.success, isTrue);
      expect(result.validCount, 10);
      expect(result.errorCount, 0);
      expect(result.rows.first.price, 3500);
      expect(result.rows.first.stock, 48);
    });
  });

  group('tambah stok bisa membaca berkas yang sama', () {
    test('kolom jumlah terdeteksi "stok" dan 10 baris terbaca', () {
      final bytes = workbook(
        sheetName: 'Produk',
        headerOrder: ['nama', 'barcode', 'harga', 'stok', 'kategori'],
      );

      final result = ExcelStockService().parseFromBytes(bytes);

      expect(result.success, isTrue);
      expect(result.quantityColumn, 'stok',
          reason: 'baris dibaca memakai kolom jumlah "stok"',);
      expect(result.rows.length, 10, reason: 'semua baris data terbaca');
      expect(result.validCount, 10);
      expect(result.errorCount, 0);
      expect(result.rows.first.barcode, '8991002101011');
      expect(result.rows.first.quantity, 48);
    });
  });
}