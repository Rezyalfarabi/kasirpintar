import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/data/datasources/excel/excel_number.dart';

void main() {
  group('angka Excel tanpa pembulatan desimal', () {
    test('angka polos dan pemisah ribuan terbaca', () {
      expect(parseExcelInt('0'), 0);
      expect(parseExcelInt('24'), 24);
      expect(parseExcelInt('10000'), 10000);
      expect(parseExcelInt('15.000'), 15000);
      expect(parseExcelInt('15,000'), 15000);
      expect(parseExcelInt('1.500.000'), 1500000);
      expect(parseExcelInt('1,500,000'), 1500000);
      expect(parseExcelInt('999999999'), 999999999);
    });

    test('spasi di dalam dan di tepi angka dibuang', () {
      expect(parseExcelInt('  24  '), 24);
      expect(parseExcelInt('1 000'), 1000);
      expect(parseExcelInt('15 . 000'), 15000);
    });

    test('tanda minus dibaca sebagai nilai negatif', () {
      expect(parseExcelInt('-5'), -5);
    });

    // Kasus ini yang paling merusak: "15000.50" tidak cocok pola ribuan, dan
    // implementasi lama membuang titiknya sehingga hasilnya 1500050.
    test('desimal tidak dianggap pemisah ribuan dan ditolak', () {
      expect(parseExcelInt('15000.50'), isNull);
      expect(parseExcelInt('15000,50'), isNull);
    });

    test('teks yang bukan angka ditolak, bukan jadi nol', () {
      expect(parseExcelInt('Rp15.000'), isNull);
      expect(parseExcelInt('15rb'), isNull);
      expect(parseExcelInt('abc'), isNull);
      expect(parseExcelInt(''), isNull);
      expect(parseExcelInt('   '), isNull);
    });

    test('pemisah ribuan harus lengkap', () {
      expect(parseExcelInt('1.50'), isNull);
      expect(parseExcelInt('1.5'), isNull);
      expect(parseExcelInt('1.0000'), isNull);
    });
  });

  group('angka Excel dengan pembulatan desimal', () {
    test('satu koma nol dibulatkan menjadi bilangan bulat', () {
      expect(parseExcelInt('24,0', roundDecimal: true), 24);
      expect(parseExcelInt('24.0', roundDecimal: true), 24);
    });

    test('pecahan lain dibulatkan ke terdekat', () {
      expect(parseExcelInt('24,4', roundDecimal: true), 24);
      expect(parseExcelInt('24,5', roundDecimal: true), 25);
      expect(parseExcelInt('1,5', roundDecimal: true), 2);
    });

    test('pemisah ribuan tetap menang sebelum desimal', () {
      expect(parseExcelInt('1.000', roundDecimal: true), 1000);
    });

    test('teks bercampur tetap ditolak walau pembulatan diizinkan', () {
      expect(parseExcelInt('24 pcs', roundDecimal: true), isNull);
    });
  });
}
