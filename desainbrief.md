# Design Brief
## Aplikasi Kasir — Gaya Minimalism (Hitam · Putih · Kuning)

**Terkait:** PRD Aplikasi Kasir Flutter
**Platform:** Android, iOS, Web
**Gaya:** Minimalism, fungsional, tidak generik ("no AI slop")

---

## 1. Konteks & Prinsip Dasar

Ini aplikasi kerja untuk kasir toko retail kecil-menengah — dipakai berulang kali setiap hari, seringkali cepat dan sambil melayani pembeli. Maka desain harus:

- **Cepat dibaca, cepat ditekan.** Kasir tidak sempat mengagumi UI; setiap elemen harus langsung jelas fungsinya.
- **Jujur pada data, bukan dekorasi.** Barcode, angka harga, dan stok adalah bintang utama — bukan ilustrasi atau gradient.
- **Kontras tegas.** Hitam-putih sebagai struktur, kuning hanya untuk hal yang butuh perhatian (aksi utama, status penting).

### Yang harus dihindari (ciri generik/"AI slop")
- Kartu seragam dengan radius sama semua + shadow abu-abu lembut yang sama di setiap elemen.
- Label ALL CAPS di atas setiap judul (eyebrow label) tanpa alasan.
- Ikon panah "→" ditempel di setiap tombol/link.
- Angka bertitik tengah "01 · 02 · 03" padahal kontennya bukan urutan langkah.
- Warna aksen "hangat generik" (cream/terracotta) — brief ini sudah menentukan sendiri: **hitam, putih, kuning**.
- Dekorasi yang tidak menyampaikan informasi (gradient hias, ilustrasi generik "flat design orang-orangan").

---

## 2. Design Tokens

### 2.1 Warna

| Token | Hex | Peran |
|---|---|---|
| `color.base.black` | `#111111` | Teks utama, ikon utama, elemen struktural (border tebal, header) |
| `color.base.white` | `#FFFFFF` | Latar utama (background) |
| `color.base.offwhite` | `#F5F5F3` | Latar sekunder (card/section pembeda tipis, bukan abu-abu bayangan) |
| `color.accent.yellow` | `#F5C400` | Aksi utama (tombol bayar/simpan), status "perlu perhatian" (stok menipis) |
| `color.accent.yellow-deep` | `#C79A00` | Teks/ikon di atas kuning agar kontras (WCAG AA), hover state |
| `color.state.danger` | `#111111` di atas garis merah tipis `#D14343` | Error/hapus — dipakai minimal, hanya garis/teks, bukan blok besar |
| `color.state.success` | `#111111` di atas garis hijau tipis `#3A7D44` | Konfirmasi transaksi berhasil |

> **Aturan pakai kuning:** kuning tidak boleh dipakai sebagai warna dekorasi/background luas. Kuning = sinyal "tekan ini" atau "perhatikan ini". Kalau semua tombol kuning, kuning kehilangan makna — batasi maksimal 1 aksi kuning yang menonjol per layar.

### 2.2 Tipografi

- **Satu keluarga font, grotesque/sans yang netral-tegas** — contoh: `Inter` atau `IBM Plex Sans` (bukan default Roboto polos, bukan serif dekoratif). Gunakan variasi *weight* (Regular/Medium/Bold) untuk hierarki, bukan font kedua.
- **Skala tipe** (berbasis 1.25 ratio, dibulatkan ke angka bulat agar enak di grid):

| Peran | Ukuran | Weight | Contoh Pemakaian |
|---|---|---|---|
| Display | 28px | Bold | Total harga di layar transaksi |
| Heading | 20px | Bold | Judul halaman (Daftar Produk, Transaksi) |
| Subheading | 16px | Medium | Nama produk di list |
| Body | 14px | Regular | Deskripsi, tabel, form label |
| Caption | 12px | Medium | Barcode, timestamp, metadata stok |

- Angka harga & stok pakai **tabular figures** (angka berjajar rapi) agar kolom angka tidak "meloncat" — penting untuk kasir yang scan cepat.
- **Hindari** ALL CAPS untuk label kecuali benar-benar status singkat (misal badge "HABIS").

### 2.3 Spacing & Grid

- Skala spacing 4px: `4, 8, 12, 16, 24, 32, 48`.
- Grid konten: margin luar 16px (mobile) / 24px (tablet) / 32px (web desktop).
- Line length teks deskriptif maksimal ~72 karakter di layar lebar (web) — jangan biarkan teks membentang penuh 1920px.

