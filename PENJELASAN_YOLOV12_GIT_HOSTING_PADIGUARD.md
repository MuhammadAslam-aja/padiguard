# PENJELASAN LENGKAP FOLDER YOLOV12, GIT PUSH GITHUB, .GITIGNORE, DAN HOSTING RAILWAY

Dokumen ini berisi penjelasan detail **per poin, per folder, dan per file** mengenai komponen kecerdasan buatan (YOLOv12), mekanisme Git Version Control (`.git` & `.gitignore`), serta infrastruktur hosting cloud (Railway).

---

## 🤖 1. PENJELASAN FOLDER `yolov12n/` & MODEL AI DEEP LEARNING

Folder `yolov12n/` adalah direktori pusat pengawasan dan pengelolaan model **Object Detection YOLOv12 (You Only Look Once version 12)** untuk mengklasifikasikan 4 jenis hama dan 3 fase kematangan tanaman padi.

### 📌 Apa itu YOLOv12 dalam Proyek PadiGuard?
YOLOv12 adalah algoritma Deep Learning Convolutional Neural Network (CNN) tercepat dan terpresisi tinggi yang bertugas menemukan letak objek (*bounding box*) hama dan bulir padi pada foto sawah.

### 📂 Rincian File di Dalam Folder `yolov12n/`:

* **`📄 upload_model_yolov12.py`**
  - **Fungsi**: Script otomatisasi Python yang mengunggah dan mensinkronkan bobot model PyTorch YOLOv12 Hama Padi (`best.pt`) ke Cloud Server Roboflow.
  - **Target Project Roboflow**: `jenis-hama-hlar6` versi `1`.
  - **Cara Kerja**: Membaca gambar dataset, menyesuaikan format label Bounding Box, lalu mengunggah model ke API Roboflow agar dapat dipanggil oleh backend PHP.

* **`📄 upload_model_kematangan.py`**
  - **Fungsi**: Script otomatisasi Python untuk mensinkronkan model Kematangan Padi (`best_kematangan.pt`) ke Cloud Server Roboflow.
  - **Target Project Roboflow**: `kematangan-ieouc` versi `1`.

* **`📄 model_config.env`**
  - **Fungsi**: Berkas konfigurasi variabel lingkungan khusus untuk script Python deployment model, memuat `ROBOFLOW_API_KEY`, `PROJECT_ID`, dan `VERSION_ID`.

* **`📄 README.md`**
  - **Fungsi**: Petunjuk langkah-langkah *re-training* (pelatihan ulang) model jika ada penambahan foto dataset baru di masa mendatang.

---

### 📦 File Bobot Model (`.pt`) di Root Directory:

* **`📄 best.pt` (Ukuran: ~5.5 MB)**
  - **Fungsi**: File bobot (*weights*) hasil training PyTorch untuk **Deteksi 4 Jenis Hama Utama**: *Wereng Coklat*, *Walang Sangit*, *Penggerek Batang*, dan *Ulat Grayak*.

* **`📄 best_kematangan.pt` (Ukuran: ~5.5 MB)**
  - **Fungsi**: File bobot (*weights*) hasil training PyTorch untuk **Klasifikasi 3 Fase Kematangan Padi**: *Mentah*, *Setengah Matang*, dan *Matang*.

---

## 🐙 2. DIMANA FOLDER UNTUK PROSES GIT PUSH KE GITHUB?

### 📁 Lokasi Folder Git:
Proses `git push` dan pengelolaan repositori versi seluruhnya dikendalikan oleh folder tersembunyi (*hidden folder*):
👉 **`KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI/.git/`**

```
KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI/
├── .git/                                         ← FOLDER PUSAT KONTROL GIT (Hidden)
│   ├── config                                    ← Menyimpan URL Remote GitHub (padiguard.git)
│   ├── HEAD                                      ← Pointer branch aktif saat ini (refs/heads/main)
│   ├── index                                     ← Staging area penyimpanan perubahan sementara
│   └── refs/heads/main                           ← Commit Hash terbaru di branch main
```

### 🔗 Informasi Repositori GitHub PadiGuard:
* **URL Repositori Remote**: `https://github.com/MuhammadAslam-aja/padiguard.git`
* **Branch Utama**: `main`

### 🚀 Alur Kerja & Perintah `git push` ke GitHub:
1. `git status` → Memeriksa berkas mana saja yang baru diubah atau dibuat.
2. `git add .` → Menambahkan seluruh perubahan ke *staging area*.
3. `git commit -m "pesan perbaikan"` → Menyimpan catatan riwayat perubahan di lokal komputer `.git`.
4. `git push origin main` → **Mengunggah (upload)** seluruh commit dari komputer lokal ke repositori GitHub `MuhammadAslam-aja/padiguard`.

---

## 🛡️ 3. APA ITU `.GITIGNORE` & PENJELASAN FILE DI DALAMNYA?

### 📌 Konsep & Fungsi `.gitignore`:
`.gitignore` adalah berkas teks konfigurasi penting di root folder yang memberi tahu sistem Git **berkas atau folder mana saja yang HARUS DIABAIKAN (tidak boleh di-push ke GitHub)**.

