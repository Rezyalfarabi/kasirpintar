# Uji Alur Utama — Kasir Pintar

Dokumen ini mencatat hasil pengujian alur utama dengan dua pendekatan: test
otomatis dan checklist manual di browser.

## Perintah

```bash
flutter analyze                          # harus "No issues found!"
flutter test                             # 93 test, semua lulus
flutter run -d chrome --web-port=8080
```

File `web/sqlite3.wasm` dan `web/drift_worker.js` wajib ada supaya drift jalan
di web. Keduanya sudah ada di repo dan disalin otomatis ke `build/web/`.

### Kalau tampilan di browser terlihat seperti versi lama

`web/index.html` sudah membersihkan service worker dan cache lama setiap kali
halaman dimuat, jadi build terbaru langsung terpakai. Bila jendela Chrome masih
memegang versi lama: **Ctrl+Shift+R** (hard reload), lalu tutup tab lain yang
masih membuka aplikasi ini. Untuk memastikan berkas yang disajikan sudah baru:

```bash
cd build/web && grep -c "Tambah Stok" main.dart.js   # harus > 0
```

## Status ringkas

| Alur | Logika (otomatis) | UI di Chrome |
| --- | --- | --- |
| Tambah / ubah / hapus produk | Lulus | Perlu diklik — kecuali lampiran gambar |
| Tambah stok dari Excel | Lulus | Perlu diklik (pemilih berkas OS) |
| Transaksi kasir + keranjang | Lulus | Perlu diklik |
| Riwayat perubahan stok | Lulus | Perlu diklik |
| Cetak struk | Lulus (byte PDF valid) | Preview & cetak jalan, simpan/bagikan belum |
| Impor produk baru dari Excel | Lulus (parsing) | Perlu diklik |
| Ekspor produk ke Excel | Lulus | Unduhan browser perlu diklik |

---

## 1. Test otomatis (93 test, semua lulus)

Test alur memakai database drift in-memory lewat
`AppDatabase.withExecutor(NativeDatabase.memory())` plus repository asli (tanpa
mock), jadi query DAO ikut teruji. Test halaman memakai repository palsu supaya
hanya tampilan dan interaksinya yang diuji.

| Berkas | Test | Cakupan |
| --- | --- | --- |
| `flows/product_flow_test.dart` | 4 | CRUD produk, stok absolut & relatif, filter, soft delete |
| `flows/checkout_flow_test.dart` | 5 | Aritmetika keranjang, pembayaran, struk, penolakan |
| `flows/receipt_pdf_test.dart` | 1 | Byte PDF struk valid |
| `flows/excel_import_test.dart` | 14 | Parsing produk, validasi header, desimal, pemisah ribuan, duplikat, batas sama form, template |
| `flows/excel_export_test.dart` | 6 | Susunan kolom ekspor produk |
| `flows/stock_in_test.dart` | 10 | Baca berkas stok, cocokkan produk, mode tambah vs set, laporan baris gagal |
| `flows/stock_history_test.dart` | 9 | Jejak audit stok: produk baru, Excel, manual, penjualan, hapus, saringan, urutan |
| `flows/page_smoke_test.dart` | 8 | Layar kasir, produk, tambah stok, dan riwayat stok dirender tanpa meluber, termasuk di ponsel 360px |
| `flows/navigation_test.dart` | 5 | Lima tab navigasi dan tab aktif |
| `flows/product_image_test.dart` | 2 | Alur gambar produk |
| `unit/design_contract_test.dart` | 12 | Aturan `desainbrief.md` (font, warna, border, kontras) |
| `unit/currency_format_test.dart` | 2 | Rupiah bulat tanpa pembagian 100 |
| `unit/excel_number_test.dart` | 10 | Pembacaan angka Excel: pemisah ribuan lengkap, desimal pembulatan, teks campuran ditolak |
| `unit/product_image_resolver_test.dart` | 3 | Prioritas sumber gambar (URL, byte, berkas) |

**Yang TIDAK dicakup test otomatis** (perlu diklik manual): kamera/galeri,
pemilihan berkas lewat dialog OS, dialog cetak/bagikan, izin perangkat, dan
seluruh perpindahan layar nyata di browser.

---

## 2. Alur tambah stok dari Excel

Fitur ini memakai berkas yang **sudah berisi daftar produk** — biasanya hasil
ekspor aplikasi sendiri — lalu menambah stoknya. Alurnya:

1. **Produk → ikon unggah** (atau tab **Stok**) → halaman *Tambah Stok*.
2. **Unduh Daftar Produk (.xlsx)** — berkas berisi seluruh produk dengan kolom
   `nama, barcode, harga, stok, kategori`.
3. Sunting kolom `stok` sesuai barang masuk. Kolom lain boleh dibiarkan.
4. Unggah berkas itu kembali di halaman *Tambah Stok*.
5. Pilih cara membacanya:
   - **Tambah ke stok** (bawaan): angka di kolom `stok` ditambahkan ke stok
     sekarang — untuk barang masuk.
   - **Set stok baru**: angka di kolom `stok` menjadi stok akhir — untuk stok
     opname.
6. Pratinjau menampilkan stok sistem, perubahan, dan stok akhir per baris.
   Baris yang produknya tidak ada ditandai `BARU` dan dilewati.
7. **Terapkan** → ringkasan menampilkan jumlah produk yang diperbarui dan total
   stok bertambah.

Nama kolom yang dikenali: `barcode` atau `nama` untuk mencocokkan produk, dan
`stok`, `jumlah`, `tambah`, atau `qty` untuk jumlahnya. Barcode dipakai lebih
dulu; kalau kosong, nama dipakai sebagai cadangan.

