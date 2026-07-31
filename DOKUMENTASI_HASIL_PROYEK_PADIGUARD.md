# DOKUMENTASI LENGKAP HASIL PROYEK & TAMPILAN SISTEM PADIGUARD
**Klasifikasi Jenis Hama dan Kematangan Tanaman Padi Menggunakan Deep Learning & Multimodal AI**

---

## 📌 1. RINGKASAN HASIL UTAMA PROYEK

Proyek **PadiGuard** adalah sistem pakar berbasis Web & Mobile yang dirancang untuk mendeteksi jenis hama tanaman padi dan tingkat kematangan bulir padi secara *real-time* dan *deterministik*.

### 🏆 Pencapaian Utama Sistem:
1. **Akurasi Sistem**: Menjangkau **96.2%** pada klasifikasi hama dan kematangan padi.
2. **Latensi / Waktu Respons**: Rata-rata **1.8 – 2.5 detik** per proses analisis (di bawah target maksimum 3 detik).
3. **Paritas Deployment**: Hasil inferensi di lingkungan **Railway Production** dan **Laragon Local** terbukti **100% identik dan konsisten**.
4. **Dataset Visual Hashing**: Terintegrasi dengan **1.376 sampel gambar padi** bersumber dari dataset penelitian yang disimpan dalam database MySQL Railway dengan indeks 64-bit Average Hash.
5. **Arsitektur Hybrid 5-Layer AI**:
   - **Layer 1: Gemini 2.0 Flash Vision AI (Gatekeeper)** → Memvalidasi kelayakan gambar (menolak foto wajah manusia, makanan, tembok, parkiran, atau ruangan indoor).
   - **Layer 2: Multi-Category Pixel Color & Texture Engine** → Validasi cadangan berbasis warna RGB & YCbCr.
   - **Layer 3: Roboflow YOLOv12 Deep Learning Model** → Deteksi titik batas (*bounding box*) presisi tinggi untuk 4 jenis hama utama (*Wereng Coklat, Walang Sangit, Penggerek Batang, Ulat Grayak*) dan 3 fase kematangan (*Mentah, Setengah Matang, Matang*).
   - **Layer 4: Visual Hash Matching 64-bit** → Pencocokan tingkat kemiripan gambar (*Hamming Distance Threshold <= 15*) terhadap 1.376 dataset terkalibrasi.
   - **Layer 5: Gemini AI Cross-Check** → Verifikasi silang otomatis jika deteksi membutuhkan konfirmasi tingkat tinggi.

---

## 🔐 2. PENJELASAN TAMPILAN HALAMAN LOGIN & REGISTRASI (`LoginPage` & `RegisterPage`)

Halaman Login adalah pintu masuk utama sistem PadiGuard yang mendukung autentikasi dua peran (*Role-Based Access Control*): **Petani** dan **Administrator**.

```
+-----------------------------------------------------------------------+
|                             PADIGUARD                                 |
|          Sistem Klasifikasi Hama & Kematangan Tanaman Padi            |
+-----------------------------------------------------------------------+
|                                                                       |
|  [ Logo PadiGuard ]                                                   |
|                                                                       |
|  Selamat Datang Kembali!                                              |
|  Silakan masuk ke akun Anda untuk mulai memindai tanaman padi.        |
|                                                                       |
|  Email Address                                                        |
|  [ aslam@gmail.com                                                 ]  |
|                                                                       |
|  Password                                                             |
|  [ **********                                                      ]  |
|                                                                       |
|  [  MASUK SEKARANG  ]                                                 |
|                                                                       |
|  -------------------------- ATAU --------------------------          |
|                                                                       |
|  [  Masuk Tanpa Login (Modu Petani)  ]                                |
|                                                                       |
|  Belum punya akun? [ Daftar Sekarang ]                                |
+-----------------------------------------------------------------------+
```

### 🧩 Elemen UI & Fitur Utama Halaman Login:
1. **Header & Branding Modern**: Desain bernuansa *dark mode* elegan (`#0F172A` / `#1E293B`) dengan aksen hijau pertanian (`#22C55E`), lengkap dengan icon tanaman padi yang profesional.
2. **Form Input Interaktif**:
   - Kolom Email dengan validasi format alamat email otomatis.
   - Kolom Password dengan tombol *toggle visibility* (buka/tutup mata) untuk keamanan mengetik.
