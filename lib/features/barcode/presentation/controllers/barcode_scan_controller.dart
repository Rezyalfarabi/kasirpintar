import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kasir_pintar/data/models/product.dart';
import 'package:kasir_pintar/data/repositories/product_repository.dart';

class BarcodeScanState {
  final bool isScanning;
  final String? scannedBarcode;
  final Product? foundProduct;
  final String? error;
  final bool isProcessing;

  BarcodeScanState({
    this.isScanning = true,
    this.scannedBarcode,
    this.foundProduct,
    this.error,
    this.isProcessing = false,
  });

  BarcodeScanState copyWith({
    bool? isScanning,
    String? scannedBarcode,
    Product? foundProduct,
    String? error,
    bool? isProcessing,
  }) {
    return BarcodeScanState(
      isScanning: isScanning ?? this.isScanning,
      scannedBarcode: scannedBarcode ?? this.scannedBarcode,
      foundProduct: foundProduct ?? this.foundProduct,
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class BarcodeScanController extends StateNotifier<BarcodeScanState> {
  final ProductRepository _repository;
  MobileScannerController? _scannerController;

  BarcodeScanController(this._repository) : super(BarcodeScanState()) {
    _initScanner();
  }

  void _initScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  Future<void> onBarcodeDetected(BarcodeCapture capture) async {
    if (state.isProcessing) return;
    
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    state = state.copyWith(isProcessing: true, scannedBarcode: barcode);
    await _scannerController?.stop();

    try {
      final product = await _repository.getProductByBarcode(barcode);
      state = state.copyWith(
        isProcessing: false,
        foundProduct: product,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  void resumeScanning() {
    state = state.copyWith(isScanning: true, scannedBarcode: null, foundProduct: null, error: null);
    _scannerController?.start();
  }

  void pauseScanning() {
    _scannerController?.stop();
    state = state.copyWith(isScanning: false);
  }

  Future<void> toggleTorch() async {
    await _scannerController?.toggleTorch();
  }

  void switchCamera() {
    _scannerController?.switchCamera();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }
}