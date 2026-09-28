import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/utils/validators.dart';
import 'package:kasir_pintar/core/utils/image_utils.dart';

class ProductFormState {
  final String name;
  final String barcode;
  final String price;
  final String stock;
  final String category;
  final String imageSource;
  final Uint8List? localImageBytes;
  final String? imageUrl;
  final bool isLoading;
  final String? error;
  final Map<String, String> fieldErrors;

  ProductFormState({
    this.name = '',
    this.barcode = '',
    this.price = '',
    this.stock = '',
    this.category = '',
    this.imageSource = 'camera',
    this.localImageBytes,
    this.imageUrl,
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
  });

  ProductFormState copyWith({
    String? name,
    String? barcode,
    String? price,
    String? stock,
    String? category,
    String? imageSource,
    Uint8List? localImageBytes,
    String? imageUrl,
    bool? isLoading,
    String? error,
    Map<String, String>? fieldErrors,
    bool clearImage = false,
  }) {
    return ProductFormState(
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageSource: imageSource ?? this.imageSource,
      localImageBytes: clearImage ? null : (localImageBytes ?? this.localImageBytes),
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  bool get hasImage => localImageBytes != null || imageUrl?.isNotEmpty == true;

  Product get product => Product(
    id: 0,
    barcode: barcode.trim(),
    name: name.trim(),
    price: int.parse(price.replaceAll('.', '').replaceAll(',', '')),
    stock: int.parse(stock),
    category: category.trim().isEmpty ? null : category.trim(),
    imageSource: hasImage ? imageSource : null,
    imagePath: imageSource == 'url' ? imageUrl : null,
    imageBytes: localImageBytes,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isDeleted: false,
  );

  bool get isValid {
    return Validators.name(name) == null &&
           Validators.barcode(barcode) == null &&
           Validators.price(price) == null &&
           Validators.stock(stock) == null &&
           Validators.category(category) == null &&
           (imageSource != 'url' || Validators.url(imageUrl) == null);
  }

  Map<String, String> get validationErrors {
    final errors = <String, String>{};
    if (Validators.name(name) != null) errors['name'] = Validators.name(name)!;
    if (Validators.barcode(barcode) != null) errors['barcode'] = Validators.barcode(barcode)!;
    if (Validators.price(price) != null) errors['price'] = Validators.price(price)!;
    if (Validators.stock(stock) != null) errors['stock'] = Validators.stock(stock)!;
    if (Validators.category(category) != null) errors['category'] = Validators.category(category)!;
    if (imageSource == 'url' && Validators.url(imageUrl) != null) errors['imageUrl'] = Validators.url(imageUrl)!;
    return errors;
  }
}

class ProductFormController extends StateNotifier<ProductFormState> {
  final ProductRepository _repository;
  final int? _productId;

  ProductFormController(this._repository, this._productId) : super(ProductFormState()) {
    if (_productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    state = state.copyWith(isLoading: true);
    try {
      final product = await _repository.getProductById(_productId!);
      if (product != null) {
        state = state.copyWith(
          name: product.name,
          barcode: product.barcode,
          price: product.price.toString(),
          stock: product.stock.toString(),
          category: product.category ?? '',
          imageSource: product.imageSource ?? 'camera',
          localImageBytes: product.imageBytes,
          imageUrl: product.imageSource == 'url' ? product.imagePath : null,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateName(String value) => state = state.copyWith(name: value, fieldErrors: {...state.fieldErrors, 'name': Validators.name(value) ?? ''});
  void updateBarcode(String value) => state = state.copyWith(barcode: value, fieldErrors: {...state.fieldErrors, 'barcode': Validators.barcode(value) ?? ''});
  void updatePrice(String value) => state = state.copyWith(price: value, fieldErrors: {...state.fieldErrors, 'price': Validators.price(value) ?? ''});
  void updateStock(String value) => state = state.copyWith(stock: value, fieldErrors: {...state.fieldErrors, 'stock': Validators.stock(value) ?? ''});
  void updateCategory(String value) => state = state.copyWith(category: value, fieldErrors: {...state.fieldErrors, 'category': Validators.category(value) ?? ''});
  void updateImageSource(String value) => state = state.copyWith(imageSource: value, clearImage: true);
  void updateImageUrl(String value) => state = state.copyWith(imageUrl: value, fieldErrors: {...state.fieldErrors, 'imageUrl': Validators.url(value) ?? ''});

  Future<void> pickImageFromCamera() async {
    final bytes = await ImageUtils.pickBytesFromCamera();
    if (bytes != null) {
      state = state.copyWith(imageSource: 'camera', localImageBytes: bytes, imageUrl: null);
    }
  }

  Future<void> pickImageFromGallery() async {
    final bytes = await ImageUtils.pickBytesFromGallery();
    if (bytes != null) {
      state = state.copyWith(imageSource: 'gallery', localImageBytes: bytes, imageUrl: null);
    }
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  Future<bool> save() async {
    final errors = state.validationErrors;
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final product = state.product;
      if (_productId != null) {
        await _repository.updateProduct(product.copyWith(id: _productId));
      } else {
        final existing = await _repository.getProductByBarcode(product.barcode);
        if (existing != null) {
          state = state.copyWith(isLoading: false, error: 'Barcode sudah digunakan');
          return false;
        }
        await _repository.createProduct(product);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final productFormControllerProvider = StateNotifierProvider.family<ProductFormController, ProductFormState, int?>((ref, productId) {
  return ProductFormController(ref.read(productRepositoryProvider), productId);
});
