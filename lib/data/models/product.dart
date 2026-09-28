import 'dart:typed_data';

class Product {
  final int id;
  final String barcode;
  final String name;
  final int price;
  final int stock;
  final String? category;

  /// 'camera', 'gallery', atau 'url'.
  final String? imageSource;

  /// URL gambar ketika [imageSource] bernilai 'url'. Pada data lama, kolom ini
  /// menyimpan path relatif gambar di perangkat.
  final String? imagePath;
  final Uint8List? imageBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    this.category,
    this.imageSource,
    this.imagePath,
    this.imageBytes,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    int? price,
    int? stock,
    String? category,
    String? imageSource,
    String? imagePath,
    Uint8List? imageBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool clearImage = false,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageSource: clearImage ? null : (imageSource ?? this.imageSource),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  bool get isLowStock => stock > 0 && stock <= 5;
  bool get isOutOfStock => stock == 0;

  bool get hasImage {
    if (imageSource == 'url') return imagePath?.isNotEmpty == true;
    return imageBytes?.isNotEmpty == true || imagePath?.isNotEmpty == true;
  }
}
