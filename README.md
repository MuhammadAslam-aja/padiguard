# 🌾 PadiGuard — Klasifikasi Hama & Kematangan Tanaman Padi

Aplikasi Flutter + PHP Backend untuk mendeteksi **jenis hama** dan **tingkat kematangan** tanaman padi menggunakan AI (YOLOv12 + Gemini Vision).

## 🚀 Tech Stack

| Komponen | Teknologi |
|----------|-----------|
| Mobile App | Flutter (Dart) |
| Backend API | PHP 8.3 |
| Database | MySQL |
| AI Deteksi Hama | Roboflow YOLOv12 |
| AI Validasi Gambar | Google Gemini 1.5 Flash |
| Hosting | Railway.app |

## 🌿 Fitur Utama

- ✅ Deteksi 4 jenis hama: Wereng Coklat, Walang Sangit, Ulat Grayak, Penggerek Batang
- ✅ Analisis kematangan: Mentah, Setengah Matang, Matang
- ✅ Validasi gambar 2 lapis (hanya foto tanaman padi yang diterima)
- ✅ Bounding box hasil deteksi
- ✅ Rekomendasi penanganan otomatis
- ✅ Riwayat deteksi per pengguna
- ✅ Info cuaca sawah real-time

## 🛠️ Setup Lokal (Laragon)

### Prasyarat
- Laragon (PHP 8.x + MySQL)
- Flutter SDK
- Python 3.x

### Jalankan Backend
1. Copy folder `backend/` ke `C:/laragon/www/`
2. Aktifkan Laragon
3. Akses: `http://localhost/KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI/backend/api/`

### Jalankan Flutter App
```bash
flutter pub get
flutter run
```

## 🚂 Deploy ke Railway

### 1. Buat Service MySQL di Railway
- Buka [railway.app](https://railway.app) → New Project → Add MySQL
- Catat credentials dari tab **Variables**

### 2. Deploy Backend PHP
- Connect ke GitHub repository ini
- Railway akan otomatis detect PHP dan deploy
- Set environment variables dari `.env.example`

### 3. Environment Variables yang Dibutuhkan
```
MYSQLHOST=xxx.railway.internal
MYSQLPORT=3306
MYSQLDATABASE=railway
MYSQLUSER=root
MYSQLPASSWORD=xxx
```

## 📁 Struktur Proyek

```
├── backend/              # PHP API Server
│   ├── index.php         # Router utama semua endpoint
│   ├── connection.php    # Koneksi MySQL (Railway + Laragon)
│   └── uploads/          # Folder penyimpanan gambar
├── lib/                  # Flutter Source Code
│   ├── features/         # Fitur (detection, auth, history, dll)
│   ├── services/         # API service layer
│   └── main.dart         # Entry point Flutter
├── assets/               # Asset gambar & font
├── railway.json          # Konfigurasi Railway deploy
├── nixpacks.toml         # Konfigurasi PHP build
└── .env.example          # Template environment variables
```

## 🤝 Author

**Muhammad Aslam** — [@MuhammadAslam-aja](https://github.com/MuhammadAslam-aja)
