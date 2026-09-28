import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_export_service.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/utils/platform_files.dart';

const _xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Hasil akhir proses ekspor, dipakai pemanggil untuk memilih pesan yang tepat.
enum ExportOutcome { success, empty, failed }

/// Nilai filter stok. `outOfStockOnly` dipisah dari `lowStockOnly` supaya
/// "menipis" tidak ikut menampilkan produk yang stoknya sudah nol.
const String stockFilterAll = 'all';
const String stockFilterLow = 'low';
const String stockFilterOut = 'out';

class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final String searchQuery;
  final String selectedCategory;
  final String stockFilter;
  final List<String> categories;
  final String? error;
  final bool isExporting;

  /// Jumlah seluruh produk di database, dipakai untuk ringkasan di atas daftar.
  final int totalCount;
  final int lowStockCount;
  final int outOfStockCount;

  /// Jumlah produk yang lolos filter yang sedang aktif.
  final int matchedCount;

  ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.searchQuery = '',
    this.selectedCategory = '',
    this.stockFilter = stockFilterAll,
    this.categories = const [],
    this.error,
    this.isExporting = false,
    this.totalCount = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.matchedCount = 0,
  });

  bool get hasActiveFilter =>
      searchQuery.isNotEmpty ||
      selectedCategory.isNotEmpty ||
      stockFilter != stockFilterAll;

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    String? searchQuery,
    String? selectedCategory,
    String? stockFilter,
    List<String>? categories,
    String? error,
    bool? isExporting,
    int? totalCount,
    int? lowStockCount,
    int? outOfStockCount,
    int? matchedCount,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      stockFilter: stockFilter ?? this.stockFilter,
      categories: categories ?? this.categories,
      error: error,
      isExporting: isExporting ?? this.isExporting,
      totalCount: totalCount ?? this.totalCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      matchedCount: matchedCount ?? this.matchedCount,
    );
  }
}

class ProductListController extends StateNotifier<ProductListState> {
  final ProductRepository _repository;
  final ExcelExportService _excelExport;
  int _page = 0;
  static const _pageSize = 50;

  ProductListController(this._repository, this._excelExport)
      : super(ProductListState()) {
    loadInitial();
  }

  /// Mengekspor seluruh produk (bukan hanya yang tampil karena filter) ke
  /// berkas Excel. Di web berkas diunduh browser, di native ditulis ke folder
  /// Documents.
  Future<ExportOutcome> exportToExcel() async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      final products = await _repository.getAllProducts();
      if (products.isEmpty) {
        state = state.copyWith(isExporting: false);
        return ExportOutcome.empty;
      }

      final bytes = _excelExport.exportProducts(products);
      final saved = await saveBytesToDocuments(
        bytes,
        _excelExport.fileNameFor(DateTime.now()),
        mimeType: _xlsxMimeType,
      );
      state = state.copyWith(isExporting: false);
      return saved ? ExportOutcome.success : ExportOutcome.failed;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return ExportOutcome.failed;
    }
  }

  /// Soft delete: produk disembunyikan dari daftar tapi barisnya tetap ada
  /// supaya riwayat transaksi lama tidak kehilangan produknya.
  Future<bool> deleteProduct(int productId) async {
    try {
      final deleted = await _repository.deleteProduct(productId);
      if (deleted) {
        await loadInitial();
      }
      return deleted;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _page = 0;
      final products = await _fetch(limit: _pageSize, offset: 0);
      final categories = await _repository.getAllCategories();
      final counts = await Future.wait([
        _repository.getProductsCount(),
        _repository.getLowStockCount(),
        _repository.getOutOfStockCount(),
        _repository.getProductsCount(
          searchQuery: _query,
          category: _category,
          lowStockOnly: _lowStockOnly,
          outOfStockOnly: _outOfStockOnly,
        ),
      ]);

      state = state.copyWith(
        products: products,
        hasMore: products.length >= _pageSize,
        categories: ['', ...categories],
        totalCount: counts[0],
        lowStockCount: counts[1],
        outOfStockCount: counts[2],
        matchedCount: counts[3],
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
      final products = await _fetch(limit: _pageSize, offset: _page * _pageSize);
      state = state.copyWith(
        products: [...state.products, ...products],
        hasMore: products.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    _page = 0;
    await loadInitial();
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    _debouncedSearch();
  }

  void _debouncedSearch() {
    final query = state.searchQuery;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (state.searchQuery == query) {
        loadInitial();
      }
    });
  }

  void setCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    loadInitial();
  }

  void setStockFilter(String filter) {
    if (state.stockFilter == filter) return;
    state = state.copyWith(stockFilter: filter);
    loadInitial();
  }

  void clearFilters() {
    if (!state.hasActiveFilter) return;
    state = state.copyWith(searchQuery: '', selectedCategory: '', stockFilter: stockFilterAll);
    loadInitial();
  }

  String? get _query => state.searchQuery.isEmpty ? null : state.searchQuery;

  String? get _category => state.selectedCategory.isEmpty ? null : state.selectedCategory;

  bool? get _lowStockOnly =>
      state.stockFilter == stockFilterLow ? true : null;

  bool? get _outOfStockOnly =>
      state.stockFilter == stockFilterOut ? true : null;

  /// Satu jalur query untuk semua pemuatan daftar supaya filter yang aktif di
  /// layar selalu ikut terkirim ke database.
  Future<List<Product>> _fetch({required int limit, required int offset}) {
    return _repository.getAllProducts(
      searchQuery: _query,
      category: _category,
      lowStockOnly: _lowStockOnly,
      outOfStockOnly: _outOfStockOnly,
      limit: limit,
      offset: offset,
    );
  }
}

final productListControllerProvider =
    StateNotifierProvider<ProductListController, ProductListState>((ref) {
  return ProductListController(
    ref.read(productRepositoryProvider),
    ref.read(excelExportServiceProvider),
  );
});
