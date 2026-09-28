import 'package:intl/intl.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';

/// Satuan harga tunggal untuk seluruh aplikasi: **rupiah bulat** (`int`),
/// tanpa desimal/sen. Nilai ini yang disimpan di database, keranjang, dan
/// struk. Gunakan [format] untuk menampilkan dan [parse] untuk membaca input.
class CurrencyFormat {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static String format(int rupiah) {
    return _formatter.format(rupiah);
  }

  static int parse(String formatted) {
    final cleaned = formatted
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return int.tryParse(cleaned) ?? 0;
  }
}
