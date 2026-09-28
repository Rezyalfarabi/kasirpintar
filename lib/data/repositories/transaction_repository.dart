import 'package:kasir_pintar/data/models/transaction.dart';
import 'package:kasir_pintar/data/models/transaction_item.dart';

abstract class TransactionRepository {
  Future<List<TransactionWithItems>> getAllTransactions({
    int? limit,
    int? offset,
  });

  Future<TransactionWithItems?> getTransactionById(int id);

  Future<int> createTransaction(Transaction transaction, List<TransactionItem> items);

  Future<void> updatePdfPath(int transactionId, String pdfPath);

  Future<List<TransactionItem>> getTransactionItems(int transactionId);

  Future<int> getTransactionsCount();

  Future<int> getTotalSales({DateTime? startDate, DateTime? endDate});
}

class TransactionWithItems {
  final Transaction transaction;
  final List<TransactionItem> items;

  TransactionWithItems({
    required this.transaction,
    required this.items,
  });
}