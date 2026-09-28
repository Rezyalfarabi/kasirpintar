import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';

class CartSummaryPanel extends ConsumerWidget {
  const CartSummaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final subtotal = cartState.subtotal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        border: Border(
          left: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RINGKASAN', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.lg),
          if (cartState.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('Keranjang kosong', style: AppTextStyles.body),
              ),
            )
          else
            _buildSummaryContent(subtotal),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(int subtotal) {
    return Column(
      children: [
        _buildRow('Subtotal', CurrencyFormat.format(subtotal)),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: AppSpacing.md),
        _buildRow('TOTAL', CurrencyFormat.format(subtotal), isTotal: true),
        const SizedBox(height: AppSpacing.xl),
        _buildPaymentInput(),
        const SizedBox(height: AppSpacing.md),
        _buildChangeDisplay(),
        const SizedBox(height: AppSpacing.lg),
        Consumer(
          builder: (context, ref, _) {
            final transactionState = ref.watch(transactionControllerProvider);
            final controller = ref.read(transactionControllerProvider.notifier);
            return PrimaryButton(
              label: 'BAYAR',
              onPressed: transactionState.isProcessing
                  ? null
                  : () async {
                      final transactionId = await controller.processPayment();
                      if (transactionId != null && context.mounted) {
                        context.go('/receipt/$transactionId');
                      }
                    },
              isLoading: transactionState.isProcessing,
              isFullWidth: true,
              leadingIcon: Icons.payment,
            );
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final error = ref.watch(transactionControllerProvider).error;
            if (error == null) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLine.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.dangerLine),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.dangerLine,
                        size: AppSpacing.iconSize,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          error,
                          style: AppTextStyles.body.copyWith(color: AppColors.dangerLine),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? AppTextStyles.display.copyWith(fontSize: 24)
                : AppTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildAmount(
          amount,
          style: isTotal
              ? AppTextStyles.display.copyWith(fontSize: 24, fontWeight: FontWeight.bold)
              : AppTextStyles.price.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Nominal ikut mengecil bila ruangnya sempit, bukan meluber keluar panel:
  /// total bernilai miliaran tetap harus terbaca di layar ponsel.
  Widget _buildAmount(String amount, {required TextStyle style, Color? color}) {
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          amount,
          style: color == null ? style : style.copyWith(color: color),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildPaymentInput() {
    return Consumer(
      builder: (context, ref, _) {
        final transactionState = ref.watch(transactionControllerProvider);
        final controller = ref.read(transactionControllerProvider.notifier);

        return InputField(
          label: 'Uang Bayar *',
          hint: 'Masukkan nominal uang',
          controller: TextEditingController(text: transactionState.paidAmount),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            ref.read(transactionControllerProvider.notifier).setPaidAmount(value);
          },
          errorText: transactionState.paidAmount.isNotEmpty && !controller.isPaymentValid
              ? 'Uang bayar kurang dari total'
              : null,
        );
      },
    );
  }

  Widget _buildChangeDisplay() {
    return Consumer(
      builder: (context, ref, _) {
        final transactionState = ref.watch(transactionControllerProvider);
        final cartState = ref.watch(cartControllerProvider);
        final changeValue =
            CurrencyFormat.parse(transactionState.paidAmount) - cartState.subtotal;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: changeValue >= 0
                ? AppColors.successLine.withValues(alpha: 0.1)
                : AppColors.offWhite,
            border: Border.all(
              color: changeValue >= 0 ? AppColors.successLine : AppColors.divider,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'KEMBALIAN',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildAmount(
                CurrencyFormat.format(changeValue),
                style: AppTextStyles.display.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                color: changeValue >= 0 ? AppColors.successLine : AppColors.dangerLine,
              ),
            ],
          ),
        );
      },
    );
  }
}
