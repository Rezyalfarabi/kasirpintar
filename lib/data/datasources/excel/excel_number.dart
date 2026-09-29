/// Pembacaan angka dari sel Excel.
///
/// Sel bisa datang sebagai angka (`15000`), sebagai teks dengan pemisah ribuan
/// (`15.000`, `15,000`, `1.500.000`), atau sebagai teks yang bukan angka sama
/// sekali (`Rp15.000`). Pustaka inti hanya memahami dua kasus pertama kalau
/// formatnya persis, dan diam-diam mengubah sisanya jadi nol.
///
///
/// Fungsi di sini selalu mengembalikan `null` untuk masukan yang bukan angka,
/// supaya pemanggil bisa membedakan "tidak terbaca" dari "benar-benar nol".
library;

/// Mengubah teks sel Excel menjadi bilangan bulat.
///
/// Mengembalikan `null` bila teksnya bukan angka yang bisa dipastikan —
/// termasuk teks bercampur seperti `Rp15.000` dan angka desimal ambigu seperti
/// `1.5` yang bisa berarti satu koma lima atau seribu lima.
///
/// ### Aturan pemisah ribuan
///
/// Pemisah ribuan hanya dikenali kalau polanya lengkap: satu sampai tiga digit,
/// lalu kelompok tepat tiga digit yang diulang. `1.000` dan `1,000,000` dibaca
/// sebagai seribu dan sejuta. `15000.50` tidak cocok pola itu, jadi ditolak
/// alih-alih berubah jadi `1500050`.
///
/// ### Argumen `roundDecimal`
///
/// Dua layanan punya kebutuhan berbeda. Tambah stok memakai kolom jumlah yang
/// wajar bisa berisi desimal, jadi `24,0` dibulatkan menjadi `24`. Impor produk
/// memakai harga yang harus bulat, jadi desimal ditolak supaya operator
/// melihat alasannya, bukan menerima angka yang salah diam-diam.
int? parseExcelInt(String raw, {bool roundDecimal = false}) {
  // Spasi di dalam angka masih sering muncul dari hasil salin-tempel.
  final text = raw.trim().replaceAll(RegExp(r'\s'), '');
  if (text.isEmpty) return null;

  final thousandsDot = RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(text);
  final thousandsComma = RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(text);
  if (thousandsDot || thousandsComma) {
    return int.tryParse(text.replaceAll('.', '').replaceAll(',', ''));
  }

  if (RegExp(r'^-?\d+$').hasMatch(text)) {
    return int.tryParse(text);
  }

  if (roundDecimal && RegExp(r'^-?\d+[.,]\d+$').hasMatch(text)) {
    // Koma desimal dipakai di sebagian besar spreadsheet lokal, jadi keduanya
    // ditukar ke titik sebelum diurai.
    return double.tryParse(text.replaceAll(',', '.'))?.round();
  }

  return null;
}
