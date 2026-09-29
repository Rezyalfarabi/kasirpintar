# Analisis Struktur Aplikasi — Kasir Pintar

Dokumen ini memetakan struktur kode, batas tanggung jawab tiap lapisan, alur
data utama, temuan yang perlu dibereskan, dan konfigurasi Android/iOS.

---

## 1. Ringkasan

Kasir Pintar adalah aplikasi point-of-sale (POS) untuk toko retail kecil. Satu
kode Dart berjalan di tiga target: web, Android, dan iOS. Semua data disimpan
lokal di perangkat (SQLite lewat Drift) — tidak ada backend, tidak ada akun,
tidak ada sinkronisasi antar perangkat.

| Aspek | Nilai |
| --- | --- |
| Bahasa | Dart 3.3+ (Flutter 3.44.6) |
| State management | Riverpod 2 (`StateNotifierProvider`) |
| Navigasi | `go_router` 14 |
| Database | Drift 2 / SQLite, `schemaVersion = 3` |
| Arsitektur | Feature-first, tiga lapisan: presentation → repository → datasource |
| Entry point | `lib/main.dart` |
| Target | web, Android (API 24+), iOS (13.0+) |

---

## 2. Peta Direktori

```
lib/
├── main.dart                     # bootstrap: buka DB -> ProviderScope -> MaterialApp.router
├── shared_widgets.dart           # barrel export untuk shared_widgets/
│
├── core/                         # hal yang tidak dimiliki fitur tertentu
│   ├── constants/                # app_constants.dart, receipt_config.dart
│   ├── di/                       # providers.dart - satu-satunya tempat wiring Riverpod
│   ├── errors/                   # failures.dart, exception_handler.dart
│   ├── theme/                    # warna, radius, spacing, text style, app_theme
│   └── utils/                    # format, validasi, resolver gambar, bridge berkas per platform
│
├── data/                         # sumber kebenaran data, tidak tahu UI
│   ├── datasources/
│   │   ├── excel/                # excel_import_service, excel_export_service, excel_stock_service
│   │   ├── local/                # app_database.dart (+ .g.dart), koneksi DB per platform
│   │   └── pdf/                  # receipt_pdf_generator.dart
│   ├── models/                   # Product, Transaction, TransactionItem, StockMovement
│   └── repositories/             # kontrak + implementasi (impl/)
│
├── features/                     # satu folder per fitur
│   ├── barcode/                  # pemindai barcode (kamera)
│   ├── excel_import/             # impor produk dari .xlsx
│   ├── product/                  # daftar + form produk
│   ├── receipt/                  # cetak/bagikan struk
│   ├── stock_history/            # jejak audit perubahan stok
│   ├── stock_in/                 # tambah stok (manual & dari .xlsx)
│   └── transaction/              # layar kasir, keranjang, riwayat penjualan
│
├── routing/app_router.dart       # 9 rute go_router
└── shared_widgets/               # komponen UI generik, tidak tahu fitur
    └── app_bar/ badges/ buttons/ inputs/ layout/
```

### Konvensi di dalam `features/<fitur>/`

```
presentation/
├── pages/         # widget halaman
├── widgets/       # widget khusus fitur
└── controllers/   # StateNotifier: sementara state UI + orkestrasi repository
```

Tidak ada folder `domain/`. Aturan bisnis seperti "stok tidak boleh negatif" atau
"hapus produk berarti soft delete" hidup di `app_database.dart`, bukan di service
domain khusus. Itu pilihan sadar untuk aplikasi sekecil ini, tapi artinya
menambah aturan bisnis berarti menyentuh lapisan data.

---

## 3. Alur Data

### Menambah produk manual

```
ProductFormPage
  └─ ProductFormController            validasi field lewat Validators
      └─ ProductRepository.createProduct
          └─ ProductDao.insertProduct      satu transaksi DB
              ├─ INSERT products
              └─ INSERT stock_movements   (source: 'create', 0 -> stok)
```

### Transaksi kasir