---

## 3. Riwayat perubahan stok (jejak audit)

Setiap perubahan stok dicatat otomatis ke tabel `stock_movements_table`:
waktu, nama produk saat itu, jumlah sebelum → sesudah, selisihnya, sumber
perubahan, dan catatan tambahan.

| Sumber | Kapan muncul | Catatan yang disimpan |
| --- | --- | --- |
| Produk baru | Produk dibuat dengan stok bukan nol | — |
| Dari Excel | Halaman **Tambah Stok**, atau impor yang menimpa stok | Nama berkas `.xlsx` |
| Diubah manual | Form produk atau perubahan stok langsung | — |
| Penjualan | Setiap transaksi di kasir | `Transaksi #<id>` |
| Produk dihapus | Produk dihapus dari daftar | — |

Catatan penting: **checkout sekarang benar-benar mengurangi stok produk** dan
pencatatannya ikut dalam satu transaksi database. Sebelumnya transaksi tersimpan
tapi stok produk tidak pernah berkurang.

Halaman **Riwayat Stok** bisa dibuka dari halaman *Tambah Stok* (tombol
"Lihat riwayat perubahan stok") atau dari daftar produk lewat menu
**⋯ → Riwayat stok** yang otomatis menyaring per produk. Di sana ada saringan
per sumber perubahan.

---

## 4. Checklist manual (Chrome)

Jalankan `flutter run -d chrome --web-port=8080`, lalu:

### A. Tambah produk
1. **Produk → Tambah Produk**.
2. Isi Nama, Barcode, Harga `15000`, Stok `10`, Kategori `Minuman`. Simpan.
3. Produk muncul di daftar, harga tertulis **Rp 15.000** (bukan Rp 150).
4. Ulangi dengan barcode sama → ditolak dengan pesan kesalahan.
5. Menu **⋯ pada baris produk → Hapus produk** → konfirmasi muncul, produk
   hilang dari daftar.
6. Coba segmen **Kamera** dan **Galeri** → catat hasilnya (butuh izin + HTTPS).
7. Coba segmen **URL**, isi URL gambar publik → pratinjau muncul.

### B. Transaksi kasir
1. Buka **Kasir**. Di layar lebar katalog dan keranjang tampil berdampingan;
   di layar sempit berpindah lewat tombol **Katalog / Keranjang**.
2. Ketuk sebuah produk di katalog → muncul notifikasi singkat dan penanda
   jumlah di kartu produk.
3. Tekan **Scan** untuk menambah lewat barcode (butuh izin kamera).
4. Ubah kuantitas, hapus satu item → subtotal di **Ringkasan** ikut berubah.
5. Isi uang bayar kurang dari total → tombol **Bayar** tidak jalan.
6. Isi uang bayar cukup → tekan **Bayar** → berpindah ke halaman struk dan
   riwayat bertambah satu baris.
7. Buka **Produk**: stok produk yang tadi terjual harus berkurang sebanyak
   jumlah yang dibeli.

### C. Cetak struk
1. Pratinjau PDF 58 mm muncul di halaman struk.
2. Ikon **cetak** → dialog cetak browser terbuka.
3. Ikon **bagikan** dan **simpan PDF** → catat hasilnya.
4. **Riwayat → detail transaksi** → total, bayar, dan kembalian konsisten.

### D. Tambah stok dari Excel
1. **Produk → Unduh Daftar Produk (.xlsx)**: berkas terunduh dengan kolom
   `nama, barcode, harga, stok, kategori` dan angka stok yang benar.
2. Isi kolom `stok` pada beberapa baris dengan jumlah barang masuk, mis. `12`.
3. **Tab Stok → pilih berkas** → pratinjau menampilkan jumlah cocok, tidak
   ditemukan, dan baris error.
4. Ganti mode **Tambah ke stok** ↔ **Set stok baru** → kolom *Stok akhir*
   harus ikut berubah tanpa membaca ulang berkas.
5. Tekan **Terapkan ke N Produk** → ringkasan muncul; buka **Produk** dan
   pastikan angka stoknya bertambah sesuai.
6. Coba juga berkas yang salah: header tanpa kolom jumlah (ditolak dengan
   pesan jelas), barcode yang tidak terdaftar (dilewati), dan angka bukan
   bilangan (masuk daftar baris error).

### E. Tambah stok dari aplikasi versi lama
Fitur ini menggantikan impor yang menimpa stok. Jika pengguna masih memakai
berkas dari alur lama, kolom `stok` dibaca sebagai jumlah tambahan — beri tahu
mereka untuk memakai **Set stok baru** bila maksudnya menimpa.

### F. Riwayat stok
1. **Tab Stok → Lihat riwayat perubahan stok**.
2. Setelah menjual barang, pastikan muncul baris **Penjualan** dengan selisih
   negatif dan catatan `Transaksi #<id>`.
3. Setelah menambah stok dari Excel, pastikan muncul baris **Dari Excel**
   dengan nama berkasnya dan angka *stok lama → stok baru* yang benar.
4. Ketuk saringan **Dari Excel / Penjualan / Diubah manual** → hanya baris dari
   sumber itu yang tampil.
5. Dari daftar produk: **⋯ → Riwayat stok** → hanya perubahan produk tersebut
   yang muncul.

### G. Hal yang hanya bisa dicek di perangkat asli
- Izin kamera (`mobile_scanner`, `image_picker`) di Android/iOS.
- Izin penyimpanan dan dialog cetak/sistem asli.
