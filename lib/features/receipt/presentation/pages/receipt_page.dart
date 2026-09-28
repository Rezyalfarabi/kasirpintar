import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/utils/platform_files.dart';
import 'package:kasir_pintar/data/datasources/pdf/receipt_pdf_generator.dart';

/// Lebar visual struk, dibuat menyempit supaya terbaca seperti kertas struk
/// asli meskipun jendela browser lebar.
const double _receiptPaperWidth = 340;

class ReceiptPage extends ConsumerStatefulWidget {
  final int transactionId;

  const ReceiptPage({super.key, required this.transactionId});

  @override
  ConsumerState<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends ConsumerState<ReceiptPage> {
  pw.Document? _pdfDocument;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final controller = ref.read(transactionRepositoryProvider);
    final transactionWithItems = await controller.getTransactionById(widget.transactionId);

    if (transactionWithItems != null) {
      final pdf = await ReceiptPdfGenerator().generate(
        transaction: transactionWithItems.transaction,
        items: transactionWithItems.items,
      );
      if (!mounted) return;
      setState(() {
        _pdfDocument = pdf;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBarWidget(title: 'Struk #${widget.transactionId}'),
      body: _pdfDocument == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildPreview()),
                _buildActions(),
              ],
            ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Container(
          width: _receiptPaperWidth,
          decoration: BoxDecoration(
            color: AppColors.baseWhite,
            border: Border.all(color: AppColors.borderLight, width: 1),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: PdfPreview(
            build: (format) => _pdfDocument!.save(),
            pdfFileName: 'struk_${widget.transactionId}.pdf',
            // Toolbar bawaan dimatikan supaya aksi struk memakai gaya aplikasi
            // sendiri, bukan tampilan bawaan paket.
            useActions: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowPrinting: false,
            allowSharing: false,
            padding: EdgeInsets.zero,
            initialPageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Cetak',
              leadingIcon: Icons.print_outlined,
              onPressed: _printPdf,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SecondaryButton(
              label: 'Bagikan',
              leadingIcon: Icons.ios_share,
              onPressed: _sharePdf,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SecondaryButton(
              label: 'Simpan',
              leadingIcon: Icons.download_outlined,
              onPressed: _savePdf,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf() async {
    if (_pdfDocument == null) return;
    await Printing.layoutPdf(
      onLayout: (format) => _pdfDocument!.save(),
      name: 'struk_${widget.transactionId}.pdf',
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfDocument == null) return;
    // Printing.sharePdf dipakai karena didukung web maupun native, jadi tidak
    // perlu menulis berkas sementara di disk.
    await Printing.sharePdf(
      bytes: await _pdfDocument!.save(),
      filename: 'struk_${widget.transactionId}.pdf',
    );
  }

  Future<void> _savePdf() async {
    if (_pdfDocument == null) return;
    final bytes = await _pdfDocument!.save();
    final saved = await saveBytesToDocuments(
      bytes,
      'struk_${widget.transactionId}.pdf',
      mimeType: 'application/pdf',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved ? 'Struk PDF disimpan' : 'Gagal menyimpan struk PDF')),
      );
    }
  }
}