```
TransactionPage -> CartController (tambah/kurang, total, kembalian)
  └─ TransactionController.checkout
      └─ TransactionRepository
          └─ TransactionDao.insertTransactionWithItems   satu transaksi DB
              ├─ INSERT transactions
              ├─ INSERT transaction_items  per item
              ├─ UPDATE products  SET stock = max(0, stock - qty)
              └─ INSERT stock_movements  (source: 'sale', note: "Transaksi #id")
```

Stok tidak pernah berubah tanpa jejak. Tabel `stock_movements` bersifat
append-only, dan setiap perubahan stok — buat, ubah form, impor, jual, hapus —
mengisinya di dalam transaksi yang sama dengan perubahannya.

### Impor Excel

```
ExcelImportPage
  └─ ExcelImportController
      ├─ FilePicker -> Uint8List
      ├─ ExcelImportService.importFromBytes   parse + validasi per baris
      ├─ preview (valid / error per baris)
      └─ importValidRows() | importWithUpdateDuplicates()
          └─ ProductRepository  (pencocokan duplikat lewat barcode)
```

Spesifikasi format berkasnya ada di `PANDUAN_IMPORT_EXCEL.md`.

---

## 4. Skema Database

`app_database.dart`, `schemaVersion = 3`.

| Tabel | Kolom penting | Catatan |
| --- | --- | --- |
| `products` | `barcode` **UNIQUE**, `name`, `price`, `stock`, `category`, `image_source`, `image_path`, `image_bytes`, `is_deleted` | `barcode` unik adalah kunci pencocokan untuk import Excel. Gambar disimpan sebagai **BLOB** supaya terbaca identik di web dan native. Hapus = soft delete (`is_deleted = 1`). |
| `transactions` | `date`, `total_price`, `paid_amount`, `change_amount`, `pdf_path` | `pdf_path` diisi setelah struk disimpan ke disk (hanya di native). |
| `transaction_items` | `transaction_id` (FK cascade), `product_id` (FK), `product_name` (denormalisasi), `qty`, `unit_price`, `subtotal` | `product_name` disimpan ulang karena produk bisa dihapus setelah penjualan. |
| `stock_movements` | `product_id` (**tanpa FK**), `product_name`, `delta`, `stock_before`, `stock_after`, `source`, `note`, `created_at` | Append-only. Tanpa FK supaya riwayat tetap utuh walau produknya dihapus. |

Migrasi sekarang hanya menangani `from < 2` (tambah `image_bytes`) dan
`from < 3` (buat `stock_movements`). Jalur `from == 1` menuju versi 3 belum
diuji — perlu dipastikan sebelum ada rilis ke pengguna lama.

---

## 5. Bridge Per Platform

Hanya ada dua titik percabahan platform di seluruh `lib/`, keduanya memakai
conditional import:

| Bridge | Native (Android/iOS) | Web |
| --- | --- | --- |
| `core/utils/platform_files.dart` | `platform_files_native.dart` — tulis ke `getApplicationDocumentsDirectory()` | `platform_files_web.dart` — unduh lewat browser |
| `data/datasources/local/database_connection.dart` | `database_connection_native.dart` — `NativeDatabase(File(...))` | `database_connection_web.dart` — `WasmDatabase` |

Konsekuensi praktis: fitur yang butuh filesystem hanya bekerja penuh di
Android/iOS. Receipt PDF di web masih bisa dibuat dan dicetak, tapi tidak
tersimpan.

---

## 6. Peta Rute

| Path | Nama | Halaman |
| --- | --- | --- |
| `/` | `transaction` | Layar kasir (tab default) |
| `/products` | `products` | Daftar produk + ekspor Excel |
| `/product-form?id=&barcode=` | `productForm` | Tambah / ubah produk |
| `/excel-import` | `excelImport` | Impor produk dari `.xlsx` |
| `/stock-in` | `stockIn` | Tambah stok (manual dan dari `.xlsx`) |
| `/stock-history?productId=` | `stockHistory` | Jejak audit stok |
| `/history` | `history` | Riwayat transaksi |
| `/receipt/:id` | `receipt` | Struk PDF |
| `/scan` | `barcodeScan` | Pindai barcode |

Navigasi bawah berupa lima tab (`AppNavigationBar`): Kasir, Produk, Tambah
Stok, Riwayat, dan pemindai.

---

## 7. Temuan

### Yang sudah rapi

