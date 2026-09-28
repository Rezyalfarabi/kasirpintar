import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:kasir_pintar/data/models/product.dart';

/// Menyusun daftar produk menjadi berkas Excel.
///
/// Susunan kolomnya sengaja dibuat sama persis dengan yang dibaca
/// `ExcelImportService`, supaya berkas hasil ekspor bisa disunting lalu
/// diimpor kembali tanpa mengubah apa pun.
class ExcelExportService {
  static const List<String> headers = ['nama', 'barcode', 'harga', 'stok', 'kategori'];
  static const String sheetName = 'Daftar Produk';

  Uint8List exportProducts(List<Product> products) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#111111'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
    }

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      final rowIndex = i + 1;

      // Barcode ditulis sebagai teks agar angka panjang tidak berubah bentuk.
      _writeText(sheet, 0, rowIndex, product.name);
      _writeText(sheet, 1, rowIndex, product.barcode);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = IntCellValue(product.price);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = IntCellValue(product.stock);
      _writeText(sheet, 4, rowIndex, product.category ?? '');
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  void _writeText(Sheet sheet, int column, int row, String value) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .value = TextCellValue(value);
  }

  /// Nama berkas menyertakan tanggal supaya ekspor berulang tidak saling
  /// menimpa berkas lama.
  String fileNameFor(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'produk_${date.year}$month$day.xlsx';
  }
}
