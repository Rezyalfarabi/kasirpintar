import 'package:flutter/material.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/core/utils/product_image.dart';
import 'package:kasir_pintar/data/models/product.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHistory;

  const ProductListItem({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final showMenu = onEdit != null || onDelete != null || onHistory != null;

    return ListRow(
      leading: _buildThumbnail(),
      title: Text(
        product.name,
        style: AppTextStyles.subheading,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Flexible(
                child: Text(
                  product.barcode,
                  style: AppTextStyles.barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (product.category != null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Text('•', style: AppTextStyles.barcode),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    product.category!,
                    style: AppTextStyles.barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Harga bisa panjang (ratusan juta) sedangkan barisnya sempit di
          // ponsel, jadi harganya mengecil sendiri alih-alih meluber. Sisa
          // stok tidak ditulis di sini karena sudah ada di lencana kanan.
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormat.format(product.price),
                    style: AppTextStyles.price.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStockBadge(),
          if (showMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Aksi produk',
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                  case 'history':
                    onHistory?.call();
                  case 'delete':
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Edit produk')),
                if (onHistory != null)
                  const PopupMenuItem(
                    value: 'history',
                    child: Text('Riwayat stok'),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Hapus produk')),
              ],
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildThumbnail() {
    const size = 48.0;
    final provider = productImageProvider(
      imageSource: product.imageSource,
      imagePath: product.imagePath,
      imageBytes: product.imageBytes,
    );

    if (provider == null) return _buildPlaceholder(size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.thumbnail),
      child: SizedBox(
        width: size,
        height: size,
        child: Image(
          image: provider,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(size),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppRadius.thumbnail),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.placeholder),
      ),
    );
  }

  /// Lencana sekaligus menampilkan jumlah stok, jadi tidak perlu teks stok
  /// terpisah yang membuat baris sesak di layar ponsel.
  Widget _buildStockBadge() {
    if (product.isOutOfStock) {
      return const StatusBadge(label: 'HABIS', type: BadgeType.danger);
    }
    if (product.isLowStock) {
      return StatusBadge(
        label: 'SISA ${product.stock}',
        type: BadgeType.attention,
      );
    }
    return StatusBadge(
      label: 'STOK ${product.stock}',
      type: BadgeType.neutral,
    );
  }
}
