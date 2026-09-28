import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/core/utils/product_image.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/cart_controller.dart';

class CartItemTile extends ConsumerWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.thumbnail),
            child: Container(
              width: AppSpacing.thumbnailSize.toDouble(),
              height: AppSpacing.thumbnailSize.toDouble(),
              color: AppColors.offWhite,                  child: _buildThumbnail(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.subheading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${CurrencyFormat.format(item.product.price)} × ${item.quantity}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Subtotal: ${item.formattedSubtotal}',
                  style: AppTextStyles.price.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Quantity controls
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: AppSpacing.iconSize),
                  onPressed: onDecrement,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: AppTextStyles.subheading.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: AppSpacing.iconSize),
                  onPressed: onIncrement,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.dangerLine, size: AppSpacing.iconSize),
            onPressed: onRemove,
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final size = AppSpacing.thumbnailSize.toDouble();
    final provider = productImageProvider(
      imageSource: item.product.imageSource,
      imagePath: item.product.imagePath,
      imageBytes: item.product.imageBytes,
    );

    if (provider == null) {
      return const Icon(Icons.image_outlined, size: 32, color: AppColors.placeholder);
    }

    return Image(
      image: provider,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_outlined, size: 32, color: AppColors.placeholder),
    );
  }
}