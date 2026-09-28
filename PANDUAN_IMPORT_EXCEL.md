# Panduan Import Excel — Kasir Pintar

Ada **dua** impor Excel yang berbeda di aplikasi ini. Jangan tertukar.

| | Impor Produk | Tambah Stok |
| --- | --- | --- |
| Halaman | Produk → ikon impor → `/excel-import` | Tambah Stok → impor dari Excel |
| Berkas kerja | `excel_import_service.dart` | `excel_stock_service.dart` |
| Efek | membuat produk baru, atau memperbarui yang sudah ada | hanya mengubah angka stok |
| Kolom jumlah | `harga`, `stok` (keduanya wajib) | `stok` / `jumlah` / `tambah` / `qty` (salah satu) |
| Template | `template_import_produk.xlsx` | `template_tambah_stok.xlsx` |

Dokumen ini membahas **Impor Produk** karena di situlah persyaratan berkasnya
paling ketat. Tambah Stok dijelaskan di bagian 7.

---

## 1. Persyaratan Format

| Aturan | Nilai |
| --- | --- |
| Format berkas | **`.xlsx` saja** |
| Ekstensi lain | `.xls` (Excel 97-2003) dan `.csv` **ditolak** oleh pemilih berkas |
| Jumlah sheet | Bebas — hanya **sheet pertama** yang dibaca |
| Baris 1 | harus berisi judul kolom |
| Baris 2 dan seterusnya | data produk |
| Jumlah file | satu berkas per impor |

Pemilih berkas sengaja dikunci ke `allowedExtensions: ['xlsx']`, jadi berkas
`.csv` yang kamu ubah ekstensinya tetap gagal dibaca.

---

## 2. Kolom Wajib

Lima kolom berikut **wajib ada sebagai judul kolom**:

| Judul kolom | Isi | Wajib berisi nilai? |
| --- | --- | --- |
| `nama` | Nama produk | **Ya** |
| `barcode` | Kode barcode, harus unik | **Ya** |
| `harga` | Harga jual, bilangan bulat tanpa desimal | **Ya** |
| `stok` | Jumlah stok, boleh nol | **Ya** |
| `kategori` | Nama kategori | Tidak, boleh dikosongkan |

### Aturan judul kolom

- **Tidak case-sensitive.** `Nama`, `NAMA`, dan `nama` semua dikenali.
- **Spasi di tepi dibuang.** ` nama ` dibaca sebagai `nama`.
- **Urutan kolom bebas.** Tidak harus `nama, barcode, harga, stok, kategori`.
- **Kolom tambahan diabaikan.** Tambah kolom `keterangan` atau `satuan` tidak
  menjadi masalah, selama lima kolom wajib masih ada.

Contoh berkas yang valid:

| nama | barcode | harga | stok | kategori |
| --- | --- | --- | --- | --- |
| Indomie Goreng | 8991002101011 | 3500 | 48 | Makanan |
| Aqua 600ml | 8992775001369 | 4000 | 24 | Minuman |
| Rokok 12 | 8999999033771 | 23000 | 12 | Rokok |

---

## 3. Format Nilai

### `nama`

- Wajib diisi, tidak boleh hanya spasi.
- Batas panjang yang konsisten dengan form manual: 100 karakter.
  Impor Excel **belum** menegakkan batas ini (lihat bagian 6).

### `barcode`

- Wajib diisi, tidak boleh hanya spasi.
- Bentuknya bebas teks, bukan harus angka: `8991002101011`, `ABC-001`, dan
  `200/PL` semuanya sah karena kolomnya bertipe teks.
- Panjang sampai 50 karakter.
- **Harus unik.** Barcode yang sudah ada di database dicocokkan lewat
  `getProductByBarcode`; lihat bagian 5.

### `harga`

- **Harus bilangan bulat.** `15000` benar, `15000.50` ditolak.
- Pemisah ribuan dibuang otomatis, jadi `15000`, `15.000`, dan `15,000`
  semuanya dibaca sebagai 15000.
- Harus lebih besar dari 0. `0` dan negatif ditolak.
- Teks dengan satuan ikut serta tidak akan terbaca: `Rp15.000` gagal, dan
  baris itu dilaporkan sebagai error.

### `stok`

- Boleh nol, tidak boleh negatif.
- Sel numerik biasa apa pun aman: `0`, `24`, `10000`.
- **Hindari titik atau koma sebagai pemisah ribuan di kolom ini.** Tulisan
  `"10.000"` tidak akan dibaca sebagai sepuluh ribu; kolom ini tidak
  membuang pemisah ribuan seperti kolom `harga`, dan hasilnya menjadi `0`
  tanpa pesan error. Pakai angka polos `10000`.

### `kategori`

- Boleh dikosongkan. Baris dengan kategori kosong disimpan dengan kategori
  `null`, sama seperti produk yang ditambahkan lewat form tanpa kategori.

---

## 4. Alur di Layar

1. **Produk → ikon impor** (tooltip: "Tambah stok dari Excel").
2. Ketuk kotak **Pilih File Excel**.
3. Aplikasi langsung mem-parse berkas dan menampilkan preview:
   jumlah baris valid, jumlah baris error, dan tabel isinya.
4. Baris error ditampilkan terpisah di kotak merah, lengkap dengan nomor
   baris dan alasannya.
5. Pilih salah satu dari dua tombol:

