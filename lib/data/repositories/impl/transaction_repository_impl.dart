import 'package:drift/drift.dart';
import 'package:kasir_pintar/data/models/transaction.dart';
import 'package:kasir_pintar/data/models/transaction_item.dart';
import 'package:kasir_pintar/data/datasources/local/app_database.dart' as db;
import 'package:kasir_pintar/data/repositories/transaction_repository.dart';
import 'package:kasir_pintar/core/errors/exception_handler.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final db.TransactionDao _transactionDao;

  TransactionRepositoryImpl(this._transactionDao);

  @override
  Future<List<TransactionWithItems>> getAllTransactions({
    int? limit,
    int? offset,
  }) async {
    try {
      final dbResults = await _transactionDao.getAllTransactions(
        limit: limit,
        offset: offset,
      );
      return _groupTransactions(dbResults);
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<TransactionWithItems?> getTransactionById(int id) async {
    try {
      final dbResult = await _transactionDao.getTransactionById(id);
      if (dbResult == null) return null;

      final items = await _transactionDao.getTransactionItems(id);
      return TransactionWithItems(
        transaction: _mapToTransaction(dbResult.transaction),
        items: items.map(_mapToTransactionItem).toList(),
      );
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> createTransaction(
    Transaction transaction,
    List<TransactionItem> items,
  ) async {
    try {
      final transactionCompanion = db.TransactionsTableCompanion(
        date: Value(transaction.date),
        totalPrice: Value(transaction.totalPrice),
        paidAmount: Value(transaction.paidAmount),
        changeAmount: Value(transaction.changeAmount),
        pdfPath: Value(transaction.pdfPath),
      );

      final itemCompanions = items.map((item) => db.TransactionItemsTableCompanion(
        transactionId: const Value(0),
        productId: Value(item.productId),
        productName: Value(item.productName),
        qty: Value(item.qty),
        unitPrice: Value(item.unitPrice),
        subtotal: Value(item.subtotal),
      ),).toList();

      return await _transactionDao.insertTransactionWithItems(
        transactionCompanion,
        itemCompanions,
      );
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<List<TransactionItem>> getTransactionItems(int transactionId) async {
    try {
      final dbItems = await _transactionDao.getTransactionItems(transactionId);
      return dbItems.map(_mapToTransactionItem).toList();
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> getTransactionsCount() async {
    try {
      return await _transactionDao.getTransactionsCount();
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<int> getTotalSales({DateTime? startDate, DateTime? endDate}) async {
    try {
      return await _transactionDao.getTotalSales(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  @override
  Future<void> updatePdfPath(int transactionId, String pdfPath) async {
    try {
      await _transactionDao.updatePdfPath(transactionId, pdfPath);
    } catch (e, st) {
      throw ExceptionHandler.handleError(e, st);
    }
  }

  List<TransactionWithItems> _groupTransactions(List<db.TransactionWithItems> results) {
    final Map<int, TransactionWithItems> map = {};

    for (final result in results) {
      final transaction = _mapToTransaction(result.transaction);
      final item = result.item != null ? _mapToTransactionItem(result.item!) : null;

      if (map.containsKey(transaction.id)) {
        if (item != null) {
          map[transaction.id] = TransactionWithItems(
            transaction: transaction,
            items: [...map[transaction.id]!.items, item],
          );
        }
      } else {
        map[transaction.id] = TransactionWithItems(
          transaction: transaction,
          items: item != null ? [item] : [],
        );
      }
    }

    return map.values.toList()
      ..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
  }

  Transaction _mapToTransaction(dbTransaction) {
    return Transaction(
      id: dbTransaction.id,
      date: dbTransaction.date,
      totalPrice: dbTransaction.totalPrice,
      paidAmount: dbTransaction.paidAmount,
      changeAmount: dbTransaction.changeAmount,
      pdfPath: dbTransaction.pdfPath,
    );
  }

  TransactionItem _mapToTransactionItem(dbItem) {
    return TransactionItem(
      id: dbItem.id,
      transactionId: dbItem.transactionId,
      productId: dbItem.productId,
      productName: dbItem.productName,
      qty: dbItem.qty,
      unitPrice: dbItem.unitPrice,
      subtotal: dbItem.subtotal,
    );
  }
}