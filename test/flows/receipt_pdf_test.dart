import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/datasources/pdf/receipt_pdf_generator.dart';
import 'package:kasir_pintar/data/models/transaction.dart';
import 'package:kasir_pintar/data/models/transaction_item.dart';

void main() {
  test('generate struk menghasilkan byte PDF valid', () async {
    final document = await ReceiptPdfGenerator().generate(
      transaction: Transaction(
        id: 7,
        date: DateTime(2026, 1, 2, 10, 30),
        totalPrice: 45000,
        paidAmount: 50000,
        changeAmount: 5000,
        pdfPath: null,
      ),
      items: [
        TransactionItem(
          id: 1,
          transactionId: 7,
          productId: 1,
          productName: 'Kopi Susu',
          qty: 3,
          unitPrice: 15000,
          subtotal: 45000,
        ),
      ],
    );

    final bytes = await document.save();

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
