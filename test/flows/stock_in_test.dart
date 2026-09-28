import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_export_service.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_stock_service.dart';
import 'package:kasir_pintar/features/stock_in/presentation/controllers/stock_in_controller.dart';

import '../helpers/test_database.dart';

void main() {
  group('ExcelStockService', () {
    final service = ExcelStockService();

    test('membaca kolom stok dari berkas hasil ekspor', () {
      final result = service.parseFromBytes(
        _sheet([
          ['nama', 'barcode', 'harga', 'stok', 'kategori'],
          ['Kopi', '111', '15000', '5', 'Minuman'],
        ]),
      );

      expect(result.success, isTrue);
      expect(result.rows, hasLength(1));
      expect(result.rows.first.barcode, '111');
      expect(result.rows.first.quantity, 5);
      expect(result.quantityColumn, 'stok');
    });

    test('menerima kolom "jumlah" dan angka ribuan bertitik', () {
      final result = service.parseFromBytes(
        _sheet([
          ['nama', 'jumlah'],
          ['Kopi', '1.500'],
        ]),
      );

      expect(result.success, isTrue);
      expect(result.quantityColumn, 'jumlah');
      expect(result.rows.first.quantity, 1500);
    });

    test('menolak berkas tanpa kolom jumlah', () {
      final result = service.parseFromBytes(
        _sheet([
          ['nama', 'barcode', 'harga'],
          ['Kopi', '111', '15000'],
        ]),
      );

      expect(result.success, isFalse);
      expect(result.error, contains('jumlah stok'));
    });

    test('memisahkan baris tidak valid dan baris dobel', () {
      final result = service.parseFromBytes(
        _sheet([
          ['nama', 'barcode', 'stok'],
          ['Kopi', '111', '5'],
          ['Kopi', '111', '3'],
          ['Teh', '222', 'bukan angka'],
        ]),
      );

      expect(result.success, isTrue);
      expect(result.validCount, 1);
      expect(result.errorCount, 2);
      expect(result.errors.first.errors.first, contains('lebih dari sekali'));
    });
  });

  group('StockInController', () {
    late TestHarness harness;
    late StockInController controller;

    setUp(() {
      harness = TestHarness();
      controller = StockInController(
        harness.productRepository,
        ExcelStockService(),
        ExcelExportService(),
      );
    });

    tearDown(() => harness.dispose());

    test('menambahkan jumlah di berkas ke stok yang ada', () async {
      final id = await harness.productRepository.createProduct(
        makeProduct(barcode: '111', name: 'Kopi', stock: 10),
      );

      await controller.loadFile(
        _sheet([
          ['nama', 'barcode', 'stok'],
          ['Kopi', '111', '5'],
        ]),
        'stok.xlsx',
      );

      expect(controller.state.items, hasLength(1));
      expect(controller.state.items.first.resultStock, 15);

      final applied = await controller.apply();

      expect(applied, isTrue);
      final product = await harness.productRepository.getProductById(id);
      expect(product!.stock, 15);
      expect(controller.state.report!.applied, 1);
      expect(controller.state.report!.stockDelta, 5);
    });

    test('mode set stok baru menimpa stok sekarang', () async {
      final id = await harness.productRepository.createProduct(
        makeProduct(barcode: '111', name: 'Kopi', stock: 10),
      );

      await controller.loadFile(
        _sheet([
          ['nama', 'barcode', 'stok'],
          ['Kopi', '111', '4'],
        ]),
        'opname.xlsx',
      );
      controller.setMode(StockUpdateMode.replace);

      expect(controller.state.items.first.resultStock, 4);

      await controller.apply();
      final product = await harness.productRepository.getProductById(id);
      expect(product!.stock, 4);
      expect(controller.state.report!.stockDelta, -6);
    });

    test('mencocokkan produk lewat nama saat barcode kosong', () async {
      await harness.productRepository.createProduct(
        makeProduct(barcode: '111', name: 'Kopi Susu', stock: 2),
      );

      await controller.loadFile(
        _sheet([
          ['nama', 'stok'],
          ['kopi susu', '8'],
        ]),
        'stok.xlsx',
      );

      expect(controller.state.matchedItems, hasLength(1));
      expect(controller.state.items.first.resultStock, 10);
    });

    test('baris yang produknya tidak ada dilaporkan dan dilewati', () async {
      final id = await harness.productRepository.createProduct(
        makeProduct(barcode: '111', name: 'Kopi', stock: 3),
      );

      await controller.loadFile(
        _sheet([
          ['nama', 'barcode', 'stok'],
          ['Kopi', '111', '2'],
          ['Produk Asing', '999', '5'],
        ]),
        'stok.xlsx',
      );

      expect(controller.state.matchedItems, hasLength(1));
      expect(controller.state.unmatchedItems, hasLength(1));

      await controller.apply();

      expect(controller.state.report!.applied, 1);
      expect(controller.state.report!.notFound, 1);
      final product = await harness.productRepository.getProductById(id);
      expect(product!.stock, 5);
    });

    test('tidak bisa diterapkan kalau tidak ada produk yang cocok', () async {
      await controller.loadFile(
        _sheet([
          ['nama', 'barcode', 'stok'],
          ['Produk Asing', '999', '5'],
        ]),
        'stok.xlsx',
      );

      expect(controller.state.canApply, isFalse);
      expect(await controller.apply(), isFalse);
    });

    test('berkas hasil ekspor produk bisa dibaca kembali', () async {
      await harness.productRepository.createProduct(
        makeProduct(barcode: '111', name: 'Kopi', stock: 7),
      );
      await harness.productRepository.createProduct(
        makeProduct(barcode: '222', name: 'Teh', stock: 0),
      );

      final products = await harness.productRepository.getAllProducts();
      final exported = ExcelExportService().exportProducts(products);
      final result = ExcelStockService().parseFromBytes(exported);

      expect(result.success, isTrue);
      expect(result.validCount, 2);
      final quantities = {
        for (final row in result.rows) row.barcode: row.quantity,
      };
      expect(quantities['111'], 7);
      expect(quantities['222'], 0);
    });
  });
}

/// Menyusun berkas .xlsx sederhana untuk keperluan test.
Uint8List _sheet(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel[excel.tables.keys.first];
  for (final row in rows) {
    sheet.appendRow(row.map<CellValue?>(TextCellValue.new).toList());
  }
  return Uint8List.fromList(excel.encode()!);
}