### 2.4 Border, Radius, Shadow

- **Radius kecil dan konsisten secara fungsional, bukan seragam total**: elemen interaktif (tombol, input, chip) `radius: 6px`. Kontainer struktural besar (card produk, panel) `radius: 2px` — nyaris tegas, bukan bulat penuh seperti kartu SaaS generik.
- **Tanpa drop-shadow lembut sebagai default.** Pemisah antar elemen pakai **border 1px solid hitam/abu gelap** (`#111111` atau `#DADADA` untuk yang lebih halus), bukan shadow blur. Ini konsisten dengan gaya minimalism-editorial: struktur terlihat, bukan "melayang".
- Elevasi (mis. modal/bottom sheet) baru pakai shadow tipis (`0 2px 8px rgba(0,0,0,0.12)`), dan hanya untuk lapisan yang benar-benar mengambang di atas konten lain.

### 2.5 Motion

- Motion hanya untuk merespons aksi pengguna: konfirmasi item masuk keranjang, transisi buka/tutup bottom sheet gambar produk, animasi scan barcode berhasil (highlight singkat pada border, bukan confetti).
- Tidak ada animasi fade-slide-up otomatis di semua section saat halaman dimuat — halaman kasir harus langsung tampil, tidak "menunggu animasi selesai".
- Durasi standar: 150–200ms, easing `ease-out`.

---

## 3. Layout per Layar Utama

### 3.1 Layar Transaksi (Kasir) — layar paling sering dipakai

```
┌──────────────────────────────────────────┐
│ [≡] Kasir                        [👤 Nama]│  <- header tipis, border-bottom 1px
├───────────────────────┬────────────────────┤
│  KERANJANG            │  RINGKASAN         │
│  ┌──────────────────┐ │  Subtotal   Rp xxx │
│  │ Nama produk   x2  │ │  Diskon     Rp   0 │
│  │ Rp 15.000  Rp30rb │ │  ────────────────  │
│  ├──────────────────┤ │  TOTAL     Rp xxx  │ <- Display size, bold
│  │ ...               │ │                    │
│  └──────────────────┘ │  [ Bayar ]  <- kuning, satu-satunya CTA kuning di layar
│  [ + Scan Barcode ]   │                    │
└───────────────────────┴────────────────────┘
```

- Kolom kiri (keranjang) lebih lebar di web/tablet; di mobile jadi satu kolom dengan ringkasan sticky di bawah.
- Tombol **Scan Barcode** ikon jelas (kamera/barcode), bukan tombol bulat mengambang generik tanpa label.
- Hanya **satu** tombol berwarna kuning solid di layar ini: "Bayar". Tombol lain (tambah manual, hapus item) pakai outline hitam/teks saja.

### 3.2 Layar Daftar Produk / Stok (CRUD)

```
┌──────────────────────────────────────────┐
│ Produk                      [+ Tambah]    │
│ [ Cari nama/barcode...      ]  [Filter ▾] │
├──────────────────────────────────────────┤
│ [img] Nama Produk        Stok: 12   >     │
│ ──────────────────────────────────────── │  <- border tipis antar baris, bukan card shadow
│ [img] Nama Produk        Stok: 3 ⚠        │  <- badge kuning kecil untuk stok menipis
│ ──────────────────────────────────────── │
└──────────────────────────────────────────┘
```

- List baris dengan **pembatas garis**, bukan kartu terpisah dengan shadow — lebih padat, lebih cepat dipindai mata untuk daftar panjang.
- Badge kuning **hanya** untuk status "stok menipis/habis" — bukan dekorasi tiap baris.
- Thumbnail gambar produk persegi kecil (40×40), radius 4px, dengan placeholder abu-abu bergaris (bukan ikon gambar pecah) jika tidak ada foto.

### 3.3 Form Tambah/Edit Produk (termasuk input gambar)

- Form satu kolom, label di atas input (bukan floating label — lebih jelas dibaca cepat).
- Tiga metode input gambar ditampilkan sebagai **segmented control** horizontal: `Kamera | Galeri | Link URL` — bukan menu dropdown tersembunyi, karena ini aksi yang sering dipakai.
- Preview gambar tampil di atas segmented control begitu dipilih, dengan tombol kecil "Ganti" (teks, bukan ikon tempat sampah merah besar).