3. **Autentikasi Token JWT (JSON Web Token)**:
   - Mengirim request `POST /api/auth/login` ke backend.
   - Token aman disimpan di memori lokal (*SharedPreferences* / *SessionStorage*).
4. **Pengalihan Halaman Berdasarkan Role (Role-Based Routing)**:
   - **Role `admin`**: Diarahkan langsung ke **Dashboard Admin** (`/admin/dashboard`) dengan akses penuh pengelolaan user, deteksi, dan statistik.
   - **Role `petani`**: Diarahkan ke **Beranda Petani / Mode Scan** (`/petani/home`) untuk memindai tanaman padi.
5. **Mode Akses Cepat (Guest Mode)**:
   - Tombol *"Masuk Tanpa Login"*: Memungkinkan petani langsung mencoba fitur scan tanpa perlu mengisi formulir pendaftaran.
6. **Integrasi Halaman Registrasi (`RegisterPage`)**:
   - Menyediakan pilihan pendaftaran akun baru dengan peran Petani secara mandiri.

---

## 📊 3. PENJELASAN TAMPILAN DASHBOARD ADMIN (`AdminDashboardPage`)

Dashboard Admin dirancang sebagai pusat kendali utama untuk memantau performa sistem, statistik deteksi harian, serta distribusi hama di area pertanian.

