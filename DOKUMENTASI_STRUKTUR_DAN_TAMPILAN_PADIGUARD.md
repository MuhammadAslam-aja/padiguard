# DOKUMENTASI STRUKTUR ROOT FOLDER & DESKRIPSI TAMPILAN SISTEM PADIGUARD

Dokumen ini menyajikan struktur lengkap **Root Folder Proyek PadiGuard** beserta diagram visual dan tabel deskripsi berdampingan (*side-by-side*) untuk memudahkan pemahaman arsitektur sistem, file backend, serta tampilan antarmuka (UI/UX).

---

## 📁 1. DIAGRAM VISUAL STRUKTUR ROOT FOLDER PROYEK

Berikut adalah struktur peta pohon (*tree structure*) dari seluruh folder dan file di root direktori proyek PadiGuard:

```mermaid
graph TD
    Root["📂 ROOT: KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI"]
    
    Root --> Backend["📂 backend/ (API & Engine AI)"]
    Root --> Lib["📂 lib/ (Flutter Web/Mobile Frontend)"]
    Root --> Web["📂 web/ (Asset Deployment Web)"]
    Root --> Assets["📂 assets/ (Gambar & Model PT)"]
    Root --> Docker["📄 Dockerfile & entrypoint.sh"]
    Root --> Model["📄 best.pt & best_kematangan.pt"]
    Root --> Config["📄 pubspec.yaml & analysis_options.yaml"]

    Backend --> BIndex["📄 index.php (API Routing & CORS)"]
    Backend --> BEngine["📄 inference_engine.php (5-Layer AI Engine)"]
    Backend --> BConn["📄 connection.php (Database MySQL & Auto-Seeder)"]
    Backend --> BData["📄 dataset_seed.sql (1,376 Data Hash)"]
    Backend --> BUpload["📂 uploads/ & dataset_samples/"]

    Lib --> Auth["📂 features/auth (Login & Register)"]
    Lib --> Admin["📂 features/admin (Dashboard, Users, Detections, Dataset)"]
    Lib --> Petani["📂 features/detection (Scan Padi & Bounding Box)"]
    Lib --> Core["📂 core/ & services/ (API Driver & State)"]

    Auth --> FLogin["📄 login_page.dart"]
    Admin --> FDash["📄 admin_dashboard_page.dart"]
    Admin --> FUser["📄 admin_users_page.dart"]
    Admin --> FDet["📄 admin_detections_page.dart"]
    Petani --> FScan["📄 detection_page.dart"]
```

---

## 🗺️ 2. TABEL PETA FOLDER ROOT & DESKRIPSI LENGKAP (SIDE-BY-SIDE)

Tabel berikut menjelaskan fungsi setiap elemen yang berada langsung di **Root Folder Proyek**:

| Folder / File di Root | Komponen / Isi Utama | Deskripsi & Fungsi Lengkap di Sampingnya |
| :--- | :--- | :--- |
| **`📂 backend/`** | `index.php`<br>`inference_engine.php`<br>`connection.php`<br>`dataset_seed.sql` | **Core Backend REST API & Engine AI**<br>Menangani seluruh logika backend PHP, validasi piksel multi-kategori, panggilan Gemini Vision AI API, pencocokan Visual Hash (1.376 data), serta routing API murni JSON. |
| **`📂 lib/`** | `main.dart`<br>`app.dart`<br>`features/auth/`<br>`features/admin/`<br>`features/detection/` | **Source Code Antarmuka Flutter (Web & Mobile)**<br>Berisi seluruh halaman UI (Login, Dashboard Admin, Scan Padi, Kelola User, Riwayat Deteksi) menggunakan arsitektur modular Feature-First. |
| **`📂 web/`** | `index.html`<br>`manifest.json`<br>`favicon.png` | **Aset Deployment Flutter Web**<br>File pendukung hosting web yang memungkinkan aplikasi Flutter di-build dan di-deploy ke Railway/Web Server secara responsif. |
| **`📂 assets/`** | `icons/`<br>`images/`<br>`sample_padi/` | **Aset Visual & Gambar Statis**<br>Menyimpan icon tanaman padi, gambar ilustrasi onboarding, logo PadiGuard, serta contoh gambar sampel padi untuk antarmuka. |
| **`📄 Dockerfile`** | `PHP 8.2-FPM`<br>`NGINX`<br>`output_buffering=4096` | **Konfigurasi Environment Railway Deployment**<br>Instruksi kontainerisasi Docker untuk menyatukan NGINX dan PHP-FPM di Railway agar respons JSON murni tanpa warning PHP. |
| **`📄 best.pt` & `best_kematangan.pt`** | Model Weights YOLOv12 PyTorch (5.5 MB) | **Bobot Model Deep Learning lokal**<br>File model hasil training PyTorch untuk klasifikasi 4 hama padi dan 3 fase kematangan yang disinkronkan ke Roboflow API. |
| **`📄 pubspec.yaml`** | Dependencies Flutter, HTTP, Provider, Charts | **Manajemen Dependensi Aplikasi**<br>Mengatur pustaka external Flutter seperti Google Fonts, HTTP Client, Image Picker, Chart visualizer, dan SVG renderer. |
| **`📄 entrypoint.sh`** | Script startup container Railway | **Script Inisialisasi Server**<br>Menjalankan service NGINX dan PHP-FPM secara otomatis saat kontainer Railway dinyalakan (*bootup*). |

