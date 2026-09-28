import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/core/utils/date_format.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/data/repositories/transaction_repository.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(transactionRepositoryProvider);

    return ResponsiveScaffold(
      appBar: const AppBarWidget(title: 'Riwayat Transaksi'),
      bottomNavigationBar: const AppNavigationBar(),
      body: FutureBuilder<List<TransactionWithItems>>(
        future: controller.getAllTransactions(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: AppTextStyles.body),
            );
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const EmptyState(
              title: 'Belum Ada Transaksi',
              message: 'Transaksi yang selesai akan muncul di sini',
              icon: Icons.receipt_long_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final transaction = transactions[index].transaction;
              return ListTile(
                leading: const Icon(Icons.receipt_outlined),
                title: Text('Transaksi #${transaction.id.toString().padLeft(6, '0')}'),
                subtitle: Text(
                  '${DateFormatUtil.formatDateTime(transaction.date)} \u2022 ${CurrencyFormat.format(transaction.totalPrice)}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                trailing: Text(
                  CurrencyFormat.format(transaction.totalPrice),
                  style: AppTextStyles.priceDisplay.copyWith(fontSize: 18),
                ),
                onTap: () => context.push('/receipt/${transaction.id}'),
              );
            },
          );
        },
      ),
    );
  }
}