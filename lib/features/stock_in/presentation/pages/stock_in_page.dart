import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_stock_service.dart';
import 'package:kasir_pintar/features/product/presentation/controllers/product_list_controller.dart';
import 'package:kasir_pintar/features/stock_in/presentation/controllers/stock_in_controller.dart';

/// Menambah stok massal dari berkas Excel yang sudah berisi daftar produk.
///
/// Alurnya sengaja tiga langkah — unduh daftar, sunting kolom stok, unggah —
/// karena operator biasanya sudah punya catatan barang masuk, bukan berkas
/// dengan format aplikasi.
class StockInPage extends ConsumerWidget {
  const StockInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockInControllerProvider);
    final controller = ref.read(stockInControllerProvider.notifier);

    return ResponsiveScaffold(
      appBar: AppBarWidget(
        title: 'Tambah Stok',
        actions: [
          if (state.hasFile)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Pilih berkas lain',
              onPressed: state.isApplying ? null : controller.clearFile,
            ),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.error != null) ...[
            _ErrorBanner(message: state.error!, onDismiss: controller.clearError),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (state.report != null)
            _ResultSection(state: state, controller: controller)
          else if (state.hasFile)
            _PreviewSection(state: state, controller: controller)
          else
            _PickerSection(state: state, controller: controller),
        ],
      ),
    );
  }
}

class _PickerSection extends ConsumerWidget {
  final StockInState state;
  final StockInController controller;

  const _PickerSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepLabel(number: '1', title: 'Siapkan berkas'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Unduh daftar produk, isi kolom stok dengan jumlah barang masuk, '
          'lalu unggah kembali berkas itu.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Unduh Daftar Produk (.xlsx)',
          leadingIcon: Icons.file_download_outlined,
          isLoading: state.isDownloading,
          onPressed: state.isDownloading ? null : () => _download(context, ref, controller),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'Unduh Template Kosong',
          leadingIcon: Icons.description_outlined,
          onPressed: state.isDownloading ? null : () => _downloadTemplate(context, controller),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _StepLabel(number: '2', title: 'Pilih berkas'),
        const SizedBox(height: AppSpacing.md),
        _FileDropZone(
          fileName: state.fileName,
          isBusy: state.isParsing,
          onTap: state.isParsing ? null : () => _pickFile(context, ref),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.push('/stock-history'),
          child: const Text('Lihat riwayat perubahan stok'),
        ),
        TextButton(
          onPressed: () => context.push('/excel-import'),
          child: const Text('Berkas ini berisi produk baru, bukan stok? Impor produk'),
        ),
      ],
    );
  }
}

class _PreviewSection extends ConsumerWidget {
  final StockInState state;
  final StockInController controller;

  const _PreviewSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantityColumn = state.quantityColumn ?? 'stok';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FileChip(
          fileName: state.fileName ?? '',
          meta: '${state.items.length} baris dibaca • kolom jumlah: "$quantityColumn"',
          onReplace: state.isApplying ? null : controller.clearFile,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _StepLabel(number: '3', title: 'Cara membaca kolom jumlah'),
        const SizedBox(height: AppSpacing.sm),
        SegmentedControl<StockUpdateMode>(
          segments: const [
            Segment(value: StockUpdateMode.add, label: 'Tambah ke stok'),
            Segment(value: StockUpdateMode.replace, label: 'Set stok baru'),
          ],
          selectedValue: state.mode,
          onChanged: controller.setMode,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          state.mode == StockUpdateMode.add
              ? 'Angka di kolom "$quantityColumn" ditambahkan ke stok sekarang. '
                  'Cocok untuk barang masuk.'
              : 'Angka di kolom "$quantityColumn" dipakai sebagai stok akhir, '
                  'menimpa stok sekarang. Cocok untuk hasil stok opname.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'PRODUK COCOK',
                value: '${state.matchedItems.length}',
                tone: AppColors.successLine,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                label: 'TIDAK DITEMUKAN',
                value: '${state.unmatchedItems.length}',
                tone: state.unmatchedItems.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.dangerLine,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                label: 'BARIS ERROR',
                value: '${state.parseErrors.length}',
                tone: state.parseErrors.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.dangerLine,
              ),
            ),
          ],
        ),
        if (state.parseErrors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _RowErrorPanel(errors: state.parseErrors),
        ],
        const SizedBox(height: AppSpacing.lg),
        _PreviewTable(state: state),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Terapkan ke ${state.matchedItems.length} Produk',
          leadingIcon: Icons.check,
          isLoading: state.isApplying,
          onPressed: state.canApply ? () => _apply(context, ref, controller) : null,
        ),
        if (state.matchedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Tidak ada produk di berkas yang cocok dengan database. '
              'Periksa kolom barcode/nama, atau impor produknya dulu.',
              style: AppTextStyles.caption.copyWith(color: AppColors.dangerLine),
            ),
          )
        else if (state.unmatchedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '${state.unmatchedItems.length} baris yang produknya belum terdaftar '
              'akan dilewati.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _ResultSection extends ConsumerWidget {
  final StockInState state;
  final StockInController controller;

  const _ResultSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = state.report!;
    final isAdd = state.mode == StockUpdateMode.add;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            border: Border.all(
              color: report.applied > 0 ? AppColors.successLine : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    report.applied > 0 ? Icons.check_circle_outline : Icons.info_outline,
                    color: report.applied > 0 ? AppColors.successLine : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    report.applied > 0 ? 'Stok sudah diperbarui' : 'Tidak ada stok yang berubah',
                    style: AppTextStyles.heading,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ResultRow(label: 'Produk diperbarui', value: '${report.applied}'),
              if (isAdd)
                _ResultRow(
                  label: 'Stok bertambah',
                  value: '${report.stockDelta > 0 ? '+' : ''}${report.stockDelta} unit',
                ),
              if (report.notFound > 0)
                _ResultRow(label: 'Baris tidak ditemukan', value: '${report.notFound}'),
              if (report.failed > 0)
                _ResultRow(label: 'Gagal disimpan', value: '${report.failed}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Unggah Berkas Lain',
          leadingIcon: Icons.upload_file,
          onPressed: controller.clearFile,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'Lihat Riwayat Stok',
          leadingIcon: Icons.history,
          onPressed: () => context.push('/stock-history'),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'Lihat Daftar Produk',
          leadingIcon: Icons.inventory_2_outlined,
          onPressed: () => context.go('/products'),
        ),
      ],
    );
  }
}

