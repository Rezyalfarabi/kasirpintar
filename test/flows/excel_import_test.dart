import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_import_service.dart';

void main() {
  Uint8List workbook(List<List<CellValue?>> rows) {
    final excel = Excel.createExcel();
    final sheet = excel[excel.tables.keys.first];
    rows.forEach(sheet.appendRow);
    return Uint8List.fromList(excel.encode()!);
  }

  List<CellValue> headerRow() => <CellValue>[
        TextCellValue('nama'),
        TextCellValue('barcode'),
        TextCellValue('harga'),
        TextCellValue('stok'),
        TextCellValue('kategori'),
      ];

  test('impor Excel valid membaca semua baris', () async {
    final bytes = workbook([
      headerRow(),
      <CellValue>[
        TextCellValue('Kopi'),
        TextCellValue('111'),
        TextCellValue('15000'),
        TextCellValue('10'),
        TextCellValue('Minuman'),
      ],
      <CellValue>[
        TextCellValue('Teh'),
        TextCellValue('222'),
        TextCellValue('8000'),
        TextCellValue('5'),
        TextCellValue('Minuman'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    expect(result.success, isTrue);
    expect(result.validCount, 2);
    expect(result.errorCount, 0);
    expect(result.rows.first.name, 'Kopi');
    expect(result.rows.first.barcode, '111');
    expect(result.rows.first.price, 15000);
    expect(result.rows.first.stock, 10);
    expect(result.rows.first.category, 'Minuman');
  });

  test('baris tidak valid dipisahkan ke daftar error', () async {
    final bytes = workbook([
      headerRow(),
      <CellValue>[
        TextCellValue('Valid'),
        TextCellValue('333'),
        TextCellValue('1000'),
        TextCellValue('2'),
        TextCellValue('X'),
      ],
      <CellValue>[
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('0'),
        TextCellValue('1'),
        TextCellValue('Y'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    expect(result.success, isTrue);
    expect(result.validCount, 1);
    expect(result.errorCount, 1);
    expect(result.errors.first.data.barcode, '');
  });

  test('header tidak lengkap ditolak', () async {
    final bytes = workbook([
      <CellValue>[TextCellValue('nama'), TextCellValue('harga')],
      <CellValue>[TextCellValue('Kopi'), TextCellValue('15000')],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    expect(result.success, isFalse);
    expect(result.error, isNotNull);
  });

  test('template yang dibuat bisa dibaca kembali oleh importer', () async {
    final service = ExcelImportService();
    final bytes = service.generateTemplateBytes();

    // Berkas xlsx adalah arsip zip, jadi diawali magic bytes 'PK'.
    expect(bytes.length, greaterThan(0));
    expect(bytes.sublist(0, 2), [0x50, 0x4B]);
    expect(service.templateFileName, endsWith('.xlsx'));

    final result = await service.importFromBytes(bytes);

    // Baris contoh di template harus lolos validasi.
    expect(result.success, isTrue);
    expect(result.validCount, 1);
    expect(result.errorCount, 0);
    expect(result.rows.first.name, 'Contoh Produk');
    expect(result.rows.first.price, 15000);
  });
}