### 3.4 Import Excel

- Layar sederhana: tombol "Pilih File Excel" → tabel preview data (garis pembatas, header bold) → tombol konfirmasi "Impor N Produk" (kuning) di bagian bawah, sticky.
- Baris bermasalah (barcode duplikat/format salah) ditandai dengan teks merah tipis di kolom terkait — bukan seluruh baris diblok merah.

### 3.5 Preview Struk (PDF)

- Struk ditampilkan dalam bingkai putih menyerupai kertas struk asli (lebar terbatas ~320px secara visual meski di web), font monospasi hanya di sini karena struk kertas asli memang biasa monospasi — ini satu-satunya tempat monospace dipakai, tidak untuk label data lain di aplikasi.
- Dua aksi di bawah preview: "Bagikan" dan "Simpan" — outline hitam, bukan kuning (karena aksi utama "Bayar" sudah selesai di layar sebelumnya).

---

## 4. Komponen Utama

| Komponen | Varian | Catatan Anti-Slop |
|---|---|---|
| Button Primer | Kuning solid, teks hitam bold | Maksimal 1 per layar; tanpa ikon panah default |
| Button Sekunder | Outline hitam 1px, teks hitam | Untuk aksi setara (batal, tambah manual) |
| Button Teks | Teks hitam underline saat hover | Untuk aksi ringan (ganti gambar, lihat detail) |
| Input Field | Border bawah 1px solid, label di atas | Fokus: border bawah jadi 2px kuning-deep, bukan glow/shadow |
| Badge Status | Kuning (perhatian), garis merah tipis (habis), garis hijau tipis (aktif) | Bukan pill warna-warni penuh |
| List Row | Pembatas garis 1px, bukan card | Dipakai di daftar produk & histori transaksi |
| Segmented Control | Untuk pilihan metode input gambar & filter | Highlight aktif: latar hitam, teks putih |
| Empty State | Ilustrasi garis sederhana (bukan flat-illustration generik) + teks arahan aksi | Contoh teks: "Belum ada produk. Tambah produk pertama atau impor dari Excel." |

---

## 5. Nada Penulisan (Microcopy)

- Kalimat aktif, sesuai aksi: tombol "Simpan Produk" → notifikasi "Produk disimpan" (bukan "Data telah berhasil diproses").
- Error langsung ke inti masalah + cara memperbaiki: "Barcode ini sudah dipakai produk lain. Gunakan barcode berbeda atau edit produk yang ada."
- Tidak ada nada "menjual fitur" ke pengguna internal (kasir bukan calon pelanggan) — bahasa instruksional, singkat, apa adanya.

---

## 6. Aksesibilitas & Responsif (Lantai Kualitas Wajib)

- Kontras teks hitam di atas putih/offwhite otomatis lolos AA. Teks di atas kuning **wajib** pakai `color.accent.yellow-deep` atau hitam, dicek kontrasnya (bukan putih di atas kuning).
- Target sentuh minimum 44×44px untuk semua tombol/ikon di mobile (penting karena dipakai cepat berulang oleh kasir).
- Fokus keyboard terlihat jelas (border 2px kuning-deep) — versi web dipakai juga dengan keyboard/barcode scanner USB yang mensimulasikan keyboard.
- Layout responsif: 1 kolom di mobile, 2 kolom (keranjang + ringkasan) mulai breakpoint tablet ke atas.

---

## 7. Ringkasan Prinsip (Checklist Sebelum Build Komponen Baru)

1. Apakah kuning dipakai untuk **aksi/perhatian**, bukan dekorasi? ✅/❌
2. Apakah elemen pakai **border**, bukan shadow lembut generik, sebagai pemisah? ✅/❌
3. Apakah copy ditulis spesifik untuk konteks kasir, bukan teks generik "Lorem-ipsum-style"? ✅/❌
4. Apakah komponen ini benar-benar dibutuhkan alurnya, atau sekadar dekorasi (dead UI)? ✅/❌
5. Apakah radius, spacing, dan warna diambil dari token di atas — tidak ada nilai hardcode baru? ✅/❌

---

*Design brief ini menjadi acuan visual sebelum implementasi UI Flutter (widget, ThemeData, dan komponen kustom) untuk aplikasi kasir.*