class _PreviewTable extends StatelessWidget {
  final StockInState state;

  const _PreviewTable({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.offWhite),
        headingTextStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
        columnSpacing: AppSpacing.xl,
        columns: const [
          DataColumn(label: Text('PRODUK')),
          DataColumn(label: Text('BARCODE')),
          DataColumn(label: Text('STOK SISTEM'), numeric: true),
          DataColumn(label: Text('PERUBAHAN'), numeric: true),
          DataColumn(label: Text('STOK AKHIR'), numeric: true),
        ],
        rows: [
          for (final item in state.items)
            DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.product?.name ?? item.row.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isMatched) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const StatusBadge(label: 'BARU', type: BadgeType.danger),
                        ],
                      ],
                    ),
                  ),
                ),
                DataCell(Text(item.row.barcode.isEmpty ? '—' : item.row.barcode)),
                DataCell(Text(item.isMatched ? '${item.currentStock}' : '—')),
                DataCell(
                  Text(
                    item.isMatched
                        ? '${item.delta > 0 ? '+' : ''}${item.delta}'
                        : '+${item.row.quantity}',
                    style: TextStyle(
                      color: item.isMatched ? AppColors.successLine : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(item.isMatched ? '${item.resultStock}' : '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String title;

  const _StepLabel({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentYellow,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AppTextStyles.badge.copyWith(color: AppColors.textOnYellow),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.subheading),
      ],
    );
  }
}

class _FileDropZone extends StatelessWidget {
  final String? fileName;
  final bool isBusy;
  final VoidCallback? onTap;

  const _FileDropZone({this.fileName, this.isBusy = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isBusy ? AppColors.offWhite : AppColors.baseWhite,
          border: Border.all(
            color: isBusy ? AppColors.disabled : AppColors.borderDark,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 40,
              color: isBusy ? AppColors.disabled : AppColors.textPrimary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isBusy ? 'Membaca berkas...' : 'Ketuk untuk memilih berkas .xlsx',
              style: AppTextStyles.body.copyWith(
                color: isBusy ? AppColors.disabled : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kolom yang dikenali: barcode/nama dan stok/jumlah',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final String fileName;
  final String meta;
  final VoidCallback? onReplace;

  const _FileChip({required this.fileName, required this.meta, this.onReplace});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart_outlined, size: AppSpacing.iconSize),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: AppTextStyles.subheading, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(meta, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (onReplace != null)
            TextButton(onPressed: onReplace, child: const Text('Ganti')),
        ],
      ),
    );
  }
}

class _RowErrorPanel extends StatelessWidget {
  final List<StockSheetError> errors;

  const _RowErrorPanel({required this.errors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerLine.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.dangerLine),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Baris yang dilewati:',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.dangerLine,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final error in errors)
            Text(
              'Baris ${error.row}: ${error.errors.join(', ')}',
              style: AppTextStyles.caption.copyWith(color: AppColors.dangerLine),
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.price.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerLine.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.dangerLine),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.dangerLine),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.dangerLine),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.dangerLine),
            onPressed: onDismiss,
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }
}

Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
  // withData wajib di web: PlatformFile.path selalu null di sana.
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) return;

  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi berkas tidak bisa dibaca')),
      );
    }
    return;
  }

  await ref.read(stockInControllerProvider.notifier).loadFile(bytes, file.name);
}

Future<void> _apply(
  BuildContext context,
  WidgetRef ref,
  StockInController controller,
) async {
  final success = await controller.apply();
  if (!context.mounted) return;

  if (success) {
    // Daftar produk memegang stok hasil query lama, jadi dimuat ulang supaya
    // angka di layar ikut berubah.
    ref.invalidate(productListControllerProvider);
  }

  final report = ref.read(stockInControllerProvider).report;
  if (report == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak ada baris yang bisa diterapkan')),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        report.applied > 0
            ? '${report.applied} produk diperbarui'
            : 'Tidak ada stok yang berubah',
      ),
    ),
  );
}

Future<void> _download(
  BuildContext context,
  WidgetRef ref,
  StockInController controller,
) async {
  final saved = await controller.downloadProductSheet();
  if (!context.mounted) return;
  final error = ref.read(stockInControllerProvider).error;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        saved
            ? 'Daftar produk diunduh. Sunting kolom stok lalu unggah kembali.'
            : error ?? 'Gagal mengunduh daftar produk',
      ),
    ),
  );
}

Future<void> _downloadTemplate(
  BuildContext context,
  StockInController controller,
) async {
  final saved = await controller.downloadTemplate();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(saved ? 'Template diunduh' : 'Gagal mengunduh template'),
    ),
  );
}
