import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/features/excel_import/presentation/controllers/excel_import_controller.dart';

class ExcelImportPage extends ConsumerStatefulWidget {
  const ExcelImportPage({super.key});

  @override
  ConsumerState<ExcelImportPage> createState() => _ExcelImportPageState();
}

class _ExcelImportPageState extends ConsumerState<ExcelImportPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(excelImportControllerProvider);
    final controller = ref.read(excelImportControllerProvider.notifier);

    return ResponsiveScaffold(
      appBar: const AppBarWidget(title: 'Import Excel'),
      bottomNavigationBar: const AppNavigationBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.dangerLine.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.dangerLine),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.dangerLine),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(state.error!, style: AppTextStyles.body.copyWith(color: AppColors.dangerLine))),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.dangerLine),
                      onPressed: controller.clear,
                    ),
                  ],
                ),
              ),

            if (state.result == null) ...[
              _buildFilePicker(state, controller),
              const SizedBox(height: AppSpacing.lg),
              _buildTemplateDownload(state, controller),
            ] else ...[
              _buildPreview(state),
              const SizedBox(height: AppSpacing.lg),
              _buildImportOptions(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(ExcelImportState state, ExcelImportController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih File Excel', style: AppTextStyles.subheading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Format: .xlsx dengan kolom: nama, barcode, harga, stok, kategori',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: state.isLoading ? null : _pickFile,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(
                color: state.isLoading ? AppColors.disabled : AppColors.borderLight,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: state.isLoading ? AppColors.offWhite : AppColors.baseWhite,
            ),
            child: Column(
              children: [
                // Ikon unggah sengaja bukan kuning: kuning dipakai untuk satu
                // aksi utama saja per layar.
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: state.isLoading ? AppColors.disabled : AppColors.textPrimary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.fileName != null
                      ? 'Berkas dipilih: ${state.fileName}'
                      : 'Ketuk untuk memilih berkas .xlsx',
                  style: AppTextStyles.body.copyWith(
                    color: state.isLoading ? AppColors.disabled : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state.isLoading) ...[
                  const SizedBox(height: AppSpacing.md),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateDownload(ExcelImportState state, ExcelImportController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Template Excel', style: AppTextStyles.subheading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Unduh template untuk memastikan format kolom benar',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Unduh Template',
          onPressed: state.isLoading ? null : () => _downloadTemplate(controller),
          leadingIcon: Icons.download,
          isLoading: state.isLoading,
        ),
      ],
    );
  }

  Widget _buildPreview(ExcelImportState state) {
    final result = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Data (${result.validCount} valid, ${result.errorCount} error)',
          style: AppTextStyles.subheading,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (result.errors.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dangerLine.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.dangerLine),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Baris dengan error:', style: AppTextStyles.caption.copyWith(color: AppColors.dangerLine, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                ...result.errors.map((e) => Text(
                  'Baris ${e.row}: ${e.errors.join(', ')}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.dangerLine),
                ),),
              ],
            ),
          ),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.offWhite),
            headingTextStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.accentYellow.withValues(alpha: 0.2);
              return null;
            }),
            columns: const [
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Barcode')),
              DataColumn(label: Text('Harga'), numeric: true),
              DataColumn(label: Text('Stok'), numeric: true),
              DataColumn(label: Text('Kategori')),
            ],
            rows: state.result!.rows.map((row) {
              final hasError = state.result!.errors.any((e) => e.data.barcode == row.barcode);
              return DataRow(
                color: hasError ? WidgetStateProperty.all(AppColors.dangerLine.withValues(alpha: 0.1)) : null,
                cells: [
                  DataCell(Text(row.name)),
                  DataCell(Text(row.barcode)),
                  DataCell(Text(CurrencyFormat.format(row.price))),
                  DataCell(Text(row.stock.toString())),
                  DataCell(Text(row.category ?? '-')),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildImportOptions(ExcelImportState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Lewati Duplikat',
                onPressed: state.isImporting ? null : () => _importWithSkip(state),
                isLoading: state.isImporting,
                leadingIcon: Icons.skip_next,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                // Jumlah produk ikut ditulis supaya jelas apa yang akan terjadi.
                label: 'Impor ${state.result?.validCount ?? 0} Produk',
                onPressed: state.isImporting ? null : () => _importWithUpdate(state),
                isLoading: state.isImporting,
                leadingIcon: Icons.check,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.result?.errors.isNotEmpty == true)
          Text(
            'Baris dengan error akan dilewati',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Future<void> _pickFile() async {
    // withData wajib di web: di sana PlatformFile.path selalu null dan hanya
    // byte berkas yang tersedia.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membaca isi berkas Excel')),
        );
      }
      return;
    }

    final controller = ref.read(excelImportControllerProvider.notifier);
    controller.setSelectedFile(bytes, file.name);
    await controller.parseFile();
  }

  Future<void> _downloadTemplate(ExcelImportController controller) async {
    final saved = await controller.downloadTemplate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved ? 'Template berhasil diunduh' : 'Gagal mengunduh template')),
      );
    }
  }

  Future<void> _importWithSkip(ExcelImportState state) async {
    final success = await ref.read(excelImportControllerProvider.notifier).importValidRows();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Import berhasil' : 'Import gagal')),
      );
      if (success) {
        ref.read(excelImportControllerProvider.notifier).clear();
      }
    }
  }

  Future<void> _importWithUpdate(ExcelImportState state) async {
    final success = await ref.read(excelImportControllerProvider.notifier).importWithUpdateDuplicates();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Import & update berhasil' : 'Import gagal')),
      );
      if (success) {
        ref.read(excelImportControllerProvider.notifier).clear();
      }
    }
  }
}