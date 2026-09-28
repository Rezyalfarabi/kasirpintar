import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/utils/date_format.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/features/stock_history/presentation/controllers/stock_history_controller.dart';

/// Jejak audit perubahan stok: kapan, berapa, dan dari mana perubahannya.
class StockHistoryPage extends ConsumerWidget {
  final int? productId;

  const StockHistoryPage({super.key, this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockHistoryControllerProvider(productId));
    final controller = ref.read(stockHistoryControllerProvider(productId).notifier);

    return ResponsiveScaffold(
      appBar: AppBarWidget(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              productId == null ? 'Riwayat Stok' : 'Riwayat Stok Produk',
              style: AppTextStyles.heading,
            ),
            Text(
              '${state.matchedCount} perubahan tercatat',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          FilterChipBar<StockMovementSource?>(
            items: [
              const FilterChipItem(value: null, label: 'Semua'),
              for (final source in StockMovementSource.values)
                FilterChipItem(value: source, label: source.label),
            ],
            selectedValue: state.sourceFilter,
            onSelected: controller.setSourceFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildList(context, controller, state)),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    StockHistoryController controller,
    StockHistoryState state,
  ) {
    if (state.isLoading && state.movements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.movements.isEmpty) {
      return EmptyState(
        title: 'Riwayat Gagal Dimuat',
        message: state.error!,
        icon: Icons.error_outline,
        actionLabel: 'Coba Lagi',
        onAction: controller.refresh,
      );
    }

    if (state.movements.isEmpty) {
      return EmptyState(
        title: 'Belum Ada Riwayat Stok',
        message: state.hasFilter
            ? 'Tidak ada perubahan stok dari sumber yang dipilih.'
            : 'Setiap perubahan stok akan tercatat di sini: penambahan dari '
                'Excel, penjualan di kasir, maupun perubahan manual.',
        icon: Icons.history_toggle_off,
        actionLabel: state.hasFilter ? 'Tampilkan Semua' : null,
        onAction: state.hasFilter ? () => controller.setSourceFilter(null) : null,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        itemCount: state.movements.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          if (index == state.movements.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _MovementRow(movement: state.movements[index]);
        },
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final StockMovement movement;

  const _MovementRow({required this.movement});

  @override
  Widget build(BuildContext context) {
    // Garis pemisah disediakan ListView.separated, jadi ListRow tidak perlu
    // menambah garisnya sendiri.
    return ListRow(
      showDivider: false,
      leading: _buildLeading(),
      title: Text(
        movement.productName,
        style: AppTextStyles.subheading,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${movement.source.label} • ${DateFormatUtil.formatDateTime(movement.createdAt)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Stok ${movement.stockBefore} → ${movement.stockAfter}'
            '${movement.note == null ? '' : ' • ${movement.note}'}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${movement.delta > 0 ? '+' : ''}${movement.delta}',
            style: AppTextStyles.price.copyWith(
              fontWeight: FontWeight.bold,
              color: movement.isIncrease ? AppColors.successLine : AppColors.dangerLine,
            ),
          ),
          Text(
            'unit',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLeading() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppRadius.thumbnail),
      ),
      child: Center(
        child: Icon(_iconFor(movement.source), size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  IconData _iconFor(StockMovementSource source) {
    return switch (source) {
      StockMovementSource.create => Icons.add_box_outlined,
      StockMovementSource.excel => Icons.table_chart_outlined,
      StockMovementSource.manual => Icons.edit_outlined,
      StockMovementSource.sale => Icons.point_of_sale_outlined,
      StockMovementSource.delete => Icons.delete_outline,
    };
  }
}
