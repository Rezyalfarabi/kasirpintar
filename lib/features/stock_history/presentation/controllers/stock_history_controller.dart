import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/data/models/stock_movement.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';

class StockHistoryState {
  final List<StockMovement> movements;
  final bool isLoading;
  final bool hasMore;
  final StockMovementSource? sourceFilter;
  final int matchedCount;
  final String? error;

  const StockHistoryState({
    this.movements = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.sourceFilter,
    this.matchedCount = 0,
    this.error,
  });

  bool get hasFilter => sourceFilter != null;

  StockHistoryState copyWith({
    List<StockMovement>? movements,
    bool? isLoading,
    bool? hasMore,
    StockMovementSource? sourceFilter,
    bool clearSourceFilter = false,
    int? matchedCount,
    String? error,
  }) {
    return StockHistoryState(
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      sourceFilter: clearSourceFilter ? null : (sourceFilter ?? this.sourceFilter),
      matchedCount: matchedCount ?? this.matchedCount,
      error: error,
    );
  }
}

/// Riwayat perubahan stok. [productId] kosong berarti seluruh produk.
class StockHistoryController extends StateNotifier<StockHistoryState> {
  final ProductRepository _repository;
  final int? productId;
  int _page = 0;
  static const _pageSize = 50;

  StockHistoryController(this._repository, {this.productId})
      : super(const StockHistoryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _page = 0;
      final movements = await _fetch(limit: _pageSize, offset: 0);
      final count = await _repository.getStockMovementsCount(
        productId: productId,
        source: state.sourceFilter,
      );
      state = state.copyWith(
        movements: movements,
        matchedCount: count,
        hasMore: movements.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      _page++;
      final movements = await _fetch(limit: _pageSize, offset: _page * _pageSize);
      state = state.copyWith(
        movements: [...state.movements, ...movements],
        hasMore: movements.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();

  void setSourceFilter(StockMovementSource? source) {
    if (state.sourceFilter == source) return;
    state = source == null
        ? state.copyWith(clearSourceFilter: true)
        : state.copyWith(sourceFilter: source);
    load();
  }

  Future<List<StockMovement>> _fetch({
    required int limit,
    required int offset,
  }) {
    return _repository.getStockMovements(
      productId: productId,
      source: state.sourceFilter,
      limit: limit,
      offset: offset,
    );
  }
}

final stockHistoryControllerProvider = StateNotifierProvider.family<
    StockHistoryController, StockHistoryState, int?>((ref, productId) {
  return StockHistoryController(
    ref.read(productRepositoryProvider),
    productId: productId,
  );
});
