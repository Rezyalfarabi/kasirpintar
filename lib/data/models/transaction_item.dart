class TransactionItem {
  final int id;
  final int transactionId;
  final int productId;
  final String productName;
  final int qty;
  final int unitPrice;
  final int subtotal;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    int? qty,
    int? unitPrice,
    int? subtotal,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}