| Tombol | Perilaku pada barcode yang sudah ada |
| --- | --- |
| **Lewati Duplikat** | Produk lama dibiarkan apa adanya. Hanya barcode baru yang dibuat. |
| **Impor N Produk** | Produk lama **diperbarui**: nama, harga, stok, dan kategori ditimpa dengan isi berkas. Perbarui stok tercatat di riwayat dengan sumber `excel`. |

Baris error **tidak pernah** diimpor, dari mode mana pun. Baris yang valid tetap
diimpor walau ada baris lain yang gagal divalidasi.

---

## 5.-precision Aturan Duplikat Barcode

| Situasi | Yang terjadi |
| --- | --- |
| Barcode sudah ada di database, mode Lewati Duplikat | dilewati |
| Barcode sudah ada di database, mode Impor | diperbarui |
| Barcode **sama muncul dua kali di dalam satu berkas** | perilaku tidak konsisten: baris pertama masuk, baris kedua dianggap "sudah ada" lalu dilewati atau ditimpa. Sebaiknya hindari. |

Deteksi duplikat di dalam berkas belum ada di `ExcelImportService` — ini
perbedaan nyata dibanding `ExcelStockService` yang sudah menjaganya.

---

## 6. Batas yang Belum Ditegakkan

`ExcelImportService` memvalidasi empat hal saja: nama tidak kosong, barcode
tidak kosong, harga lebih besar dari nol, stok tidak negatif. Ia **tidak**
menegakkan batas yang sama dengan form manual:

| Nilai | Batas di form manual | Status di impor Excel |
| --- | --- | --- |
| Panjang nama | 100 karakter | tidak ditegakkan |
| Panjang kategori | 50 karakter | tidak ditegakkan |
| Panjang barcode | 50 karakter | tidak ditegakkan |
| Harga maksimum | 999999999 | tidak ditegakkan |
| Stok maksimum | 999999 | tidak ditegakkan |

Praktisnya: produk yang sama bisa berhasil diimpor lewat Excel dan ditolak
kalau diketik manual. Selama batas ini belum diperbaiki, isi nilai yang wajar
dan Perhatikan panjang kolom.

---

## 7. Tambah Stok dari Excel (sebagai pembanding)

Layanan `ExcelStockService` jauh lebih longgar dan sengaja begitu, supaya
berkas hasil ekspor bisa disunting lalu diunggah kembali.

**Syarat:**

- `.xlsx`, sheet pertama, baris 1 = judul kolom.
- Wajib ada **salah satu** penanda produk: kolom `barcode` atau `nama`.
  (Paling aman pakai keduanya.)
- Wajib ada **salah satu** kolom jumlah dari: `stok`, `jumlah`, `tambah`, `qty`.
  Kalau lebih dari satu ada, yang menang mengikuti urutan di atas.

**Yang boleh absen:** `harga` dan `kategori`. Layanan ini tidak butuh keduanya.

**Kelebihan dibanding impor produk:**

- Angka **`10.000` di kolom jumlah terbaca benar** — pemisah ribuan dibuang
  dan desimal dibulatkan, bukan dipotong.
- **Produk yang tidak ditemukan dilaporkan** per baris, bukan diam-diam
  dilewati.
- **Duplikat dalam berkas dideteksi** dan dilaporkan sebagai error.
- Baris kosong di tengah berkas dilewati diam-diam, bukan dianggap error.

Contoh:

| nama | barcode | stok |
| --- | --- | --- |
| Indomie Goreng | 8991002101011 | 24 |
| Aqua 600ml | 8992775001369 | 1.000 |

---

## 8. Template

Kedua layanan bisa membuat template kosongnya sendiri dari dalam aplikasi:

- **Impor Produk** → tombol **Unduh Template** → `template_import_produk.xlsx`
- **Tambah Stok** → tombol **Unduh Daftar Produk (.xlsx)**

Di Android dan iOS template ditulis ke folder Documents aplikasi. Di web
template diunduh lewat browser. Cara paling aman: unduh template, isi, lalu
unggah ulang berkas itu.

---

## 9. Kalau Impor Gagal

| Pesan | Artinya dan solusinya |
| --- | --- |
| `Kolom wajib "X" tidak ditemukan` | Judul kolom `X` hilang atau salah ejaan. Bandingkan dengan daftar di bagian 2 — perhatikan huruf besar tidak berpengaruh, tapi spasi di tengah kata tidak dihapus. |
| `File Excel kosong atau tidak valid` | Berkas rusak, atau sebenarnya `.xls`/`.csv` yang ekstensinya diganti. Simpan ulang dari Excel sebagai `.xlsx`. |
| `File Excel tidak memiliki data (hanya header)` | Ada judul kolom tapi tidak ada satu pun baris produk. |
| `Nama kosong` / `Barcode kosong` | Sel kosong atau hanya berisi spasi. |
| `Harga harus > 0` | Harga 0, negatif, desimal (`15000.50`), atau ada teks di dalamnya (`Rp15.000`). |
| `Stok tidak boleh negatif` | Angka stok bernilai minus. |
| `Gagal membaca file: ...` | Berkas korup atau didukung. Simpan ulang dari Excel. |
| Preview menunjukkan banyak baris error | Buka berkas aslinya, perbaiki berdasarkan nomor baris yang disebut, unggah ulang. Baris yang valid tetap bisa diimpor tanpa menunggu perbaikan. |
