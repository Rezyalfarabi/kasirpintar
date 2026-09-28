# Product Requirement Document (PRD)
## Aplikasi Kasir Berbasis Flutter & Dart

**Versi:** 1.0
**Tanggal:** 27 September 2026
**Platform:** Android, iOS, Web (Flutter — single codebase)

---

## 1. Latar Belakang & Tujuan

Aplikasi kasir sederhana untuk membantu pencatatan transaksi penjualan, pengelolaan stok produk, dan pencetakan struk. Aplikasi dibangun dengan Flutter agar bisa berjalan di Android, iOS, dan Web dari satu basis kode.

**Tujuan utama:**
- Mempercepat proses input produk lewat barcode scanner.
- Memudahkan pengelolaan stok (tambah, lihat, ubah, hapus).
- Mempercantik data produk dengan gambar (kamera, galeri, atau URL).
- Mempercepat input massal produk lewat import Excel.
- Mencetak/menampilkan struk transaksi dalam bentuk PDF.

## 2. Ruang Lingkup (Scope)

Hanya modul **Kasir**. Tidak termasuk: manajemen multi-cabang, laporan keuangan lanjutan, integrasi payment gateway, multi-user role (admin/owner), atau sinkronisasi cloud real-time (kecuali disepakati di fase berikutnya).

### 2.1 Fitur In-Scope
| No | Fitur | Deskripsi Singkat |
|----|-------|-------------------|
| 1 | Barcode Scanner | Scan barcode produk untuk pencarian & transaksi cepat |
| 2 | Manajemen Stok (CRUD) | Tambah, lihat, ubah, hapus data produk & jumlah stok |
| 3 | Gambar Produk | Input gambar via kamera, galeri, atau tempel link URL |
| 4 | Import Produk via Excel | Upload file .xlsx untuk isi produk secara massal |
| 5 | Cetak Struk (PDF) | Generate PDF struk & tampilkan lewat `flutter_pdfview` |
| 6 | Transaksi Kasir | Input transaksi, hitung total, kembalian |

### 2.2 Out of Scope
- Manajemen banyak toko/cabang
- Laporan analitik/dashboard kompleks
- Payment gateway online
- Role & permission bertingkat (hanya 1 peran: kasir)
- Sinkronisasi data antar-device secara real-time

## 3. Target Pengguna
Kasir toko retail skala kecil-menengah yang butuh alat kasir cepat, ringan, dan bisa dipakai lintas perangkat (HP Android/iOS atau browser).

## 4. Functional Requirements

### 4.1 Barcode Scanner
- Scan barcode via kamera perangkat (mobile) dan input manual/webcam (web, sebagai fallback bila hardware scanner tidak tersedia).
- Hasil scan langsung mencari produk di database lokal berdasarkan kode barcode.
- Jika barcode tidak ditemukan → opsi langsung buat produk baru dengan barcode terisi otomatis.
- Package rekomendasi: `mobile_scanner` (support Android/iOS/Web).

### 4.2 Manajemen Stok (CRUD)
- **Create:** tambah produk baru (nama, barcode, harga, stok awal, kategori, gambar).
- **Read:** lihat daftar produk (list + search + filter kategori/stok menipis).
- **Update:** ubah data produk termasuk stok manual (mis. stok opname).
- **Delete:** hapus produk (soft delete disarankan agar histori transaksi tidak rusak).
- Validasi: barcode unik, stok tidak boleh negatif, harga > 0.

### 4.3 Gambar Produk (Multi-metode Input)
Mendukung 3 metode input gambar produk:
1. **Kamera** — ambil foto langsung.
2. **Galeri** — pilih gambar dari penyimpanan perangkat.
3. **Link URL** — tempel URL gambar (untuk web/gambar dari internet).

Package rekomendasi: `image_picker` (kamera & galeri, support Android/iOS/Web), `cached_network_image` (untuk render gambar dari URL beserta cache).

