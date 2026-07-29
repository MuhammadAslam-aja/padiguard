"""
upload_model_kematangan.py
==========================
Script untuk upload model YOLOv12 kematangan ke Roboflow
Project: kematangan-ieouc (muhammad-aslam-s-workspace)

PERSIAPAN:
  Letakkan file weights kematangan di salah satu lokasi berikut (urutan prioritas):
    1. best_kematangan.pt  <- di folder root project ini (DISARANKAN)
    2. best.pt             <- di folder root (akan dipakai jika tidak ada best_kematangan.pt)

Cara pakai:
  1. Buka terminal / CMD di folder root project ini
  2. Jalankan: python upload_model_kematangan.py
"""

import os
import shutil
import sys

# ──────────────────────────────────────────────
# KONFIGURASI
# ──────────────────────────────────────────────
API_KEY        = "nsRtr9srM0kLon24RWka"
WORKSPACE      = "muhammad-aslam-s-workspace"
PROJECT        = "kematangan-ieouc"
VERSION        = 1
MODEL_TYPE     = "yolov12"
UPLOAD_FOLDER  = "kematangan_upload"

# ──────────────────────────────────────────────
# CARI FILE WEIGHTS (prioritas: best_kematangan.pt -> best.pt)
# ──────────────────────────────────────────────
script_dir = os.path.dirname(os.path.abspath(__file__))

weights_candidates = [
    os.path.join(script_dir, "best_kematangan.pt"),
    os.path.join(script_dir, "best.pt"),
]

weights_path = None
for candidate in weights_candidates:
    if os.path.exists(candidate):
        weights_path = candidate
        break

if weights_path is None:
    print("[ERROR] Tidak ada file weights (.pt) ditemukan!")
    print()
    print("Silakan letakkan salah satu file berikut di folder root project:")
    print("  - best_kematangan.pt  (file khusus model kematangan) <-- DISARANKAN")
    print("  - best.pt             (file weights umum)")
    print()
    print("Cara mendapatkan best_kematangan.pt:")
    print("  1. Training model YOLO lokal dengan dataset kematangan")
    print("     python train_kematangan.py")
    print()
    print("  2. Download dari Roboflow (model yang sudah ada):")
    print("     - Buka: https://app.roboflow.com/muhammad-aslam-s-workspace/kematangan-ieouc/models")
    print("     - Klik model kematangan-ieouc-1-yolo11n-t1")
    print("     - Klik 'Download Weights'")
    sys.exit(1)

print(f"[OK] File weights ditemukan: {os.path.basename(weights_path)}")
print(f"     Path  : {weights_path}")
print(f"     Ukuran: {os.path.getsize(weights_path) / 1024 / 1024:.2f} MB")
print()

# ──────────────────────────────────────────────
# BUAT FOLDER UPLOAD & SALIN WEIGHTS
# ──────────────────────────────────────────────
upload_dir = os.path.join(script_dir, UPLOAD_FOLDER)
os.makedirs(upload_dir, exist_ok=True)

dest_weights = os.path.join(upload_dir, "best.pt")
shutil.copy2(weights_path, dest_weights)
print(f"[OK] Salin ke folder upload: {upload_dir}")

# ──────────────────────────────────────────────
# CEK & IMPORT roboflow
# ──────────────────────────────────────────────
try:
    from roboflow import Roboflow
    print("[OK] Library roboflow sudah terinstall.")
except ImportError:
    print("[INFO] Menginstall library roboflow...")
    os.system(f"{sys.executable} -m pip install roboflow")
    from roboflow import Roboflow
    print("[OK] Instalasi roboflow selesai.")

print()

# ──────────────────────────────────────────────
# UPLOAD MODEL KE ROBOFLOW
# ──────────────────────────────────────────────
print("=" * 55)
print(" UPLOAD YOLOv12 MODEL KEMATANGAN KE ROBOFLOW")
print("=" * 55)
print(f" Workspace : {WORKSPACE}")
print(f" Project   : {PROJECT}")
print(f" Version   : {VERSION}")
print(f" Model Type: {MODEL_TYPE}")
print(f" Weights   : {os.path.basename(weights_path)}")
print("=" * 55)
print()

try:
    rf      = Roboflow(api_key=API_KEY)
    project = rf.workspace(WORKSPACE).project(PROJECT)
    version = project.version(VERSION)

    print("[INFO] Memulai upload... (bisa memakan waktu beberapa menit)")
    version.deploy(
        model_type=MODEL_TYPE,
        model_path=upload_dir,
        filename="best.pt"
    )
    print()
    print("[SUCCESS] Model kematangan berhasil diupload ke Roboflow!")
    print(f"          Cek di: https://app.roboflow.com/{WORKSPACE}/{PROJECT}/models")

except Exception as e:
    err = str(e)
    print(f"[ERROR] Upload gagal: {err}")
    print()

    if "version" in err.lower() or "404" in err:
        print("[INFO] Coba ganti VERSION = 2 atau VERSION = 3 di script ini,")
        print("       sesuaikan dengan versi yang tersedia di Roboflow.")
    else:
        print("Kemungkinan penyebab:")
        print("  1. Versi project tidak cocok  -> ganti VERSION")
        print("  2. Koneksi internet bermasalah")
        print("  3. API key tidak memiliki akses ke project kematangan")
        print()
        print("Alternatif - upload manual via website:")
        print("  1. Buka: https://app.roboflow.com/muhammad-aslam-s-workspace/kematangan-ieouc/models")
        print("  2. Klik ikon panah atas di samping model")
        print("  3. Pilih tipe YOLOv12, upload best_kematangan.pt")

finally:
    if os.path.exists(upload_dir):
        shutil.rmtree(upload_dir)
        print(f"\n[OK] Folder sementara '{UPLOAD_FOLDER}' dihapus.")
