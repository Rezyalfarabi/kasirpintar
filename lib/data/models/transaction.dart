class Transaction {
  final int id;
  final DateTime date;
  final int totalPrice;
  final int paidAmount;
  final int changeAmount;
  final String? pdfPath;

  Transaction({
    required this.id,
    required this.date,
    required this.totalPrice,
    required this.paidAmount,
    required this.changeAmount,
    this.pdfPath,
  });

  Transaction copyWith({
    int? id,
    DateTime? date,
    int? totalPrice,
    int? paidAmount,
    int? changeAmount,
    String? pdfPath,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      totalPrice: totalPrice ?? this.totalPrice,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }
}