---

## 🔐 3. TAMPILAN HALAMAN LOGIN & DESKRIPSI LENGKAP (`login_page.dart`)

Halaman Login berada di `lib/features/auth/presentation/pages/login_page.dart`. Berikut adalah rancangan visual tampilan dan penjelasan fungsinya secara berdampingan:

| Tampilan Visual Mockup UI Login | Deskripsi & Alur Kerja Sistem di Sampingnya |
| :--- | :--- |
| <pre>+------------------------------------+<br>|             PADIGUARD              |<br>|   Sistem Deteksi Hama & Kematangan |<br>+------------------------------------+<br>|                                    |<br>|  [ 🌾 Logo PadiGuard ]             |<br>|                                    |<br>|  Selamat Datang Kembali!           |<br>|                                    |<br>|  Email                             |<br>|  [ aslam@gmail.com               ] |<br>|                                    |<br>|  Password                          |<br>|  [ **********                  👁️ ] |<br>|                                    |<br>|  [    MASUK SEKARANG    ]          |<br>|                                    |<br>|  ----------------- ATAU ---------- |<br>|  [ Masuk Tanpa Login (Guest) ]     |<br>|                                    |<br>|  Belum punya akun? [Daftar]        |<br>+------------------------------------+</pre> | **1. Autentikasi Berbasis Role (RBAC)**:<br>• Memeriksa email dan password via API `POST /api/auth/login`.<br>• Jika role = `admin`, pengguna diarahkan ke **Dashboard Admin** (`/admin/dashboard`).<br>• Jika role = `petani`, pengguna diarahkan ke **Scan Padi** (`/petani/home`).<br><br>**2. Fitur Keamanan & UX**:<br>• Toggle mata (visibility) password.<br>• Penyimpanan Token JWT di local storage.<br>• Validation error dialog jika email/password salah.<br><br>**3. Akses Cepat Petani (Guest Mode)**:<br>• Tombol *"Masuk Tanpa Login"* memungkinkan petani langsung melakukan scan tanpa registrasi. |

---

## 📊 4. TAMPILAN DASHBOARD ADMIN & DESKRIPSI LENGKAP (`admin_dashboard_page.dart`)

Halaman Dashboard Admin berada di `lib/features/admin/presentation/pages/admin_dashboard_page.dart`.

| Tampilan Visual Mockup Dashboard Admin | Deskripsi & Fungsi Widget di Sampingnya |
| :--- | :--- |
| <pre>+--------------------------------------------------------+<br>| PadiGuard Admin | [Dashboard] [User] [Deteksi] (Admin v) |<br>+--------------------------------------------------------+<br>| STATISTIK UTAMA SISTEM                                  |<br>| +----------------+ +---------------+ +---------------+ |<br>| | Total Deteksi  | | Total Petani  | | Akurasi AI    | |<br>| |   1,428 Kali   | |   34 Orang    | |   96.2 %      | |<br>| +----------------+ +---------------+ +---------------+ |<br>|<br>| +-------------------------+ +------------------------+ |<br>| | GRAFIK DISTRIBUSI HAMA  | | GRAFIK KEMATANGAN PADI | |<br>| | ■ Wereng Coklat (45%)   | | ■ Matang         (40%) | |<br>| | ■ Penggerek     (30%)   | | ■ Setengah Matang(48%) | |<br>| | ■ Walang Sangit (15%)   | | ■ Mentah         (12%) | |<br>| +-------------------------+ +------------------------+ |<br>+--------------------------------------------------------+</pre> | **1. Kartu Metric Utama (KPI Cards)**:<br>• Memuat data agregasi *real-time* dari MySQL (`totalDetections`, `totalUsers`, `mostCommonHama`, `systemAccuracy`).<br><br>**2. Visualisasi Grafik Interaktif**:<br>• **Diagram Distribusi Hama**: Menampilkan rasio serangan Wereng Coklat, Penggerek Batang, Walang Sangit, dan Ulat Grayak.<br>• **Diagram Kematangan Padi**: Menampilkan proporsi padi Mentah, Setengah Matang, dan Matang.<br>• **Grafik Tren Mingguan**: Frekuensi pemindaian dari Senin sampai Minggu.<br><br>**3. Navigasi Sidebar Responsif**:<br>• Akses instan ke Kelola User, Riwayat Deteksi, dan Dataset Padi. |

