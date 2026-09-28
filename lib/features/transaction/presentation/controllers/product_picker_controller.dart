import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';

/// Daftar produk yang bisa diketuk untuk masuk keranjang di layar kasir.
///
/// Pencarian dikerjakan di database, bukan disaring di memori, supaya katalog
/// besar tetap ringan saat dibuka di perangkat kasir.
class ProductPickerState {
  final List<Product> products;
  final bool isLoading;
  final String query;
  final int matchedCount;
  final String? error;

  const ProductPickerState({
    this.products = const [],
    this.isLoading = false,
    this.query = '',
    this.matchedCount = 0,
    this.error,
  });

  ProductPickerState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? query,
    int? matchedCount,
    String? error,
  }) {
    return ProductPickerState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      matchedCount: matchedCount ?? this.matchedCount,
      error: error,
    );
  }
}

class ProductPickerController extends StateNotifier<ProductPickerState> {
  final ProductRepository _repository;
  static const _pageSize = 60;

  ProductPickerController(this._repository) : super(const ProductPickerState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final query = state.query.isEmpty ? null : state.query;
      final products = await _repository.getAllProducts(
        searchQuery: query,
        limit: _pageSize,
      );
      final matchedCount = await _repository.getProductsCount(searchQuery: query);
      state = state.copyWith(
        products: products,
        matchedCount: matchedCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setQuery(String query) {
    if (state.query == query) return;
    state = state.copyWith(query: query);
    _debouncedSearch();
  }

  void _debouncedSearch() {
    final query = state.query;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (state.query == query) {
        load();
      }
    });
  }

  Future<void> refresh() async {
    await load();
  }
}

final productPickerControllerProvider =
    StateNotifierProvider<ProductPickerController, ProductPickerState>((ref) {
  return ProductPickerController(ref.read(productRepositoryProvider));
});
