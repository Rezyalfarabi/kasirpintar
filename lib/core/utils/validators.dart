import 'package:kasir_pintar/core/constants/app_constants.dart';

class Validators {
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Barcode wajib diisi';
    }
    if (value.length > AppConstants.maxBarcodeLength) {
      return 'Barcode maksimal ${AppConstants.maxBarcodeLength} karakter';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama produk wajib diisi';
    }
    if (value.length > AppConstants.maxNameLength) {
      return 'Nama maksimal ${AppConstants.maxNameLength} karakter';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga wajib diisi';
    }
    final parsed = int.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
    if (parsed == null) {
      return 'Harga harus berupa angka';
    }
    if (parsed <= 0) {
      return 'Harga harus lebih dari 0';
    }
    if (parsed > AppConstants.maxPrice) {
      return 'Harga terlalu besar';
    }
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stok wajib diisi';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Stok harus berupa angka';
    }
    if (parsed < 0) {
      return 'Stok tidak boleh negatif';
    }
    if (parsed > AppConstants.maxStock) {
      return 'Stok terlalu besar';
    }
    return null;
  }

  static String? category(String? value) {
    if (value != null && value.length > AppConstants.maxCategoryLength) {
      return 'Kategori maksimal ${AppConstants.maxCategoryLength} karakter';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'URL tidak valid';
    }
    return null;
  }

  static String? positiveInteger(String? value, {String fieldName = 'Nilai'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return '$fieldName harus angka positif';
    }
    return null;
  }

  static String? nonNegativeInteger(String? value, {String fieldName = 'Nilai'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      return '$fieldName tidak boleh negatif';
    }
    return null;
  }
}