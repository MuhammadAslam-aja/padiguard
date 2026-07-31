# STRUKTUR STRUKTURAL LENGKAP ROOT DIREKTORI PADIGUARD

Berikut adalah struktur lengkap seluruh berkas (*file*) dan folder di root proyek **PadiGuard**, diformat persis dalam bentuk Pohon ASCII (*Directory Tree Diagram*) lengkap dengan penjelas panah kanan (`←`):

```text
KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI/
├── lib/                                          ← Kode Utama Flutter Web & Mobile Frontend
│   ├── main.dart                                 ← Entry point utama aplikasi Flutter
│   ├── app.dart                                  ← Root widget (MaterialApp + Provider + Routing)
│   ├── config/                                   ← Konfigurasi global aplikasi
│   │   ├── constants.dart                        ← Semua konstanta (URL API, tips, rekomendasi hama)
│   │   ├── routes.dart                           ← Routing & navigasi antar halaman aplikasi
│   │   └── theme.dart                            ← Tema warna dark mode & tipografi Google Fonts
│   ├── services/                                 ← Layanan komunikasi data & API
│   │   ├── dio_client.dart                       ← HTTP Client API Driver (Dio + Interceptor JWT)
│   │   ├── api_mock_data.dart                    ← Data fallback offline / mock API
│   │   ├── secure_storage.dart                   ← Penyimpanan aman Token JWT (FlutterSecureStorage)
│   │   ├── shared_prefs.dart                     ← Penyimpanan preferensi & sesi pengguna lokal
│   │   └── weather_service.dart                  ← Integration API Layanan Cuaca Sawah (OpenWeather)
│   ├── core/                                     ← Core shared utilities & reusable widgets
│   │   ├── providers/
│   │   │   └── core_providers.dart               ← Central Provider state management
│   │   ├── utils/
│   │   │   ├── app_notification.dart             ← Dialog notifikasi & toast pesan error
│   │   │   ├── web_camera_web.dart               ← Utilitas pengambil gambar kamera via browser
│   │   │   └── web_camera_stub.dart              ← Stub kamera untuk kompatibilitas multi-platform
│   │   └── widgets/
│   │       ├── auth_responsive_wrapper.dart      ← Wrapper antarmuka responsif Mobile/Desktop
│   │       └── yolo_bounding_box.dart            ← Widget penggambar overlay Bounding Box YOLOv12
│   └── features/                                 ← Fitur-fitur utama sistem (Modular Architecture)
│       ├── auth/                                 ← Modul autentikasi pengguna
│       │   └── presentation/pages/
│       │       ├── splash_page.dart              ← Halaman animasi pembuka (Splash Screen)
│       │       ├── onboarding_page.dart          ← Halaman pengenalan sistem (Onboarding Slider)
│       │       ├── login_page.dart               ← Halaman masuk akun Admin & Petani + Guest Mode
│       │       └── register_page.dart            ← Halaman pendaftaran akun Petani baru
│       ├── dashboard_petani/                     ← Modul beranda utama petani
│       │   └── presentation/pages/
│       │       ├── petani_home_page.dart         ← Beranda ringkasan cuaca, tips, & riwayat
│       │       └── petani_shell_layout.dart      ← Layout navigasi bawah (Bottom Navigation Bar)
│       ├── detection/                            ← Modul utama pemindaian & klasifikasi padi
│       │   └── presentation/pages/
│       │       └── detection_page.dart           ← Halaman scan kamera/upload + bounding box AI
│       ├── history/                              ← Modul riwayat deteksi
│       │   └── presentation/pages/
│       │       └── history_page.dart             ← Daftar riwayat hasil analisis sawah pengguna
│       ├── profile/                              ← Modul profil pengguna
│       │   └── presentation/pages/
│       │       └── profile_page.dart             ← Halaman informasi akun & pengaturan profil
│       └── admin/                                ← Modul panel kendali administrator
│           └── presentation/pages/
│               ├── admin_shell_layout.dart       ← Sidebar & header layout SPA Admin
│               ├── admin_dashboard_page.dart     ← Dashboard statistik KPI & grafik distribusi AI
│               ├── admin_users_page.dart         ← Halaman Kelola User (CRUD Petani & Admin)
│               ├── admin_detections_page.dart    ← Halaman kelola & audit riwayat deteksi sawah
│               └── admin_dataset_page.dart       ← Halaman galeri & audit 1.376 dataset visual
├── backend/                                      ← Kode Utama Backend REST API (PHP 8.2 & MySQL)
│   ├── index.php                                 ← Central Router API, CORS, & Endpoint Controller
│   ├── inference_engine.php                      ← Engine 5-Layer AI (Gemini, YOLO, Hash, Pixel)
│   ├── connection.php                            ← Handler PDO MySQL & Auto-Seeder 1.376 Dataset
│   ├── database.sql                              ← Skema tabel database MySQL (users, detections)
│   ├── dataset_seed.sql                          ← Data seeder 1.376 hash dataset padi (311 KB)
│   ├── cli_audit.php                             ← Script CLI pengujian otomatis 100 gambar
│   ├── benchmark_suite.php                       ← Suite tolok ukur latensi & akurasi Railway vs Laragon
│   ├── import_dataset.php                        ← Converter visual hashing dataset ke MySQL
│   ├── uploads/                                  ← Folder penyimpanan foto hasil scan pengguna
│   └── dataset_samples/                          ← Folder direktori foto sampel dataset terkalibrasi
├── assets/                                       ← Aset gambar statis & icon aplikasi
│   ├── icons/                                    ← Logo & icon aplikasi PadiGuard
│   ├── images/                                   ← Gambar ilustrasi sawah & hama padi
│   └── sample_padi/                              ← Sampel gambar untuk pengujian offline
├── Dockerfile                                    ← Konfigurasi kontainerisasi NGINX + PHP 8.2 Railway
├── entrypoint.sh                                 ← Script startup otomatis service NGINX & PHP-FPM
├── best.pt                                       ← Bobot model YOLOv12 PyTorch Hama Padi (5.5 MB)
├── best_kematangan.pt                            ← Bobot model YOLOv12 PyTorch Kematangan Padi (5.5 MB)
├── pubspec.yaml                                  ← Dependensi pustaka Flutter (Dio, Provider, Fonts)
├── pubspec.lock                                  ← Kunci versi dependensi pustaka Flutter
├── analysis_options.yaml                         ← Konfigurasi linter & aturan analisis sintaks Dart
├── benchmark_latency.csv                         ← Data mentah pengujian latensi inferensi Railway
├── hasil_pengujian_100_gambar.csv                ← Matriks pengujian paritas 100 gambar (Laragon vs Railway)
├── hasil_pengujian_100_gambar.xlsx               ← Laporan Excel hasil pengujian 100 gambar sawah
└── README.md                                     ← Panduan umum cara instalasi & menjalankan proyek
```
