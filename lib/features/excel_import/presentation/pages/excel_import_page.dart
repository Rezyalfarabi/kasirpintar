import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';
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
      appBar: const AppBarWidget(title: 'Upload Excel Produk'),
      bottomNavigationBar: const AppNavigationBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.error != null) ...[
              _buildErrorBanner(state.error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (state.outcome != null) ...[
              _buildOutcome(state.outcome!),
              const SizedBox(height: AppSpacing.lg),
            ] else if (state.result == null) ...[
              _buildUploadZone(state, controller),
              const SizedBox(height: AppSpacing.lg),
              _buildRules(controller),
            ] else ...[
              _buildSummary(state),
              const SizedBox(height: AppSpacing.lg),
              _buildAccepted(state),
              const SizedBox(height: AppSpacing.lg),
              _buildRejected(state),
              const SizedBox(height: AppSpacing.lg),
              _buildImportOptions(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerLine.withValues(alpha: 0.1),
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
            onPressed: () => ref.read(excelImportControllerProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }

  /// Rekap setelah impor. Ada tombol ke daftar produk supaya operator bisa
  /// langsung memverifikasi bahwa produknya benar-benar sudah masuk.
  Widget _buildOutcome(ImportOutcome outcome) {
    final nothing = outcome.touched == 0;
    final color = nothing ? AppColors.dangerLine : AppColors.successLine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                nothing ? Icons.warning_amber_outlined : Icons.check_circle_outline,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  nothing
                      ? 'Tidak ada produk yang ditambahkan'
                      : '${outcome.touched} produk sudah masuk daftar',
                  style: AppTextStyles.subheading.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildOutcomeRow('Produk baru', outcome.added),
          _buildOutcomeRow('Produk diperbarui', outcome.updated),
          _buildOutcomeRow('Dilewati karena duplikat', outcome.skipped),
          _buildOutcomeRow('Baris ditolak', outcome.rejected),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Lihat Daftar Produk',
                  leadingIcon: Icons.inventory_2_outlined,
                  onPressed: () => context.go('/products'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SecondaryButton(
                  label: 'Upload Lagi',
                  leadingIcon: Icons.upload_file,
                  onPressed: () => ref.read(excelImportControllerProvider.notifier).clear(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.caption),
          ),
          Text(
            '$count',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone(ExcelImportState state, ExcelImportController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload File Excel', style: AppTextStyles.subheading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Produk akan ditambahkan sesuai isi file, selama setiap baris '
          'memenuhi ketentuan produk di bawah.',
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
                  Icons.upload_file_outlined,
                  size: 48,
                  color: state.isLoading ? AppColors.disabled : AppColors.textPrimary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.fileName != null
                      ? 'Berkas dipilih: ${state.fileName}'
                      : 'Ketuk untuk mengunggah file .xlsx',
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

  /// Ketentuan produk diambil dari [AppConstants] dan `Validators`, jadi teks di
  /// layar ini tidak mungkin berbeda dengan yang benar-benar ditegakkan saat
  /// impor.
  Widget _buildRules(ExcelImportController controller) {
    final rules = <(String, String)>[
      ('Format', 'Berkas .xlsx, hanya sheet pertama yang dibaca'),
      ('Baris 1', 'Judul kolom. Nama kolom bebas huruf besar-kecil dan urutannya bebas'),
      (
        'nama',
        'Wajib diisi, maksimal ${AppConstants.maxNameLength} karakter',
      ),
      (
        'barcode',
        'Wajib diisi, maksimal ${AppConstants.maxBarcodeLength} karakter, '
        'harus unik',
      ),
      (
        'harga',
        'Bilangan bulat lebih dari 0, maksimal ${AppConstants.maxPrice}. '
        'Pemisah ribuan boleh: 15000, 15.000, atau 15,000',
      ),
      (
        'stok',
        'Tidak boleh negatif, maksimal ${AppConstants.maxStock}. Boleh nol',
      ),
      (
        'kategori',
        'Boleh dikosongkan, maksimal ${AppConstants.maxCategoryLength} karakter',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ketentuan Produk', style: AppTextStyles.subheading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Baris yang tidak memenuhi ketentuan ini akan ditolak dan disebut '
          'alasannya, bukan dilewati diam-diam.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              for (final (i, rule) in rules.indexed)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(top: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          rule.$1,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(rule.$2, style: AppTextStyles.caption),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Unduh Template',
          onPressed: controller.downloadTemplate,
          leadingIcon: Icons.download,
        ),
      ],
    );
  }

  Widget _buildSummary(ExcelImportState state) {
    final result = state.result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hasil dari ${state.fileName}',
                style: AppTextStyles.subheading,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StatusBadge(
              label: '${result.validCount} siap',
              type: result.validCount > 0 ? BadgeType.success : BadgeType.danger,
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(
              label: '${result.errorCount} ditolak',
              type: result.errorCount > 0 ? BadgeType.danger : BadgeType.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                'Periksa tabel di bawah sebelum menekan tombol tambah.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(excelImportControllerProvider.notifier).clear(),
              child: const Text('Ganti file'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccepted(ExcelImportState state) {
    final rows = state.result!.rows;
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Text(
          'Tidak ada baris yang lolos ketentuan. Perbaiki file lalu unggah lagi.',
          style: AppTextStyles.caption.copyWith(color: AppColors.dangerLine),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produk yang akan ditambahkan (${rows.length})',
          style: AppTextStyles.subheading,
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.offWhite),
            headingTextStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
            columns: const [
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Barcode')),
              DataColumn(label: Text('Harga'), numeric: true),
              DataColumn(label: Text('Stok'), numeric: true),
              DataColumn(label: Text('Kategori')),
            ],
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: [
                      DataCell(Text(row.name)),
                      DataCell(Text(row.barcode)),
                      DataCell(Text(CurrencyFormat.format(row.price))),
                      DataCell(Text(row.stock.toString())),
                      DataCell(Text(row.category ?? '-')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRejected(ExcelImportState state) {
    final errors = state.result!.errors;
    if (errors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Baris ditolak (${errors.length})', style: AppTextStyles.subheading),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.dangerLine.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.dangerLine),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              for (final (i, error) in errors.indexed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(top: BorderSide(color: AppColors.dangerLine)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Baris ${error.row} · ${error.errors.join(', ')}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.dangerLine,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (error.data.name.isNotEmpty || error.data.barcode.isNotEmpty)
                        Text(
                          '${error.data.name.isEmpty ? '(tanpa nama)' : error.data.name}'
                          '${error.data.barcode.isEmpty ? '' : ' · ${error.data.barcode}'}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportOptions(ExcelImportState state) {
    final validCount = state.result?.validCount ?? 0;
    final canImport = validCount > 0 && !state.isImporting;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Lewati Duplikat',
                onPressed: canImport ? () => _import(updateExisting: false) : null,
                isLoading: state.isImporting,
                leadingIcon: Icons.skip_next,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                // Jumlah produk ikut ditulis supaya jelas apa yang akan terjadi.
                label: 'Tambah $validCount Produk',
                onPressed: canImport ? () => _import(updateExisting: true) : null,
                isLoading: state.isImporting,
                leadingIcon: Icons.add,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tambah memperbarui produk lama yang barcode-nya sama. Lewati '
          'Duplikat membiarkannya apa adanya.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
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
          const SnackBar(content: Text('Gagal membaca isi file Excel')),
        );
      }
      return;
    }

    final controller = ref.read(excelImportControllerProvider.notifier);
    controller.setSelectedFile(bytes, file.name);
    await controller.parseFile();
  }

  Future<void> _import({required bool updateExisting}) async {
    final controller = ref.read(excelImportControllerProvider.notifier);
    final outcome = updateExisting
        ? await controller.importWithUpdateDuplicates()
        : await controller.importValidRows();

    if (!mounted || outcome == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import gagal')),
        );
      }
      return;
    }

    if (outcome.touched == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada produk yang ditambahkan. Semua barcode sudah ada.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${outcome.added} produk ditambahkan'
          '${outcome.updated > 0 ? ', ${outcome.updated} diperbarui' : ''}',
        ),
      ),
    );
  }
}