- `schemaVersion` + `MigrationStrategy` benar-benar dipakai, bukan sekadar
  ada.
- Stok tidak pernah berubah tanpa jejak, ditegakkan di dalam transaksi DB.
- `barcode` sebagai kunci unik dipakai konsisten di DAO, repository, dan logika
  import Excel.
- Conditional import dipakai hemat — hanya dua, tidak ada `kIsWeb` atau
  `defaultTargetPlatform` yang tercebar di seluruh kode.
- 93 test otomatis mencakup parsing Excel, ekspor, struk PDF, jejak audit stok,
  dan smoke test tampilan di lebar 360px.
- `flutter analyze` bersih.

### Perlu dibereskan

| Temuan | Lokasi | Dampak |
| --- | --- | --- |
| Kolom `kategori` **wajib ada sebagai header**, padahal nilainya boleh kosong dan di form kategori bersifat opsional. | `app_constants.dart:18` | Berkas tanpa kolom kategori ditolak, padahal tidak ada data yang hilang. |
| Empat dependensi tidak terpakai di `lib/`: `permission_handler`, `cached_network_image`, `share_plus`, `uuid`. Resolver gambar memakai `NetworkImage` bawaan, bukan `cached_network_image`. | `pubspec.yaml` | Bobot build dan surface attack yang tidak perlu. |
| `riverpod_annotation` + `riverpod_generator` ada sebagai dev dependency tetapi tidak dipakai — semua provider ditulis manual di `core/di/providers.dart`. | `pubspec.yaml` | codegen yang tidak perlu. |
| Migrasi `schemaVersion` 1 → 2 → 3 belum lengkap. | `app_database.dart:92` | Pengguna versi lama bisa kehilangan data saat upgrade. |
| Build Android gagal sebelum overhaul `compileSdk` (lihat bagian 8). | `android/build.gradle.kts` | Sudah diperbaiki. |
| `mobile_scanner` dan `share_plus` masih menerapkan Kotlin Gradle Plugin lawas; Flutter akan menolak build seperti ini pada versi mendatang. | `pubspec.lock` | Peringatan, belum fatal. |

### Perbaikan yang sudah selesai

Empat jebakan pembacaan Excel yang pernah ada di `ExcelImportService` sudah
dibereskan sekaligus:

- **Barcode duplikat di dalam satu berkas** dideteksi dan dilaporkan
  `Barcode sama dengan baris N`, bukan dilewati atau ditimpa diam-diam.
- **Batas yang sama dengan form manual** ditegakkan: nama ≤ 100, kategori ≤ 50,
  barcode ≤ 50, harga 1–999999999, stok 0–999999. Produk yang ditolak form pasti
  ditolak impor, dan sebaliknya.
- **Pemisah ribuan dibaca di `stok` maupun `harga`** lewat `parseExcelInt`
  (`excel_number.dart`): `10.000`, `10,000`, dan `10000` setara. Desimal
  (`15000.50`) dan teks bercampur (`Rp15.000`) ditolak dengan pesan yang jelas,
  bukan diam-diam jadi angka yang salah.
- **Nol pada kolom `harga`** dilaporkan sebagai `Harga harus lebih dari 0`,
  bukan `Harga maksimal ...`. Batas bawah dan batas atas menghasilkan pesan
  berbeda karena perbaikannya juga berbeda.

### Perbaikan barcode kembar dalam satu berkas

`ExcelImportService` sekarang menahan barcode yang sudah dipakai baris sebelumnya
di berkas yang sama, dan melaporkan baris berikutnya sebagai
`Barcode sama dengan baris N`. Baris pertama tetap dipakai.

Tiga keputusan desain yang perlu dijaga kalau aturan ini diubah nanti:

- **Pencocokan case-sensitive.** `abc` dan `ABC` tetap dua produk, sama seperti
  constraint `UNIQUE` di SQLite yang juga case-sensitive. Menjadikannya
  case-insensitive akan menolak baris yang sebenarnya bisa tersimpan.
- **Barcode baru diklaim setelah baris lolos semua validasi lain.** Kalau baris
  cacat ikut mengunci barcode-nya, baris sah berikutnya dengan barcode sama akan
  ditolak tanpa alasan yang benar karena pendahulunya tidak pernah masuk.
