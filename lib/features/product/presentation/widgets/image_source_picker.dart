import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/features/product/presentation/controllers/product_form_controller.dart';

class ImageSourcePicker extends ConsumerWidget {
  final ProductFormState state;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final int? productId;

  const ImageSourcePicker({
    super.key,
    required this.state,
    required this.onCamera,
    required this.onGallery,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gambar Produk', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (state.hasImage)
          _buildPreview(context, ref),
        const SizedBox(height: AppSpacing.md),
        _buildSourceSelector(context, ref),
        if (state.imageSource == 'url') ...[
          const SizedBox(height: AppSpacing.md),
          InputField(
            label: 'URL Gambar',
            hint: 'https://example.com/gambar.jpg',
            controller: TextEditingController(text: state.imageUrl ?? ''),
            onChanged: (v) => ref.read(productFormControllerProvider(productId).notifier).updateImageUrl(v),
            errorText: state.fieldErrors['imageUrl']?.isNotEmpty == true ? state.fieldErrors['imageUrl'] : null,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildActionButtons(ref),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: _buildImage(),
          ),
        ),
        if (state.hasImage)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: InkWell(
              onTap: () => ref.read(productFormControllerProvider(productId).notifier).clearImage(),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.baseBlack.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(Icons.close, color: AppColors.baseWhite, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (state.imageUrl?.isNotEmpty == true) {
      return Image.network(state.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    if (state.localImageBytes != null) {
      return Image.memory(state.localImageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: AppColors.offWhite,
      child: Center(child: Icon(Icons.image_outlined, size: 48, color: AppColors.placeholder)),
    );
  }

  Widget _buildSourceSelector(BuildContext context, WidgetRef ref) {
    return SegmentedControl<String>(
      segments: const [
        Segment(value: 'camera', label: 'Kamera', icon: Icons.camera_alt),
        Segment(value: 'gallery', label: 'Galeri', icon: Icons.photo_library),
        Segment(value: 'url', label: 'URL', icon: Icons.link),
      ],
      selectedValue: state.imageSource,
      onChanged: (value) {
        if (value == 'camera') onCamera();
        if (value == 'gallery') onGallery();
        ref.read(productFormControllerProvider(productId).notifier).updateImageSource(value);
      },
    );
  }

  Widget _buildActionButtons(WidgetRef ref) {
    return Row(
      children: [
        if (state.imageSource != 'url' && state.hasImage)
          Expanded(child: SecondaryButton(label: 'Ganti', onPressed: state.imageSource == 'camera' ? onCamera : onGallery)),
        if (state.hasImage)
          Expanded(child: AppTextButton(label: 'Hapus Gambar', onPressed: () => ref.read(productFormControllerProvider(productId).notifier).clearImage())),
      ],
    );
  }
}