### 4.4 Import Produk via Excel
- Upload file `.xlsx` berisi kolom minimal: `nama, barcode, harga, stok, kategori`.
- Sistem membaca file, validasi format, tampilkan preview sebelum simpan.
- Jika ada barcode duplikat dengan data existing → beri opsi *skip* atau *update*.
- Sediakan **template Excel** yang bisa diunduh pengguna agar format konsisten.
- Package rekomendasi: `excel`, `file_picker`.

### 4.5 Cetak Struk (PDF)
- Setelah transaksi selesai, generate struk dalam format PDF (nama toko, daftar item, subtotal, total, kembalian, tanggal/waktu).
- Tampilkan PDF struk menggunakan `flutter_pdfview` untuk preview di dalam aplikasi.
- Sediakan opsi *share*/*download* PDF (mis. via `printing` atau `share_plus`) sebagai pelengkap, karena `flutter_pdfview` hanya untuk **menampilkan**, bukan mencetak ke printer fisik.
- Package rekomendasi: `pdf` (generate), `flutter_pdfview` (preview), `path_provider` (simpan file sementara).

> **Catatan teknis:** `flutter_pdfview` saat ini support Android & iOS. Untuk Web, dibutuhkan fallback (mis. render PDF pakai `pdf` + `printing` package yang cross-platform, atau tampilkan via iframe/blob di web). Ini perlu diputuskan di fase desain teknis agar fitur cetak struk tetap konsisten di 3 platform.

### 4.6 Transaksi Kasir
- Tambah item ke keranjang (via scan barcode atau pilih manual dari daftar produk).
- Ubah jumlah/qty item di keranjang.
- Hitung otomatis subtotal, total, dan kembalian dari uang dibayar.
- Setelah transaksi disimpan → stok produk otomatis berkurang.
- Simpan histori transaksi (untuk keperluan cetak ulang struk).

## 5. Non-Functional Requirements
- **Cross-platform:** wajib berjalan mulus di Android, iOS, dan Web dari satu codebase.
- **Performansi:** scan barcode & pencarian produk responsif (< 1 detik untuk database lokal).
- **Offline-first:** data produk & transaksi tersimpan lokal (database lokal), tidak wajib koneksi internet kecuali untuk fitur load gambar via URL.
- **Struktur kode rapi:** mengikuti clean architecture / layered structure (lihat bagian 7).
- **Maintainability:** tidak ada dead code atau widget tak terpakai (lihat bagian 8 — Development Rules).

## 6. Data Model (Ringkas)

**Product**
```
id, barcode (unique), nama, harga, stok, kategori,
imageSource (camera/gallery/url), imagePath/imageUrl,
createdAt, updatedAt, isDeleted
```

**Transaction**
```
id, tanggal, daftarItem[{ productId, namaProduk, qty, hargaSatuan, subtotal }],
totalHarga, uangDibayar, kembalian, pdfPath (opsional cache path struk)
```

## 7. Rekomendasi Arsitektur & Struktur Folder

Disarankan pola **layered/feature-based architecture** agar rapi dan mudah di-maintain:

```
lib/
 ├─ core/               # konstanta, tema, util, error handling
 ├─ data/
 │   ├─ models/
 │   ├─ repositories/
 │   └─ datasources/    # local db, excel parser, dsb
 ├─ features/
 │   ├─ product/        # CRUD produk & gambar
 │   ├─ barcode/        # fitur scan
 │   ├─ excel_import/
 │   ├─ transaction/
 │   └─ receipt/        # generate & preview PDF
 ├─ shared_widgets/
 └─ main.dart
```

- **State management:** disarankan `Provider`/`Riverpod`/`Bloc` (pilih 1, konsisten di seluruh proyek).
- **Local database:** `sqflite` (mobile) + `sqflite_common_ffi_web` atau `Hive`/`drift` (agar sama-sama jalan di Web).
- Pisahkan **UI**, **logic (state/controller)**, dan **data layer** secara jelas per fitur.

## 8. Development Rules (Wajib Diikuti Tim)

1. **Struktur rapi & konsisten** — ikuti struktur folder di bagian 7, penamaan file/class konsisten (mis. `snake_case` untuk file, `PascalCase` untuk class).
2. **Code review wajib** di setiap akhir sesi coding maupun saat plan fitur baru:
   - Cek dan hapus **dead code** (fungsi/variabel tak terpakai).
   - Cek **widget yang tidak punya fungsi** (mis. `Container` kosong berlapis, widget duplikat).
   - Pastikan tidak ada `print()`/debug log tertinggal di kode produksi.
3. **Cross-platform check** — setiap fitur baru wajib ditest di Android, iOS, dan Web sebelum dianggap selesai (khususnya fitur kamera, file picker, dan PDF viewer yang punya perilaku beda per platform).
4. **Review & testing setiap ada perubahan/fitur baru** — tidak boleh merge/lanjut ke fitur berikutnya sebelum:
   - Fitur diuji manual di 3 platform.
   - Tidak ada regresi di fitur lama (mis. tambah fitur Excel import tidak merusak fitur CRUD manual).

## 9. Daftar Package Utama (Usulan)

| Kebutuhan | Package |
|---|---|
| Barcode scan | `mobile_scanner` |
| Ambil gambar (kamera/galeri) | `image_picker` |
| Render gambar dari URL | `cached_network_image` |
| Pilih file (Excel) | `file_picker` |
| Baca/tulis Excel | `excel` |
| Generate PDF struk | `pdf` |
| Preview PDF | `flutter_pdfview` (mobile) + fallback web |
| Simpan file sementara | `path_provider` |
| Database lokal | `sqflite` / `drift` / `Hive` |
| State management | `Riverpod` / `Bloc` / `Provider` (pilih satu) |

## 10. Alur Pengguna Utama (High-Level)

1. Kasir buka aplikasi → halaman utama daftar produk/transaksi.
2. Scan barcode produk → otomatis masuk ke keranjang transaksi.
3. Jika produk baru → kasir input manual (nama, harga, stok, gambar).
4. Selesai belanja → input uang dibayar → sistem hitung kembalian.
5. Simpan transaksi → stok otomatis berkurang → struk PDF ter-generate.
6. Struk ditampilkan via PDF viewer → kasir bisa share/simpan/cetak.

## 11. Milestone / Roadmap Pengembangan (Usulan)

| Fase | Fitur | Estimasi |
|---|---|---|
| 1 | Setup project, struktur folder, database lokal, CRUD produk dasar | 1-2 minggu |
| 2 | Fitur gambar produk (kamera/galeri/URL) | 3-5 hari |
| 3 | Barcode scanner + integrasi ke transaksi | 1 minggu |
| 4 | Import produk via Excel | 3-5 hari |
| 5 | Transaksi kasir + hitung total/kembalian | 1 minggu |
| 6 | Generate & preview struk PDF (cross-platform) | 1 minggu |
| 7 | Testing lintas platform, review dead code, polish UI | 1 minggu |

## 12. Risiko & Asumsi

- **Risiko:** `flutter_pdfview` tidak native support Web → perlu solusi tambahan agar preview struk tetap konsisten di 3 platform.
- **Risiko:** Kamera & file picker berperilaku beda di Web (browser permission) vs mobile — perlu handling error/permission yang jelas.
- **Asumsi:** Aplikasi berjalan single-device, tanpa kebutuhan sinkronisasi data multi-device di fase awal.
- **Asumsi:** Satu peran pengguna saja (kasir), tanpa login/otentikasi kompleks kecuali disepakati kemudian.

---

*Dokumen ini adalah draf awal PRD dan bisa disesuaikan lebih lanjut sesuai kebutuhan bisnis/teknis yang berkembang.*
