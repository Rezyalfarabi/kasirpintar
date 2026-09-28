import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/data/models/transaction.dart';
import 'package:kasir_pintar/data/models/transaction_item.dart';
import 'package:kasir_pintar/data/repositories/transaction_repository.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/cart_controller.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/core/errors/exception_handler.dart';
import 'package:kasir_pintar/core/errors/failures.dart';
import 'package:kasir_pintar/data/datasources/pdf/receipt_pdf_generator.dart';
import 'package:kasir_pintar/core/utils/platform_files.dart';
import 'dart:typed_data';

class TransactionState {
  final String paidAmount;
  final bool isProcessing;
  final String? error;

  TransactionState({
    this.paidAmount = '',
    this.isProcessing = false,
    this.error,
  });

  TransactionState copyWith({
    String? paidAmount,
    bool? isProcessing,
    String? error,
  }) {
    return TransactionState(
      paidAmount: paidAmount ?? this.paidAmount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class TransactionController extends StateNotifier<TransactionState> {
  final TransactionRepository _transactionRepository;
  final CartController _cartController;
  final Future<String?> Function(int transactionId, Uint8List bytes) _persistReceipt;

  TransactionController(
    this._transactionRepository,
    this._cartController, {
    Future<String?> Function(int transactionId, Uint8List bytes)? persistReceipt,
  })  : _persistReceipt = persistReceipt ?? persistReceiptPdf,
        super(TransactionState());

  int get changeAmount {
    final paid = CurrencyFormat.parse(state.paidAmount);
    final subtotal = _cartController.state.subtotal;
    return paid - subtotal;
  }

  bool get isPaymentValid {
    final paid = CurrencyFormat.parse(state.paidAmount);
    return paid >= _cartController.state.subtotal;
  }

  void setPaidAmount(String amount) {
    state = state.copyWith(paidAmount: amount, error: null);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Menyimpan transaksi + struk PDF. Mengembalikan id transaksi, atau `null`
  /// bila pembayaran gagal. Navigasi ditangani lapisan UI.
  Future<int?> processPayment() async {
    if (!isPaymentValid) {
      state = state.copyWith(error: 'Uang bayar kurang dari total');
      return null;
    }

    final hasStock = await _cartController.validateStock();
    if (!hasStock) {
      state = state.copyWith(error: 'Stok tidak mencukupi untuk beberapa produk');
      return null;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final subtotal = _cartController.state.subtotal;
      final paid = CurrencyFormat.parse(state.paidAmount);
      final change = paid - subtotal;

      final transaction = Transaction(
        id: 0,
        date: DateTime.now(),
        totalPrice: subtotal,
        paidAmount: paid,
        changeAmount: change,
        pdfPath: null,
      );

      final items = _cartController.state.items.map((cartItem) => TransactionItem(
        id: 0,
        transactionId: 0,
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        qty: cartItem.quantity,
        unitPrice: cartItem.product.price,
        subtotal: cartItem.subtotal,
      ),).toList();

      final transactionId = await _transactionRepository.createTransaction(transaction, items);

      // Generate and save PDF
      final pdfGenerator = ReceiptPdfGenerator();
      final pdf = await pdfGenerator.generate(
        transaction: Transaction(
          id: transactionId,
          date: DateTime.now(),
          totalPrice: subtotal,
          paidAmount: paid,
          changeAmount: paid - subtotal,
          pdfPath: null,
        ),
        items: _cartController.state.items.map((cartItem) => TransactionItem(
          id: 0,
          transactionId: transactionId,
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          qty: cartItem.quantity,
          unitPrice: cartItem.product.price,
          subtotal: cartItem.subtotal,
        ),).toList(),
      );

      // Struk hanya dipersistensi bila platform punya filesystem. Di web kolom
      // pdfPath dibiarkan null karena halaman struk membuat ulang PDF-nya.
      // Kegagalan menulis struk tidak boleh membatalkan transaksi yang sudah sah.
      try {
        final pdfPath = await _persistReceipt(transactionId, await pdf.save());
        if (pdfPath != null) {
          await _transactionRepository.updatePdfPath(transactionId, pdfPath);
        }
      } catch (_) {
        // Diabaikan: transaksi tetap tersimpan dan struk bisa dicetak dari riwayat.
      }

      _cartController.clear();
      state = TransactionState();
      return transactionId;
    } catch (e, st) {
      state = state.copyWith(isProcessing: false, error: ExceptionHandler.handleError(e, st).userMessage);
      return null;
    }
  }

  void reset() {
    state = TransactionState();
  }
}