---

## 👥 5. TAMPILAN KELOLA USER ADMIN (`admin_users_page.dart`)

Halaman Kelola User berada di `lib/features/admin/presentation/pages/admin_users_page.dart`.

| Tampilan Visual Mockup Kelola User | Deskripsi & Fungsi Manajemen User di Sampingnya |
| :--- | :--- |
| <pre>+--------------------------------------------------------+<br>| KELOLA USER & PETANI              [ + Tambah User ]    |<br>| Cari: [ Search email... ]   Filter: [ Semua Role v ]   |<br>+--------------------------------------------------------+<br>| Nama            | Email               | Role   | Aksi  |<br>+-----------------+---------------------+--------+-------+<br>| Tirza Marsena   | admin@padiguard.com | Admin  | [Edit]|<br>| Aslam           | aslam@gmail.com     | Petani | [Edit]|<br>| Pak Budi        | budi@petani.com     | Petani | [Hapus|<br>+--------------------------------------------------------+</pre> | **1. Manajemen Akun Pengguna (CRUD)**:<br>• **Tambah User Baru**: Menambahkan akun Petani/Admin baru ke database.<br>• **Edit User**: Mengubah nama, email, role, atau me-reset password.<br>• **Hapus User**: Menghapus hak akses pengguna.<br><br>**2. Fitur Pencarian & Filter**:<br>• Filter cepat berdasarkan role (`admin` / `petani`).<br>• Pencarian real-time berdasarkan kata kunci nama atau email. |

---

## 🌾 6. TAMPILAN SCAN PADI PETANI (`detection_page.dart`)

Halaman Scan Padi berada di `lib/features/detection/presentation/pages/detection_page.dart`.

| Tampilan Visual Mockup Scan Padi | Deskripsi & Sistem Validasi AI di Sampingnya |
| :--- | :--- |
| <pre>+------------------------------------+<br>| DETEKSI PADI YOLOV12 & GEMINI AI    |<br>+------------------------------------+<br>|                                    |<br>|  +------------------------------+  |<br>|  | [ Matang (88%) ]             |  |<br>|  | +--------------------------+ |  |<br>|  | | [Wereng Coklat (93%)]    | |  |<br>|  | | FOTO TANAMAN PADI SAWAH  | |  |<br>|  | +--------------------------+ |  |<br>|  +------------------------------+  |<br>|                                    |<br>|  Hama Terdeteksi: Wereng Coklat    |<br>|  Kematangan Padi: Matang           |<br>|  Tingkat Ancaman: [ TINGGI ]       |<br>|                                    |<br>|  REKOMENDASI PENANGANAN:           |<br>|  1. Semprotkan insektisida.        |<br>|  2. Atur jarak tanam legowo.       |<br>+------------------------------------+</pre> | **1. Multi-Layer AI Inference Engine**:<br>• **Overlay Bounding Box Terpusat**: Menampilkan lokasi hama dengan kotak oranye/hijau yang terpusat dan jelas di tengah gambar.<br>• **Deterministik & Cepat**: Respons analisis selesai dalam **< 3 detik**.<br><br>**2. Penolakan Otomatis Gambar Non-Padi**:<br>• ❌ **Wajah Manusia**: *"Gambar terdeteksi sebagai wajah/tubuh manusia."*<br>• ❌ **Makanan/Saos**: *"Gambar terdeteksi sebagai makanan/kemasan."*<br>• ❌ **Tembok/Lantai**: *"Gambar terdeteksi sebagai tembok/lantai polos."*<br>• ❌ **Parkiran/Jalan**: *"Gambar terdeteksi sebagai area parkiran/jalan."* |

---

## 💾 7. PENYIMPANAN FILE DOKUMENTASI INI

File dokumentasi visual ini telah disimpan di dalam proyek Anda pada lokasi:
- **Root Project Directory**: `c:\laragon\www\KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI\DOKUMENTASI_STRUKTUR_DAN_TAMPILAN_PADIGUARD.md`
- **Link Langsung**: [DOKUMENTASI_STRUKTUR_DAN_TAMPILAN_PADIGUARD.md](file:///c:/laragon/www/KLASIFIKASI%20JENIS%20HAMA%20DAN%20KEMATANGAN%20TANAMAN%20PADI/DOKUMENTASI_STRUKTUR_DAN_TAMPILAN_PADIGUARD.md)

---
*Dokumentasi struktur root folder dan tampilan UI disusun secara visual dan komprehensif untuk proyek PadiGuard.*
