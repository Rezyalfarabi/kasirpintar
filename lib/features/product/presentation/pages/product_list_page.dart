import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/features/product/presentation/widgets/product_list_item.dart';
import 'package:kasir_pintar/features/product/presentation/controllers/product_list_controller.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(productListControllerProvider.notifier);
    final state = ref.watch(productListControllerProvider);

    // Filter bisa direset dari luar kolom pencarian (tombol "Reset Filter"),
    // jadi isinya disamakan lagi saat state kosong.
    if (state.searchQuery.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return ResponsiveScaffold(
      appBar: AppBarWidget(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Produk', style: AppTextStyles.heading),
            Text(
              '${state.matchedCount} dari ${state.totalCount} produk',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Tambah stok dari Excel',
            onPressed: () => context.push('/stock-in'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Aksi lain',
            onSelected: (value) {
              if (value == 'export') {
                _export(context, controller);
              } else {
                context.push('/excel-import');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                enabled: !state.isExporting,
                child: const Text('Ekspor Excel'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Impor produk baru'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/product-form'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          _buildStats(state, controller),
          const SizedBox(height: AppSpacing.md),
          InputField(
            label: 'Cari Produk',
            hint: 'Nama atau barcode',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Hapus pencarian',
                    onPressed: () {
                      _searchController.clear();
                      controller.setSearchQuery('');
                    },
                  ),
            controller: _searchController,
            onChanged: controller.setSearchQuery,
          ),
          if (state.categories.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            FilterChipBar<String>(
              items: [
                for (final category in state.categories)
                  FilterChipItem(
                    value: category,
                    label: category.isEmpty ? 'Semua Kategori' : category,
                  ),
              ],
              selectedValue: state.selectedCategory,
              onSelected: controller.setCategory,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildList(context, controller, state)),
        ],
      ),
    );
  }

  /// Tiga angka ringkas yang sekaligus jadi filter stok — menekan "Stok habis"
  /// langsung menyaring daftar, jadi tidak perlu kontrol filter terpisah.
  Widget _buildStats(ProductListState state, ProductListController controller) {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            label: 'TOTAL PRODUK',
            value: '${state.totalCount}',
            icon: Icons.inventory_2_outlined,
            isSelected: state.stockFilter == stockFilterAll,
            onTap: () => controller.setStockFilter(stockFilterAll),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(
            label: 'STOK MENIPIS',
            value: '${state.lowStockCount}',
            icon: Icons.warning_amber_outlined,
            tone: state.lowStockCount > 0 ? AppColors.yellowDeep : AppColors.textSecondary,
            isSelected: state.stockFilter == stockFilterLow,
            onTap: () => controller.setStockFilter(stockFilterLow),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(
            label: 'STOK HABIS',
            value: '${state.outOfStockCount}',
            icon: Icons.remove_shopping_cart_outlined,
            tone: state.outOfStockCount > 0 ? AppColors.dangerLine : AppColors.textSecondary,
            isSelected: state.stockFilter == stockFilterOut,
            onTap: () => controller.setStockFilter(stockFilterOut),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    ProductListController controller,
    ProductListState state,
  ) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.products.isEmpty) {
      if (state.hasActiveFilter) {
        return EmptyState(
          title: 'Tidak Ada Hasil',
          message: 'Tidak ada produk yang cocok dengan pencarian atau filter aktif.',
          icon: Icons.search_off,
          actionLabel: 'Reset Filter',
          onAction: () {
            _searchController.clear();
            controller.clearFilters();
          },
        );
      }

      return EmptyState(
        title: 'Belum Ada Produk',
        message: 'Tambah produk pertama, atau tarik daftar dari berkas Excel.',
        icon: Icons.inventory_2_outlined,
        actionLabel: 'Tambah Produk',
        onAction: () => context.push('/product-form'),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          if (index == state.products.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final product = state.products[index];
          return ProductListItem(
            product: product,
            onTap: () => context.push('/product-form?id=${product.id}'),
            onEdit: () => context.push('/product-form?id=${product.id}'),
            onHistory: () => context.push('/stock-history?productId=${product.id}'),
            onDelete: () => _confirmDelete(context, controller, product),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductListController controller,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('${product.name} akan dihapus dari daftar produk.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await controller.deleteProduct(product.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? '${product.name} dihapus' : 'Produk gagal dihapus',
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    ProductListController controller,
  ) async {
    final outcome = await controller.exportToExcel();
    if (!context.mounted) return;

    final message = switch (outcome) {
      ExportOutcome.success =>
        'Daftar produk diekspor. Sunting kolom stok lalu unggah di Tambah Stok.',
      ExportOutcome.empty => 'Belum ada produk untuk diekspor',
      ExportOutcome.failed => 'Gagal mengekspor daftar produk',
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

