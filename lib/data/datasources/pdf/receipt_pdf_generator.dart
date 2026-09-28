import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';
import 'package:kasir_pintar/core/constants/receipt_config.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/data/models/transaction.dart';
import 'package:kasir_pintar/data/models/transaction_item.dart';

class ReceiptPdfGenerator {
  static const double pageWidth = 58 * PdfPageFormat.mm;
  static const double margin = 4 * PdfPageFormat.mm;

  Future<pw.Document> generate({
    required Transaction transaction,
    required List<TransactionItem> items,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? footerText,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(pageWidth, double.infinity, marginAll: margin),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(storeName, storeAddress, storePhone),
            pw.SizedBox(height: 8),
            _buildDivider(),
            pw.SizedBox(height: 8),
            _buildTransactionInfo(transaction),
            pw.SizedBox(height: 8),
            _buildDivider(),
            pw.SizedBox(height: 8),
            _buildItemsTable(items),
            pw.SizedBox(height: 8),
            _buildDivider(),
            pw.SizedBox(height: 8),
            _buildTotals(transaction),
            pw.SizedBox(height: 8),
            _buildPaymentInfo(transaction),
            pw.SizedBox(height: 12),
            _buildDivider(),
            pw.SizedBox(height: 8),
            _buildFooter(footerText),
          ],
        ),
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String? storeName, String? storeAddress, String? storePhone) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          storeName ?? ReceiptConfig.storeName,
          style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 14),
        ),
        if (storeAddress != null || ReceiptConfig.storeAddress.isNotEmpty)
          pw.Text(
            storeAddress ?? ReceiptConfig.storeAddress,
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
          ),
        if (storePhone != null || ReceiptConfig.storePhone.isNotEmpty)
          pw.Text(
            storePhone ?? ReceiptConfig.storePhone,
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
          ),
      ],
    );
  }

  pw.Widget _buildDivider() {
    return pw.Container(
      height: 1,
      color: PdfColors.black,
    );
  }

  pw.Widget _buildTransactionInfo(Transaction transaction) {
    final dateFormat = DateFormat(AppConstants.receiptDateFormat);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'No: ${transaction.id.toString().padLeft(6, '0')}',
          style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
        ),
        pw.Text(
          dateFormat.format(transaction.date),
          style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<TransactionItem> items) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text('ITEM', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('QTY', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9), textAlign: pw.TextAlign.center),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('HARGA', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9), textAlign: pw.TextAlign.right),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('TOTAL', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        ...items.map(_buildItemRow),
      ],
    );
  }

  pw.Widget _buildItemRow(TransactionItem item) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                item.productName,
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                item.qty.toString(),
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                CurrencyFormat.format(item.unitPrice),
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                CurrencyFormat.format(item.subtotal),
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
      ],
    );
  }

  pw.Widget _buildTotals(Transaction transaction) {
    return pw.Column(
      children: [
        _buildTotalRow('Subtotal', CurrencyFormat.format(transaction.totalPrice), false),
        _buildTotalRow('TOTAL', CurrencyFormat.format(transaction.totalPrice), true),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String amount, bool isTotal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: isTotal ? pw.Font.helveticaBold() : pw.Font.helvetica(),
            fontSize: isTotal ? 12 : 10,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            font: isTotal ? pw.Font.helveticaBold() : pw.Font.helvetica(),
            fontSize: isTotal ? 12 : 10,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPaymentInfo(Transaction transaction) {
    return pw.Column(
      children: [
        _buildPaymentRow('Bayar', CurrencyFormat.format(transaction.paidAmount)),
        _buildPaymentRow('Kembalian', CurrencyFormat.format(transaction.changeAmount)),
      ],
    );
  }

  pw.Widget _buildPaymentRow(String label, String amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10)),
        pw.Text(amount, style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildFooter(String? footerText) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          footerText ?? ReceiptConfig.footerText,
          style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '--- Barcode: ${DateTime.now().millisecondsSinceEpoch} ---',
          style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
        ),
      ],
    );
  }
}