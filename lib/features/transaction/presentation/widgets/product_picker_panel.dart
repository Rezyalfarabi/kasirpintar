import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/core/utils/product_image.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/product_picker_controller.dart';

/// Panel kiri layar kasir: cari produk lalu ketuk untuk masuk keranjang.
///
/// Tanpa panel ini produk hanya bisa masuk keranjang lewat scan barcode,
/// padahal banyak toko punya barang tanpa label yang bisa dibaca.
class ProductPickerPanel extends ConsumerStatefulWidget {
  const ProductPickerPanel({super.key});

  @override
  ConsumerState<ProductPickerPanel> createState() => _ProductPickerPanelState();
}

class _ProductPickerPanelState extends ConsumerState<ProductPickerPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productPickerControllerProvider);
    final controller = ref.read(productPickerControllerProvider.notifier);

    if (state.query.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: InputField(
                label: 'Cari Produk',
                hint: 'Nama atau barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          controller.setQuery('');
                        },
                      ),
                controller: _searchController,
                onChanged: controller.setQuery,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              height: 44,
              width: 44,
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan barcode',
                onPressed: () => context.push('/scan'),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('KATALOG', style: AppTextStyles.heading),
            const Spacer(),
            Text(
              '${state.matchedCount} produk',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        Expanded(child: _buildGrid(state, controller)),
      ],
    );
  }

  Widget _buildGrid(ProductPickerState state, ProductPickerController controller) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.products.isEmpty) {
      return EmptyState(
        title: 'Katalog Gagal Dimuat',
        message: state.error!,
        icon: Icons.error_outline,
        actionLabel: 'Coba Lagi',
        onAction: controller.refresh,
      );
    }

    if (state.products.isEmpty) {
      return EmptyState(
        title: state.query.isEmpty ? 'Belum Ada Produk' : 'Tidak Ditemukan',
        message: state.query.isEmpty
            ? 'Tambahkan produk lebih dulu di menu Produk.'
            : 'Tidak ada produk yang cocok dengan "${state.query}".',
        icon: state.query.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
        actionLabel: state.query.isEmpty ? 'Tambah Produk' : null,
        onAction: state.query.isEmpty ? () => context.push('/product-form') : null,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 640
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 168,
          ),
          itemCount: state.products.length,
          itemBuilder: (context, index) {
            final product = state.products[index];
            return _ProductCard(
              product: product,
              quantityInCart: ref.watch(cartControllerProvider).quantityOf(product.id),
              onTap: product.isOutOfStock ? null : () => _addToCart(product),
            );
          },
        );
      },
    );
  }

  void _addToCart(Product product) {
    final cart = ref.read(cartControllerProvider.notifier);
    final inCart = ref.read(cartControllerProvider).quantityOf(product.id);

    if (inCart >= product.stock) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Stok ${product.name} tinggal ${product.stock}')),
        );
      return;
    }

    cart.addProduct(product);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text('${product.name} ditambahkan'),
        ),
      );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final int quantityInCart;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.product,
    required this.quantityInCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;

    return Material(
      color: isOutOfStock ? AppColors.offWhite : AppColors.baseWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(),
                  const Spacer(),
                  if (quantityInCart > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.baseBlack,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        '$quantityInCart×',
                        style: AppTextStyles.badge.copyWith(color: AppColors.baseWhite),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Text(
                  product.name,
                  style: AppTextStyles.subheading.copyWith(
                    color: isOutOfStock ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                CurrencyFormat.format(product.price),
                style: AppTextStyles.price.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (isOutOfStock)
                const StatusBadge(label: 'STOK HABIS', type: BadgeType.danger)
              else if (product.isLowStock)
                StatusBadge(
                  label: 'SISA ${product.stock}',
                  type: BadgeType.attention,
                )
              else
                Text(
                  'Stok ${product.stock}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    const size = 40.0;
    final provider = productImageProvider(
      imageSource: product.imageSource,
      imagePath: product.imagePath,
      imageBytes: product.imageBytes,
    );

    if (provider == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.thumbnail),
        ),
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.placeholder),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.thumbnail),
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.placeholder),
          ),
        ),
      ),
    );
  }
}
