class AppConstants {
  static const String appName = 'Kasir Pintar';
  static const String appVersion = '1.0.0';
  static const String databaseName = 'kasir_pintar.db';
  static const int lowStockThreshold = 5;
  static const int maxImageDimension = 800;
  static const int imageQuality = 80;
  static const String currencySymbol = 'Rp';
  static const String currencyCode = 'IDR';
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd MMM yyyy HH:mm';
  static const String receiptDateFormat = 'dd/MM/yyyy HH:mm';
  static const int defaultPageSize = 50;
  static const Duration debounceDuration = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const String excelTemplateName = 'template_import_produk.xlsx';
  static const List<String> excelRequiredColumns = [
    'nama',
    'barcode',
    'harga',
    'stok',
    'kategori',
  ];
  static const List<String> imageSourceTypes = [
    'camera',
    'gallery',
    'url',
  ];
  static const int maxBarcodeLength = 50;
  static const int maxNameLength = 100;
  static const int maxCategoryLength = 50;
  static const int maxPrice = 999999999;
  static const int maxStock = 999999;
}