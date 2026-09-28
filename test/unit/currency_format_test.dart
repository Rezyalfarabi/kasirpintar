import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/core/utils/currency_format.dart';

void main() {
  group('CurrencyFormat', () {
    test('menampilkan rupiah bulat tanpa pembagian 100', () {
      expect(CurrencyFormat.format(15000), contains('15.000'));
      expect(CurrencyFormat.format(0), contains('0'));
    });

    test('parse mengembalikan rupiah bulat dari input pengguna', () {
      expect(CurrencyFormat.parse('Rp 15.000'), 15000);
      expect(CurrencyFormat.parse('15000'), 15000);
      expect(CurrencyFormat.parse(''), 0);
    });
  });
}