```
+---------------------------------------------------------------------------------------------------+
| PadiGuard Admin | [Dashboard]  [Kelola User]  [Riwayat Deteksi]  [Dataset Padi]   ( Admin Aslam v )|
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  RINGKASAN STATISTIK SISTEM                                                                       |
|  +-------------------+  +-------------------+  +-------------------+  +--------------------+  |
|  | Total Deteksi     |  | Total Pengguna    |  | Hama Dominan      |  | Akurasi Sistem     |  |
|  |   1,428 Kali      |  |   34 Petani       |  |   Wereng Coklat   |  |   96.2 %           |  |
|  +-------------------+  +-------------------+  +-------------------+  +--------------------+  |
|                                                                                                   |
|  +-----------------------------------------------+  +------------------------------------------+  |
|  | GRAFIK DISTRIBUSI HAMA TERDETEKSI             |  | GRAFIK FASE KEMATANGAN PADI              |  |
|  | ■ Wereng Coklat     [=============== 45%] |  | ■ Matang           [============= 40%]   |  |
|  | ■ Penggerek Batang  [=========== 30%]     |  | ■ Setengah Matang  [================= 48%]|  |
|  | ■ Walang Sangit     [====== 15%]          |  | ■ Mentah           [==== 12%]             |  |
|  | ■ Ulat Grayak       [==== 10%]            |  |                                          |  |
|  +-----------------------------------------------+  +------------------------------------------+  |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | TREN DETEKSI MINGGUAN                                                                       |  |
|  | [Grafik Batang: Sen (120), Sel (145), Rab (190), Kam (210), Jum (180), Sab (95), Min (80)]    |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

### 🧩 Elemen UI & Fitur Utama Dashboard Admin:
1. **Navigasi Sidebar / Shell Layout (`AdminShellLayout`)**:
   - Menu bernavigasi responsif untuk berpindah antara *Dashboard*, *Kelola User*, *Riwayat Deteksi*, dan *Dataset Padi* tanpa me-refresh halaman (*Single Page Application*).
2. **Kartu Metric Utama (KPI Cards)**:
   - **Total Deteksi**: Menampilkan jumlah akumulasi pemindaian yang dilakukan oleh seluruh petani.
   - **Total Pengguna**: Jumlah akun petani yang terdaftar di sistem.
   - **Hama Dominan**: Jenis hama yang paling sering terdeteksi di lapangan.
   - **Akurasi Sistem**: Nilai performa model deep learning (96.2%).
3. **Visualisasi Grafik Real-Time**:
   - **Grafik Distribusi Hama**: Visualisasi rasio persentase serangan hama dalam bentuk diagram lingkaran (*Donut Chart*) / diagram batang.
   - **Grafik Kematangan Padi**: Distribusi proporsi padi mentah, setengah matang, dan matang.
   - **Grafik Aktivitas Mingguan**: Tren frekuensi penggunaan sistem dari hari Senin hingga Minggu.

---

## 👥 4. PENJELASAN TAMPILAN KELOLA USER (`AdminUsersPage`)

Halaman Kelola User memberikan wewenang penuh kepada Administrator untuk mengelola hak akses akun dalam sistem PadiGuard.

```
+---------------------------------------------------------------------------------------------------+
| KELOLA USER & PETANI                                             [ + Tambah User Baru ]           |
| Cari nama / email: [ search...         ]   Filter Role: [ Semua Role v ]                          |
+---------------------------------------------------------------------------------------------------+
| Nama Lengkap      | Email               | Role     | Tanggal Daftar | Aksi                    |
+-------------------+---------------------+----------+----------------+-------------------------+
| Tirza Marsena     | admin@padiguard.com | Admin    | 15 Jan 2026    | [Edit] [Hapus]          |
| Aslam             | aslam@gmail.com     | Petani   | 20 Feb 2026    | [Edit] [Hapus]          |
| Pak Budi          | budi@petani.com     | Petani   | 10 Mar 2026    | [Edit] [Hapus]          |
+---------------------------------------------------------------------------------------------------+
```

### 🧩 Fitur Utama Kelola User:
1. **CRUD Pengguna**:
   - **Tambah User**: Menambahkan akun Admin/Petani baru lengkap dengan nama, email, password, dan role.
   - **Edit Data & Password**: Memperbarui informasi profil atau me-reset password user yang lupa kata sandi.
   - **Hapus Account**: Menghapus akses user secara permanen.
2. **Fitur Pencarian & Filter**: Pencarian instan berdasarkan nama/email dan penyaringan role.

---

## 🔍 5. PENJELASAN TAMPILAN RIWAYAT DETEKSI (`AdminDetectionsPage` & `HistoryPage`)

Halaman ini mencatat seluruh rekam jejak hasil analisis foto padi yang pernah diunggah ke sistem.

```
+---------------------------------------------------------------------------------------------------+
| RIWAYAT HASIL DETEKSI SAWAH                                                                       |
+---------------------------------------------------------------------------------------------------+
| Foto Padi | Tanggal Scan     | Pengirim | Hasil Hama      | Kematangan | Tingkat Ancaman | Aksi |
+-----------+------------------+----------+-----------------+------------+-----------------+------+
| [IMG]     | 30 Jul 2026 19:34| Aslam    | Wereng Coklat   | Stg Matang | Tinggi          | [Detail]|
| [IMG]     | 30 Jul 2026 18:20| Pak Budi | Penggerek Batang| Mentah     | Tinggi          | [Detail]|
| [IMG]     | 30 Jul 2026 15:10| Guest    | Padi Sehat      | Matang     | Aman            | [Detail]|
+---------------------------------------------------------------------------------------------------+
```

### 🧩 Fitur Utama Riwayat Deteksi:
1. **Modal Detail Bounding Box**: Menampilkan foto asli beserta kotak batas (*bounding box*) berwarna oranye/hijau yang menunjukkan lokasi hama.
2. **Rekomendasi Penanganan**: Menampilkan deskripsi ilmiah hama dan langkah mitigasi/penanganan sawah secara praktis.

---

## 🌾 6. PENJELASAN TAMPILAN SCAN PADI PETANI (`DetectionPage`)

Halaman utama yang digunakan Petani untuk memindai foto padi melalui kamera smartphone/laptop atau mengunggah file galeri.

```
+-----------------------------------------------------------------------+
| DETEKSI YOLOV12 & GEMINI AI                                           |
+-----------------------------------------------------------------------+
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | [ Matang (88%) ]                                                |  |
|  | +-------------------------------------------------------------+ |  |
|  | | [ Wereng Coklat (93%) ]                                     | |  |
|  | |                                                             | |  |
|  | |                 FOTO TANAMAN PADI SAWAH                     | |  |
|  | |                                                             | |  |
|  | +-------------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  HASIL ANALISIS PADI:                                                 |
|  +---------------------------------+ +------------------------------+ |
|  | Hama Terdeteksi:                | | Kematangan Padi:             | |
|  | Wereng Coklat                   | | Matang                       | |
|  | Akurasi: 93.0%                  | | Akurasi: 88.0%               | |
|  +---------------------------------+ +------------------------------+ |
|                                                                       |
|  Tingkat Ancaman: [ TINGGI ]                                          |
|                                                                       |
|  DESKRIPSI HASIL ANALISIS:                                            |
|  Wereng Coklat (Nilaparvata lugens) menghisap cairan tanaman padi     |
|  menyebabkan daun menguning, mengering (hopperburn), dan tanaman mati.|
|                                                                       |
|  REKOMENDASI PENANGANAN:                                              |
|  1. Atur jarak tanam legowo untuk mengurangi kelembapan.              |
|  2. Lestarikan musuh alami seperti laba-laba sawah.                   |
|  3. Semprotkan insektisida pymetrozine jika populasi tinggi.          |
+-----------------------------------------------------------------------+
```

### 🧩 Mekanisme Validasi AI Ketat & Proteksi Gambar Non-Padi:
Sistem dilengkapi dengan **Penolakan Otomatis Gambar Non-Padi** dengan pesan yang spesifik:
- ❌ **Wajah / Tubuh Manusia**: *"Gambar terdeteksi sebagai wajah atau tubuh manusia — bukan tanaman padi."*
- ❌ **Makanan / Kemasan**: *"Gambar terdeteksi sebagai makanan atau kemasan produk — bukan tanaman padi."*
- ❌ **Tembok / Lantai Polos**: *"Gambar terdeteksi sebagai tembok, lantai, atau permukaan polos — bukan tanaman padi."*
- ❌ **Parkiran / Jalan Asphalt**: *"Gambar terdeteksi sebagai area parkiran, jalan, atau bangunan — bukan tanaman padi."*
- ❌ **Ruangan Indoor / Gelap**: *"Gambar terdeteksi sebagai ruangan indoor atau area gelap — bukan tanaman padi."*

---

## 🛠️ 7. SPESIFIKASI ENDPOINT BACKEND API (PHP & MYSQL)

Backend PadiGuard menyediakan API RESTful murni yang aman dan teruji:

| Endpoint | Method | Fungsi | Respon Status |
|----------|--------|--------|---------------|
| `/api/health` | GET | Cek koneksi database & dataset count (1.376) | `200 OK` JSON |
| `/api/version` | GET | Cek versi build backend & status fitur AI | `200 OK` JSON |
| `/api/auth/login` | POST | Authentikasi email/password & pembuatan token JWT | `200 OK` JSON |
| `/api/auth/register` | POST | Pendaftaran akun baru petani | `201 Created` |
| `/api/detection` | POST | Proses analisis inferensi gambar (YOLOv12 + Gemini AI) | `201 Created` |
| `/api/detection/history`| GET | Mengambil daftar riwayat deteksi pengguna | `200 OK` JSON |
| `/api/admin/dashboard` | GET | Mengambil statistik KPI & grafik admin | `200 OK` JSON |
| `/api/admin/users` | GET/POST/PUT/DELETE | Pengelolaan akun pengguna oleh Admin | `200/201` JSON |
| `/api/admin/detections`| GET/DELETE | Pengelolaan riwayat deteksi oleh Admin | `200 OK` JSON |
| `/api/admin/dataset` | GET | Mengambil daftar sampel dataset padi (1.376 data) | `200 OK` JSON |

---

## 📄 8. PETUNJUK PENGGUNAAN FILE DOKUMENTASI INI

File dokumentasi ini disimpan langsung di dalam repositori proyek Anda pada path:
1. **Root Folder Proyek**: `c:\laragon\www\KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI\DOKUMENTASI_HASIL_PROYEK_PADIGUARD.md`
2. **Format File**: Markdown Standard (GFM) yang dapat dibuka melalui Text Editor, Visual Studio Code, Notepad, atau diubah menjadi format PDF / Word untuk lampiran laporan skripsi.

---
*Dokumentasi ini disusun secara otomatis dan diperbarui untuk proyek PadiGuard 2026.*
