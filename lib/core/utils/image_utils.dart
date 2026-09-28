import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';

/// Pengambilan gambar produk. Hasilnya berupa byte, bukan berkas di disk,
/// supaya bisa disimpan ke database dan dibaca di web maupun native.
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickBytesFromCamera() => _pick(ImageSource.camera);

  static Future<Uint8List?> pickBytesFromGallery() => _pick(ImageSource.gallery);

  static Future<Uint8List?> _pick(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: AppConstants.maxImageDimension.toDouble(),
      maxHeight: AppConstants.maxImageDimension.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );
    if (image == null) return null;
    return image.readAsBytes();
  }
}
