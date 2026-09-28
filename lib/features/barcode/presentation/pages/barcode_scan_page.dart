import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kasir_pintar/shared_widgets.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';
import 'package:kasir_pintar/core/utils/product_image.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/features/barcode/presentation/controllers/barcode_scan_controller.dart';

class BarcodeScanPage extends ConsumerStatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  ConsumerState<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends ConsumerState<BarcodeScanPage> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _scannerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(barcodeScanControllerProvider);
    final controller = ref.read(barcodeScanControllerProvider.notifier);

    return ResponsiveScaffold(
      appBar: AppBarWidget(
        title: 'Scan Barcode',
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: controller.toggleTorch,
            tooltip: 'Flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: controller.switchCamera,
            tooltip: 'Ganti Kamera',
          ),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: controller.onBarcodeDetected,
          ),
          _buildOverlay(context),
          if (scanState.scannedBarcode != null)
            _buildResultOverlay(context, controller, scanState),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.accentYellow, width: 3),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  color: AppColors.accentYellow,
                  child: Text(
                    'ARAHKAN BARCODE KE SINI',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay(BuildContext context, BarcodeScanController controller, BarcodeScanState state) {
    return ColoredBox(
      color: AppColors.overlay,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.baseWhite,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.foundProduct != null) ...[
                _buildProductCard(state.foundProduct!),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Scan Lagi',
                        onPressed: controller.resumeScanning,
                        leadingIcon: Icons.qr_code_scanner,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Tambah ke Keranjang',
                        onPressed: () => _addToCart(context, controller, state.foundProduct!),
                        leadingIcon: Icons.add_shopping_cart,
                      ),
                    ),
                  ],
                ),
              ] else if (state.error != null) ...[
                const Icon(Icons.error_outline, size: 48, color: AppColors.dangerLine),
                const SizedBox(height: AppSpacing.md),
                const Text('Barcode tidak ditemukan', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Barcode: ${state.scannedBarcode}',
                  style: AppTextStyles.barcode,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Buat produk baru?', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Scan Lagi',
                        onPressed: controller.resumeScanning,
                        leadingIcon: Icons.qr_code_scanner,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Buat Produk',
                        onPressed: () => _createProduct(context, state.scannedBarcode!),
                        leadingIcon: Icons.add,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                const Text('Mencari produk...', style: AppTextStyles.body),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.thumbnail),
                child: Container(
                  width: 60,
                  height: 60,
                  color: AppColors.offWhite,
                  child: _buildProductThumbnail(product),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.subheading, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Barcode: ${product.barcode}', style: AppTextStyles.barcode),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${CurrencyFormat.format(product.price)} • Stok: ${product.stock}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(Product product) {
    final provider = productImageProvider(
      imageSource: product.imageSource,
      imagePath: product.imagePath,
      imageBytes: product.imageBytes,
    );

    if (provider == null) {
      return const Icon(Icons.image_outlined, size: 32, color: AppColors.placeholder);
    }

    return Image(
      image: provider,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_outlined, size: 32, color: AppColors.placeholder),
    );
  }

  void _addToCart(BuildContext context, BarcodeScanController controller, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} ditambahkan ke keranjang')),
    );
    controller.resumeScanning();
  }

  void _createProduct(BuildContext context, String barcode) {
    context.push('/product-form?barcode=$barcode');
  }
}