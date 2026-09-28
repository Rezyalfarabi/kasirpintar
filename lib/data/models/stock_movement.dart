enum StockMovementSource {
  /// Stok awal saat produk dibuat.
  create,

  /// Diubah dari form produk.
  manual,

  /// Ditambah dari berkas Excel.
  excel,

  /// Berkurang karena penjualan di kasir.
  sale,

  /// Produk dihapus dari daftar.
  delete,
}

extension StockMovementSourceLabel on StockMovementSource {
  String get label => switch (this) {
        StockMovementSource.create => 'Produk baru',
        StockMovementSource.manual => 'Diubah manual',
        StockMovementSource.excel => 'Dari Excel',
        StockMovementSource.sale => 'Penjualan',
        StockMovementSource.delete => 'Produk dihapus',
      };

  static StockMovementSource fromName(String name) {
    for (final source in StockMovementSource.values) {
      if (source.name == name) return source;
    }
    return StockMovementSource.manual;
  }
}

/// Satu baris riwayat perubahan stok.
///
/// Nama produk disimpan apa adanya saat perubahan terjadi supaya riwayat tetap
/// terbaca walau produknya kemudian diubah namanya atau dihapus.
class StockMovement {
  final int id;
  final int productId;
  final String productName;
  final int delta;
  final int stockBefore;
  final int stockAfter;
  final StockMovementSource source;
  final String? note;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.delta,
    required this.stockBefore,
    required this.stockAfter,
    required this.source,
    this.note,
    required this.createdAt,
  });

  bool get isIncrease => delta > 0;
  bool get isDecrease => delta < 0;
}
