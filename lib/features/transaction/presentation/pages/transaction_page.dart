import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/features/transaction/presentation/controllers/cart_controller.dart';
import 'package:kasir_pintar/features/transaction/presentation/widgets/cart_item_tile.dart';
import 'package:kasir_pintar/features/transaction/presentation/widgets/cart_summary_panel.dart';
import 'package:kasir_pintar/features/transaction/presentation/widgets/product_picker_panel.dart';

/// Layar kasir.
///
/// Di layar lebar katalog dan keranjang tampil berdampingan seperti terminal
/// kasir sungguhan; di layar sempit keduanya ditukar lewat satu tombol supaya
/// keranjang tetap punya ruang penuh untuk daftar belanja.
class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  static const int _katalogTab = 0;
  static const int _cartTab = 1;
  int _mobileTab = _katalogTab;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);

    return ResponsiveScaffold(
      appBar: AppBarWidget(
        titleWidget: Row(
          children: [
            const AppBrandMark(),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Kasir Pintar', style: AppTextStyles.heading),
                Text(
                  'Terminal penjualan',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
            tooltip: 'Riwayat Transaksi',
          ),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return isWide
              ? _buildWideLayout()
              : _buildNarrowLayout(cartState.totalItems);
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: ProductPickerPanel(),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: 4, child: _buildCartPane()),
      ],
    );
  }

  Widget _buildNarrowLayout(int totalItems) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        SegmentedControl<int>(
          segments: [
            const Segment(value: _katalogTab, label: 'Katalog'),
            Segment(
              value: _cartTab,
              label: totalItems > 0 ? 'Keranjang ($totalItems)' : 'Keranjang',
            ),
          ],
          selectedValue: _mobileTab,
          onChanged: (tab) => setState(() => _mobileTab = tab),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _mobileTab == _katalogTab
              ? const ProductPickerPanel()
              : _buildScrollableCart(),
        ),
      ],
    );
  }

  /// Di layar sempit seluruh keranjang ikut bergulir: panel ringkasan berisi
  /// kolom uang bayar yang butuh ruang, jadi lebih baik bisa digulir daripada
  /// terpotong saat papan ketik muncul.
  Widget _buildScrollableCart() {
    final cartState = ref.watch(cartControllerProvider);

    return Column(
      children: [
        _buildCartHeader(cartState),
        const Divider(height: 1),
        Expanded(
          child: cartState.isEmpty
              ? const EmptyState(
                  title: 'Keranjang Kosong',
                  message: 'Ketuk produk di tab Katalog, atau pakai tombol scan barcode.',
                  icon: Icons.shopping_cart_outlined,
                )
              : ListView.builder(
                  itemCount: cartState.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == cartState.items.length) {
                      return const CartSummaryPanel();
                    }
                    return _buildCartTile(cartState.items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCartHeader(CartState cartState) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Text('KERANJANG', style: AppTextStyles.heading),
          const Spacer(),
          Text(
            cartState.isEmpty ? 'kosong' : '${cartState.totalItems} item',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPane() {
    final cartState = ref.watch(cartControllerProvider);

    return Column(
      children: [
        _buildCartHeader(cartState),
        const Divider(height: 1),
        Expanded(
          child: cartState.isEmpty
              ? const EmptyState(
                  title: 'Keranjang Kosong',
                  message: 'Ketuk produk di katalog untuk mulai transaksi.',
                  icon: Icons.shopping_cart_outlined,
                )
              : ListView.builder(
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) =>
                      _buildCartTile(cartState.items[index]),
                ),
        ),
        const CartSummaryPanel(),
      ],
    );
  }

  Widget _buildCartTile(CartItem item) {
    final cart = ref.read(cartControllerProvider.notifier);
    return CartItemTile(
      item: item,
      onIncrement: () => cart.incrementQuantity(item.product.id),
      onDecrement: () => cart.decrementQuantity(item.product.id),
      onRemove: () => cart.removeProduct(item.product.id),
    );
  }
}
