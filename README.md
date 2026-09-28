# Kasir Pintar

Aplikasi kasir (point-of-sale) untuk toko retail kecil-menengah, dibuat dengan
Flutter. Satu basis kode berjalan di **web, Android, dan iOS**. Semua data
disimpan lokal di perangkat — tanpa server, tanpa akun, tanpa langganan.

## Fitur

- **Kasir** — keranjang, scan barcode, pembayaran, hitung kembalian otomatis.
- **Produk** — CRUD lengkap, filter kategori, saringan stok menipis dan habis,
  lampiran gambar dari kamera, galeri, atau URL.
- **Impor & Ekspor Excel** — tarik ribuan produk dari `.xlsx`, atau ekspor
  daftar produk untuk disunting di Excel.
- **Tambah Stok** — manual maupun dari `.xlsx`, dengan laporan baris gagal.
- **Riwayat Stok** — jejak audit append-only: setiap perubahan stok tercatat
  lengkap dengan stok sebelum, sesudah, sumber, dan catatannya.
- **Struk PDF** — cetak, simpan, atau bagikan.
- **Riwayat Transaksi** dan rekap penjualan.

## Menjalankan

```bash
flutter pub get
flutter run -d chrome          # web
flutter run -d <android-device>   # Android
flutter run -d <ios-device>       # iOS (butuh macOS + Xcode)
```

Untuk build rilis:

```bash
flutter build apk --release        # Android
flutter build appbundle --release  # Android, untuk Play Store
flutter build ipa                  # iOS, hanya di macOS
flutter build web                  # web
```

### Persiapan per platform

**Android** — `minSdk 24`, `targetSdk 36`, `compileSdk 36`. Kamera ditandai
opsional (`required="false"`) supaya aplikasi tetap jalan di perangkat tanpa
kamera. `android/build.gradle.kts` memaksa `compileSdk 36` untuk semua
subproject karena beberapa plugin masih mengunci versi lebih lama.

**iOS** — deployment target 13.0. Ganti bundle ID dan pilih Apple Development
team di Xcode sebelum build. Keterangan penggunaan kamera dan galeri sudah
terisi di `ios/Runner/Info.plist`; `UIFileSharingEnabled` diaktifkan supaya
berkas Excel bisa diambil lewat Files app.

**Web** — butuh `web/sqlite3.wasm` dan `web/drift_worker.js` (keduanya sudah
ada di repo) agar Drift bisa berjalan di browser.

## Arsitektur

Feature-first, tiga lapisan: `presentation` (pages, widgets, controllers) →
`repository` (kontrak + implementasi) → `datasource` (Drift/SQLite, Excel, PDF).

```
lib/
├── core/       # konstanta, DI, error, tema, util, bridge per platform
├── data/       # models, datasources, repositories
├── features/   # barcode, excel_import, product, receipt, stock_history,
│               # stock_in, transaction
├── routing/    # go_router
└── shared_widgets/
```

State dikelola Riverpod 2, navigasi `go_router`, database lokal Drift/SQLite
(`schemaVersion = 3`). Percabangan platform hanya ada dua titik, keduanya
memakai conditional import.

## Dokumentasi

| Berkas | Isi |
| --- | --- |
| [`ANALISIS_STRUKTUR.md`](ANALISIS_STRUKTUR.md) | Analisis struktur, alur data, skema database, temuan, konfigurasi Android/iOS |
| [`PANDUAN_IMPORT_EXCEL.md`](PANDUAN_IMPORT_EXCEL.md) | Persyaratan format `.xlsx` untuk impor produk dan tambah stok |
| [`PRD_Aplikasi_Kasir.md`](PRD_Aplikasi_Kasir.md) | Product requirements document |
| [`desainbrief.md`](desainbrief.md) | Brief desain visual dan aturan kontrak desain |
| [`TESTING.md`](TESTING.md) | Hasil uji alur utama dan manual |

## Ringkasan Persyaratan Impor Excel

Berkas harus **`.xlsx`** (bukan `.xls` atau `.csv`), **sheet pertama**, baris 1
berisi judul kolom. Lima kolom wajib: `nama`, `barcode`, `harga`, `stok`,
`kategori`. `harga` harus bilangan bulat > 0 dan `stok` tidak boleh negatif.
Detail lengkap termasuk jebakan format ada di
[`PANDUAN_IMPORT_EXCEL.md`](PANDUAN_IMPORT_EXCEL.md).

## Pengujian

```bash
flutter analyze   # harus "No issues found!"
flutter test      # 71 test
```

## Lisensi

Font Inter memakai SIL Open Font License 1.1 — lihat `LICENSE-Inter.txt`.
