import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';
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

  test('barcode kembar di dalam satu berkas ditolak baris keduanya', () async {
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
      <CellValue>[
        TextCellValue('Kopiversi'),
        TextCellValue('111'),
        TextCellValue('16000'),
        TextCellValue('7'),
        TextCellValue('Minuman'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    // Baris pertama tetap dipakai, yang ditandai baris ketiga.
    expect(result.validCount, 2);
    expect(result.errorCount, 1);
    expect(result.errors.single.row, 4);
    expect(result.errors.single.errors, contains('Barcode sama dengan baris 2'));
    expect(result.errors.single.data.name, 'Kopiversi');
  });

  test('baris gagal validasi tidak menahan barcode-nya untuk baris sah berikutnya', () async {
    final bytes = workbook([
      headerRow(),
      // Baris 2 sah sekali tetapi namanya kosong, jadi tidak akan pernah masuk
      // ke database. Baris 4 memakai barcode sama dan harus tetap diterima.
      <CellValue>[
        TextCellValue(''),
        TextCellValue('111'),
        TextCellValue('15000'),
        TextCellValue('10'),
        TextCellValue('Minuman'),
      ],
      <CellValue>[
        TextCellValue('Kopi Asli'),
        TextCellValue('111'),
        TextCellValue('15000'),
        TextCellValue('10'),
        TextCellValue('Minuman'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    expect(result.validCount, 1);
    expect(result.errorCount, 1);
    expect(result.errors.single.errors, contains('Nama kosong'));
    expect(result.errors.single.errors, isNot(contains(contains('Barcode sama'))));
    expect(result.rows.single.name, 'Kopi Asli');
  });

  test('barcode berbeda huruf besar-kecil tetap dua produk', () async {
    final bytes = workbook([
      headerRow(),
      <CellValue>[
        TextCellValue('Kopi'),
        TextCellValue('abc'),
        TextCellValue('15000'),
        TextCellValue('10'),
        TextCellValue('Minuman'),
      ],
      <CellValue>[
        TextCellValue('Kopi Lain'),
        TextCellValue('ABC'),
        TextCellValue('16000'),
        TextCellValue('10'),
        TextCellValue('Minuman'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    // Constraint UNIQUE di SQLite juga case-sensitive, jadi menandainya
    // duplikat akan menolak baris yang sebenarnya bisa tersimpan.
    expect(result.errorCount, 0);
    expect(result.validCount, 2);
  });

  test('pemisah ribuan pada harga dan stok terbaca', () async {
    final bytes = workbook([
      headerRow(),
      <CellValue>[
        TextCellValue('Kopi'),
        TextCellValue('111'),
        TextCellValue('15.000'),
        TextCellValue('10.000'),
        TextCellValue('Minuman'),
      ],
      <CellValue>[
        TextCellValue('Teh'),
        TextCellValue('222'),
        TextCellValue('8,000'),
        TextCellValue('999.999'),
        TextCellValue('Minuman'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    expect(result.errorCount, 0);
    expect(result.rows.first.price, 15000);
    expect(result.rows.first.stock, 10000);
    expect(result.rows.last.price, 8000);
    expect(result.rows.last.stock, 999999);
  });

  test('harga desimal ditolak, bukan jadi 1500050', () async {
    final bytes = workbook([
      headerRow(),
      <CellValue>[
        TextCellValue('Kopi'),
        TextCellValue('111'),
        TextCellValue('15000.50'),
        TextCellValue('10'),
        TextCellValue('Minuman'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    expect(result.validCount, 0);
    expect(
      result.errors.single.errors,
      contains('Harga bukan angka: "15000.50"'),
    );
  });

  test('harga dan stok berteks ditolak dengan isi yang disebut', () async {
    final bytes = workbook([
      headerRow(),
      <CellValue>[
        TextCellValue('Kopi'),
        TextCellValue('111'),
        TextCellValue('Rp15.000'),
        TextCellValue('10 pcs'),
        TextCellValue('Minuman'),
      ],
    ]);

    final result = await ExcelImportService().importFromBytes(bytes);

    expect(result.validCount, 0);
    expect(result.errors.single.errors, contains('Harga bukan angka: "Rp15.000"'));
    expect(result.errors.single.errors, contains('Stok bukan angka: "10 pcs"'));
  });

  group('batas yang sama dengan form tambah produk', () {
    test('nama, kategori, dan barcode melewati batas ditolak', () async {
      final bytes = workbook([
        headerRow(),
        <CellValue>[
          TextCellValue('N' * (AppConstants.maxNameLength + 1)),
          TextCellValue('111'),
          TextCellValue('15000'),
          TextCellValue('10'),
          TextCellValue('Minuman'),
        ],
        <CellValue>[
          TextCellValue('Kopi'),
          TextCellValue('B' * (AppConstants.maxBarcodeLength + 1)),
          TextCellValue('15000'),
          TextCellValue('10'),
          TextCellValue('Minuman'),
        ],
        <CellValue>[
          TextCellValue('Teh'),
          TextCellValue('222'),
          TextCellValue('15000'),
          TextCellValue('10'),
          TextCellValue('K' * (AppConstants.maxCategoryLength + 1)),
        ],
      ]);

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.validCount, 0);
      expect(
        result.errors.map((e) => e.errors.single).toList(),
        containsAll(<String>[
          'Nama maksimal ${AppConstants.maxNameLength} karakter',
          'Barcode maksimal ${AppConstants.maxBarcodeLength} karakter',
          'Kategori maksimal ${AppConstants.maxCategoryLength} karakter',
        ]),
      );
    });

    test('tepat di batas masih diterima', () async {
      final bytes = workbook([
        headerRow(),
        <CellValue>[
          TextCellValue('N' * AppConstants.maxNameLength),
          TextCellValue('B' * AppConstants.maxBarcodeLength),
          TextCellValue('${AppConstants.maxPrice}'),
          TextCellValue('${AppConstants.maxStock}'),
          TextCellValue('K' * AppConstants.maxCategoryLength),
        ],
      ]);

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.errorCount, 0);
      expect(result.rows.single.name.length, AppConstants.maxNameLength);
      expect(result.rows.single.price, AppConstants.maxPrice);
      expect(result.rows.single.stock, AppConstants.maxStock);
    });

    test('harga dan stok melewati batas maksimum ditolak', () async {
      final bytes = workbook([
        headerRow(),
        <CellValue>[
          TextCellValue('Kopi Mahal'),
          TextCellValue('111'),
          TextCellValue('${AppConstants.maxPrice + 1}'),
          TextCellValue('10'),
          TextCellValue('Minuman'),
        ],
        <CellValue>[
          TextCellValue('Teh Gudang'),
          TextCellValue('222'),
          TextCellValue('8000'),
          TextCellValue('${AppConstants.maxStock + 1}'),
          TextCellValue('Minuman'),
        ],
      ]);

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.validCount, 0);
      expect(
        result.errors.first.errors,
        contains('Harga maksimal ${AppConstants.maxPrice}'),
      );
      expect(
        result.errors.last.errors,
        contains('Stok maksimal ${AppConstants.maxStock}'),
      );
    });

    test('harga dan stok negatif ditolak dengan pesan yang tepat', () async {
      final bytes = workbook([
        headerRow(),
        <CellValue>[
          TextCellValue('Kopi'),
          TextCellValue('111'),
          TextCellValue('-15000'),
          TextCellValue('-2'),
          TextCellValue('Minuman'),
        ],
      ]);

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.validCount, 0);
      expect(result.errors.single.errors, contains('Harga harus lebih dari 0'));
      expect(result.errors.single.errors, contains('Stok tidak boleh negatif'));
    });

    test('harga nol ditolak sebagai nilai yang tidak valid, bukan sebagai batas maksimum', () async {
      final bytes = workbook([
        headerRow(),
        <CellValue>[
          TextCellValue('Kopi'),
          TextCellValue('222'),
          TextCellValue('0'),
          TextCellValue('5'),
          TextCellValue('Minuman'),
        ],
      ]);

      final result = await ExcelImportService().importFromBytes(bytes);

      // Harga nol adalah batas bawah, bukan batas atas. Pesan yang menyebut
      // batas maksimum membuat operator mengira angkanya kelewat besar.
      expect(result.validCount, 0);
      expect(result.errors.single.errors, contains('Harga harus lebih dari 0'));
      expect(
        result.errors.single.errors,
        isNot(contains('Harga maksimal ${AppConstants.maxPrice}')),
      );
    });

    test('harga dan stok tepat di batas tetap diterima', () async {
      final bytes = workbook([
        headerRow(),
        <CellValue>[
          TextCellValue('Kopi'),
          TextCellValue('333'),
          TextCellValue('${AppConstants.maxPrice}'),
          TextCellValue('${AppConstants.maxStock}'),
          TextCellValue('Minuman'),
        ],
      ]);

      final result = await ExcelImportService().importFromBytes(bytes);

      expect(result.validCount, 1);
      expect(result.rows.single.price, AppConstants.maxPrice);
      expect(result.rows.single.stock, AppConstants.maxStock);
    });
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