- **Baris pertama menang, bukan baris terakhir.** Ini yang membuat hasilnya
  bisa diprediksi, dan pesan errornya menyebut nomor baris pendahulunya.

`ExcelStockService` sudah punya aturan serupa dengan kunci
`barcode:<nilai>` atau `nama:<nilai lowercase>` ketika barcode kosong — beda
kecil yang perlu diingat: import produk mewajibkan barcode, tambah stok tidak.

---

## 8. Dukungan Android & iOS

Folder `android/` dan `ios/` dibuat dengan:

```bash
flutter create --platforms=android,ios --org com.rezyalfarabi --project-name kasir_pintar .
```

`lib/main.dart` dan `pubspec.yaml` tidak disentuh — scaffold hanya menambahkan
folder platform yang sebelumnya belum ada. Folder `web/` yang sudah ada juga
tetap utuh.

### Yang dikonfigurasi manual

| Berkas | Perubahan | Alasan |
| --- | --- | --- |
| `android/app/src/main/AndroidManifest.xml` | `<uses-permission CAMERA>`, `uses-feature` kamera opsional, `android:label` "Kasir Pintar" | `mobile_scanner` butuh kamera. Kamera ditandai `required="false"` supaya aplikasi tetap jalan di perangkat tanpa kamera. |
| `android/build.gradle.kts` | Paksa `compileSdk = 36` untuk semua subproject | `file_picker`, `mobile_scanner`, `share_plus`, dan `printing` masih mengunci `compileSdk 34`, sedangkan `flutter_plugin_android_lifecycle` menuntut 36. Akibatnya `checkAarMetadata` gagal sebelum aplikasi sempat dikompilasi. Memaksa di root lebih murah daripada menaikkan tiap plugin satu per satu, dan menghindari break API pada `mobile_scanner` 5 → 7. |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, `CFBundleName` | iOS menolak akses kamera dan galeri tanpa alasan yang tertulis. Dua kunci terakhir membuat template Excel dan berkas hasil ekspor bisa diambil lewat Files app. |

Nilai bawaan Flutter yang dibiarkan karena sudah memenuhi kebutuhan:

- `minSdk = 24`, `targetSdk = 36`, `compileSdk = 36`
- `IPHONEOS_DEPLOYMENT_TARGET = 13.0` — cukup untuk `mobile_scanner` (12+),
  `image_picker` (12+), dan `printing` (12+)
- NDK `28.2.13676358`

### Verifikasi

```bash
flutter analyze          # No issues found!
flutter test             # 93 test, semua lulus
flutter build apk --debug
```

Hasil: `build/app/outputs/flutter-apk/app-debug.apk`.

iOS **tidak bisa dibangun di Windows** — `flutter build ios` butuh macOS dengan
Xcode. Struktur `ios/` sudah lengkap dan `pod install` berjalan sendiri saat
build pertama di Mac. Yang perlu dikerjakan manual di Mac:

1. Ganti bundle ID di Xcode ke milikmu (bawaan: `com.rezyalfarabi.kasirPintar`).
2. Signing & Capabilities — pilih Apple Development team.
3. `flutter build ipa` untuk rilis.

---

## 9. Rekomendasi Prioritas

1. Validasi impor Excel sudah disamakan dengan `Validators` — **selesai**:
   batas panjang dan nilai `ExcelImportService` sekarang sama persis dengan
   form manual.
2. Pembacaan `stok` dan `harga` sudah lewat `parseExcelInt`, pemisah ribuan
   terbaca dan angka yang gagal dibaca dilaporkan — **selesai**.
3. Deteksi barcode duplikat di dalam satu berkas — **selesai**.
4. Buang dependensi yang tidak terpakai: `permission_handler`,
   `cached_network_image`, `share_plus`, `uuid`, `riverpod_annotation`.
5. Lengkapi migrasi `schemaVersion` 1 → 2 → 3 sebelum ada rilis ke pengguna lama.
6. Naikkan `mobile_scanner` dan `share_plus`, lalu hapus paksaan `compileSdk` di
   `android/build.gradle.kts`.
7. Jadikan `PANDUAN_IMPORT_EXCEL.md` rujukan operator toko.
