import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/cart_controller.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/transaction_controller.dart';

import '../helpers/test_database.dart';

void main() {
  late TestHarness harness;
  late CartController cart;
  late TransactionController transaction;

  setUp(() {
    harness = TestHarness();
    cart = CartController(harness.productRepository);
    transaction = TransactionController(
      harness.transactionRepository,
      cart,
      persistReceipt: (id, bytes) async {
        final file = File('${Directory.systemTemp.path}/kasir_test_receipt_$id.pdf');
        await file.writeAsBytes(bytes);
        return file.path;
      },
    );
  });

  tearDown(() => harness.dispose());

  test('keranjang menghitung jumlah item dan subtotal', () async {
    final id = await harness.productRepository
        .createProduct(makeProduct(barcode: 'K1', price: 15000, stock: 10));
    final product = (await harness.productRepository.getProductById(id))!;

    cart.addProduct(product);
    cart.addProduct(product);
    cart.incrementQuantity(product.id);

    expect(cart.state.items.length, 1);
    expect(cart.state.items.first.quantity, 3);
    expect(cart.state.totalItems, 3);
    expect(cart.state.subtotal, 45000);

    cart.decrementQuantity(product.id);
    expect(cart.state.items.first.quantity, 2);

    cart.removeProduct(product.id);
    expect(cart.state.isEmpty, isTrue);
  });

  test('pembayaran menyimpan transaksi, item, dan struk PDF', () async {
    final id = await harness.productRepository
        .createProduct(makeProduct(barcode: 'K2', name: 'Teh', price: 8000, stock: 5));
    final product = (await harness.productRepository.getProductById(id))!;

    cart.addProduct(product, quantity: 2);
    transaction.setPaidAmount('20000');

    expect(transaction.isPaymentValid, isTrue);
    expect(transaction.changeAmount, 4000);

    final transactionId = await transaction.processPayment();
    expect(transactionId, isNotNull);

    final saved = await harness.transactionRepository.getTransactionById(transactionId!);
    expect(saved, isNotNull);
    expect(saved!.transaction.totalPrice, 16000);
    expect(saved.transaction.paidAmount, 20000);
    expect(saved.transaction.changeAmount, 4000);
    expect(saved.items.single.productName, 'Teh');
    expect(saved.items.single.qty, 2);
    expect(saved.items.single.unitPrice, 8000);

    final pdfPath = saved.transaction.pdfPath;
    expect(pdfPath, isNotNull);
    expect(File(pdfPath!).existsSync(), isTrue);

    expect(cart.state.isEmpty, isTrue);
    expect(await harness.transactionRepository.getTransactionsCount(), 1);
    expect(await harness.transactionRepository.getTotalSales(), 16000);
  });

  test('pembayaran ditolak bila uang kurang', () async {
    final id = await harness.productRepository
        .createProduct(makeProduct(barcode: 'K3', price: 10000, stock: 5));
    final product = (await harness.productRepository.getProductById(id))!;

    cart.addProduct(product);
    transaction.setPaidAmount('5000');

    expect(transaction.isPaymentValid, isFalse);
    expect(await transaction.processPayment(), isNull);
    expect(transaction.state.error, isNotNull);
    expect(await harness.transactionRepository.getTransactionsCount(), 0);
  });

  test('transaksi tetap tersimpan bila struk tidak bisa dipersistensi', () async {
    // Kondisi ini yang terjadi di web: tidak ada filesystem, jadi penyimpanan
    // struk mengembalikan null dan tidak boleh membatalkan transaksi.
    final controller = TransactionController(
      harness.transactionRepository,
      cart,
      persistReceipt: (id, bytes) async => null,
    );

    final id = await harness.productRepository
        .createProduct(makeProduct(barcode: 'K5', price: 5000, stock: 3));
    final product = (await harness.productRepository.getProductById(id))!;

    cart.addProduct(product);
    controller.setPaidAmount('5000');

    final transactionId = await controller.processPayment();
    expect(transactionId, isNotNull);

    final saved = await harness.transactionRepository.getTransactionById(transactionId!);
    expect(saved, isNotNull);
    expect(saved!.transaction.pdfPath, isNull);
    expect(controller.state.error, isNull);
    expect(cart.state.isEmpty, isTrue);
  });

  test('pembayaran ditolak bila stok tidak mencukupi', () async {
    final id = await harness.productRepository
        .createProduct(makeProduct(barcode: 'K4', price: 10000, stock: 1));
    final product = (await harness.productRepository.getProductById(id))!;

    cart.addProduct(product, quantity: 5);
    transaction.setPaidAmount('100000');

    expect(await transaction.processPayment(), isNull);
    expect(transaction.state.error, isNotNull);
    expect(await harness.transactionRepository.getTransactionsCount(), 0);
  });
}
