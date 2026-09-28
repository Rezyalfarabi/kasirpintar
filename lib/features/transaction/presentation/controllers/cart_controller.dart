import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  int get subtotal => product.price * quantity;
  String get formattedSubtotal => CurrencyFormat.format(subtotal);
}

class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }

  /// Jumlah produk tertentu yang sudah masuk keranjang. Dipakai katalog kasir
  /// untuk menandai produk yang sudah dipilih dan menahan tambahan melebihi
  /// stok yang ada.
  int quantityOf(int productId) {
    for (final item in items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  String get formattedSubtotal => CurrencyFormat.format(subtotal);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

class CartController extends StateNotifier<CartState> {
  final ProductRepository _productRepository;

  CartController(this._productRepository) : super(CartState());

  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity)]);
    }
  }

  void removeProduct(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final existingIndex = state.items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(quantity: quantity);
      state = state.copyWith(items: updatedItems);
    }
  }

  void incrementQuantity(int productId) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: updatedItems);
    }
  }

  void decrementQuantity(int productId) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final currentQty = state.items[existingIndex].quantity;
      if (currentQty <= 1) {
        removeProduct(productId);
      } else {
        final updatedItems = [...state.items];
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          quantity: currentQty - 1,
        );
        state = state.copyWith(items: updatedItems);
      }
    }
  }

  void clear() {
    state = CartState();
  }

  Future<bool> validateStock() async {
    for (final item in state.items) {
      final product = await _productRepository.getProductById(item.product.id);
      if (product == null || product.stock < item.quantity) {
        return false;
      }
    }
    return true;
  }
}