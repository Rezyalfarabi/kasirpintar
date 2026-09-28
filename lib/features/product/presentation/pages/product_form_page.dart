import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/features/product/presentation/controllers/product_form_controller.dart';
import 'package:kasir_pintar/features/product/presentation/widgets/image_source_picker.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final int? productId;

  /// Terisi saat halaman dibuka dari hasil scan barcode yang belum terdaftar,
  /// supaya nomor yang sudah dipindai tidak perlu diketik ulang.
  final String? initialBarcode;

  const ProductFormPage({super.key, this.productId, this.initialBarcode});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  @override
  void initState() {
    super.initState();
    final initialBarcode = widget.initialBarcode;
    if (widget.productId != null || initialBarcode == null || initialBarcode.isEmpty) {
      return;
    }

    // Ditulis setelah frame pertama: membangun ulang form saat build berjalan
    // akan memicu error "setState during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = productFormControllerProvider(null);
      if (ref.read(provider).barcode.isEmpty) {
        ref.read(provider.notifier).updateBarcode(initialBarcode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.productId;
    final isEditing = productId != null;
    final state = ref.watch(productFormControllerProvider(productId));
    final controller = ref.read(productFormControllerProvider(productId).notifier);

    final nameController = TextEditingController(text: state.name);
    final barcodeController = TextEditingController(text: state.barcode);
    final priceController = TextEditingController(text: state.price);
    final stockController = TextEditingController(text: state.stock);
    final categoryController = TextEditingController(text: state.category);

    return ResponsiveScaffold(
      appBar: AppBarWidget(title: isEditing ? 'Edit Produk' : 'Tambah Produk'),
      body: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLine.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.dangerLine),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.dangerLine),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(state.error!, style: AppTextStyles.body.copyWith(color: AppColors.dangerLine))),
                    ],
                  ),
                ),
              InputField(
                label: 'Nama Produk *',
                hint: 'Masukkan nama produk',
                controller: nameController,
                onChanged: controller.updateName,
                errorText: state.fieldErrors['name']?.isNotEmpty == true ? state.fieldErrors['name'] : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              InputField(
                label: 'Barcode *',
                hint: 'Scan atau masukkan barcode',
                controller: barcodeController,
                onChanged: controller.updateBarcode,
                errorText: state.fieldErrors['barcode']?.isNotEmpty == true ? state.fieldErrors['barcode'] : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: NumericInputField(
                      label: 'Harga *',
                      hint: '0',
                      controller: priceController,
                      onChanged: controller.updatePrice,
                      allowDecimal: false,
                      errorText: state.fieldErrors['price']?.isNotEmpty == true ? state.fieldErrors['price'] : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: NumericInputField(
                      label: 'Stok *',
                      hint: '0',
                      controller: stockController,
                      onChanged: controller.updateStock,
                      allowDecimal: false,
                      errorText: state.fieldErrors['stock']?.isNotEmpty == true ? state.fieldErrors['stock'] : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              InputField(
                label: 'Kategori',
                hint: 'Contoh: Makanan, Minuman',
                controller: categoryController,
                onChanged: controller.updateCategory,
                errorText: state.fieldErrors['category']?.isNotEmpty == true ? state.fieldErrors['category'] : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              ImageSourcePicker(
                state: state,
                onCamera: controller.pickImageFromCamera,
                onGallery: controller.pickImageFromGallery,
                productId: productId,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Batal',
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: isEditing ? 'Simpan Perubahan' : 'Simpan Produk',
                      onPressed: state.isLoading ? null : () => _handleSave(context, controller),
                      isLoading: state.isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, ProductFormController controller) async {
    final success = await controller.save();
    if (success && context.mounted) {
      context.pop();
    }
  }
}