### 💡 Mengapa `.gitignore` Sangat Krusial?
1. **Keamanan Kredensial (Security)**: Mencegah bocornya kunci rahasia (*API Secret Keys*) seperti file `.env` ke publik repository.
2. **Efisiensi Ukuran Repositori**: Mencegah file temporary/build yang berukuran **Raksasa (ber-GigaByte)** ikut terunggah ke GitHub.

### 📋 Rincian Aturan & Folder yang Dikecualikan di `.gitignore` PadiGuard:

| Pola / Path di `.gitignore` | Kategori File | Alasan Mengapa Dikecualikan dari Git Push |
| :--- | :--- | :--- |
| **`.env`**<br>`*.env.local` | Secret Keys | **Keamanan Kunci Rahasia**: Menyimpan API Key Gemini dan password database. Tidak boleh di-push agar tidak dicuri orang lain. |
| **`backend/uploads/`** | Foto Pengguna | **Mencegah Bloat Repositori**: Folder ini berisi ribuan foto sawah hasil upload pengguna. Jika di-push, ukuran GitHub akan membengkak ratusan MB. |
| **`*.pt`**<br>`*.weights`, `*.onnx` | Model AI Besar | **File Biner Besar**: File model PyTorch berukuran > 5 MB. Di-push terpisah via Roboflow Cloud. |
| **`Gambar Padi/`** | Dataset Mentah | **Dataset Raksasa**: Folder berisi ribuan foto sawah mentah sebelum diolah. |
| **`build/`**<br>`.dart_tool/`, `.idea/` | Build Artifacts | **File Hasil Kompilasi**: Folder hasil kompilasi Flutter Web/Android yang dibuat otomatis oleh komputer. |
| **`grep.exe.stackdump`**<br>`backend/request_log.txt` | File Error & Log | **File Temporary & Crash**: File log sementara yang dihasilkan saat debugging. |

---

## 🌐 4. SEPUTAR HOSTING & DEPLOYMENT RAILWAY (PRODUCTION CLOUD)

Sistem PadiGuard menggunakan **Railway Cloud Hosting** berbasis *Containerized Infrastructure*.

```
[ Developer Computer ]
         │
         │  1. git push origin main
         ▼
[ Repositori GitHub: padiguard.git ]
         │
         │  2. Webhook Auto-Trigger (CI/CD)
         ▼
[ Railway Cloud Server Hosting ]
         │  - Membaca Dockerfile & entrypoint.sh
         │  - Rebuild NGINX Web Server + PHP 8.2-FPM
         │  - Menjalankan Auto-Seeder Database MySQL (1,376 Data)
         ▼
[ Live Domain: https://padiguard-tirza.up.railway.app ]
```

### 📂 Rincian File & Komponen Hosting Railway:

* **`📄 Dockerfile`**
  - **Fungsi**: Berkas instruksi cetak biru (*blueprint*) kontainer Linux yang diproses oleh Railway.
  - **Isi Utama**:
    - Menginstall **PHP 8.2-FPM** dan **NGINX Web Server**.
    - Mengaktifkan ekstensi PHP `gd` (untuk manipulasi piksel gambar), `pdo_mysql`, dan `curl`.
    - Menyetel `output_buffering = 4096` dan `display_errors = Off` agar output API murni JSON tanpa warning HTML.

* **`📄 entrypoint.sh`**
  - **Fungsi**: Script shell startup yang dijalankan otomatis saat kontainer Railway dinyalakan (*bootup*).
  - **Isi Utama**: Menjalankan service NGINX di port HTTP (80/8080) dan PHP-FPM secara bersamaan.

* **`📄 .nixpacksignore`**
  - **Fungsi**: File pengabaian yang menginstruksikan Railway builder untuk menggunakan **Dockerfile khusus** kita, bukan autodetection Nixpacks standar.

* **`🌐 Live Railway Domain & SSL`**
  - **URL Production**: `https://padiguard-tirza.up.railway.app`
  - **Keamanan**: Dilengkapi dengan sertifikat keamanan **SSL/HTTPS gratis** otomatis dari Railway.
  - **Database MySQL Cloud**: Terhubung ke database MySQL Railway yang terisi **1.376 data visual hash dataset** secara otomatis (*auto-seed*).

---

## 💾 5. PENYIMPANAN FILE PENJELASAN INI

File penjelasan komprehensif ini telah disimpan di proyek Anda pada lokasi:
- **Root Project Directory**: `c:\laragon\www\KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI\PENJELASAN_YOLOV12_GIT_HOSTING_PADIGUARD.md`
- **Link Langsung File**: [PENJELASAN_YOLOV12_GIT_HOSTING_PADIGUARD.md](file:///c:/laragon/www/KLASIFIKASI%20JENIS%20HAMA%20DAN%20KEMATANGAN%20TANAMAN%20PADI/PENJELASAN_YOLOV12_GIT_HOSTING_PADIGUARD.md)

---
*Dokumentasi penjelas folder YOLOv12, Git, .gitignore, dan Hosting Railway disiapkan untuk proyek PadiGuard.*
