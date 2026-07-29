"""
upload_model_yolov12.py
=======================
Script untuk upload best.pt (YOLOv12) ke Roboflow
Project: jenis-hama-hlar6 (muhammad-aslam-s-workspace)

Cara pakai:
  1. Buka terminal / CMD di folder root project ini
  2. Jalankan: pip install roboflow
  3. Jalankan: python upload_model_yolov12.py
"""

import os
import shutil
import sys

# ──────────────────────────────────────────────
# KONFIGURASI (sesuaikan jika perlu)
# ──────────────────────────────────────────────
API_KEY        = "nsRtr9srM0kLon24RWka"
WORKSPACE      = "muhammad-aslam-s-workspace"
PROJECT        = "jenis-hama-hlar6"
VERSION        = 1
MODEL_TYPE     = "yolov12"          # Tipe model yang akan muncul di Roboflow
WEIGHTS_FILE   = "best.pt"          # File di root project ini
UPLOAD_FOLDER  = "yolov12_upload"   # Folder sementara untuk upload

# ──────────────────────────────────────────────
# CEK FILE best.pt
# ──────────────────────────────────────────────
script_dir = os.path.dirname(os.path.abspath(__file__))
weights_path = os.path.join(script_dir, WEIGHTS_FILE)

if not os.path.exists(weights_path):
    print(f"[ERROR] File '{WEIGHTS_FILE}' tidak ditemukan di: {script_dir}")
    print("        Pastikan best.pt ada di folder root project.")
    sys.exit(1)

print(f"[OK] File ditemukan: {weights_path}")
print(f"     Ukuran: {os.path.getsize(weights_path) / 1024 / 1024:.2f} MB")
print()

# ──────────────────────────────────────────────
# BUAT FOLDER UPLOAD & SALIN best.pt
# ──────────────────────────────────────────────
upload_dir = os.path.join(script_dir, UPLOAD_FOLDER)
os.makedirs(upload_dir, exist_ok=True)

dest_weights = os.path.join(upload_dir, "best.pt")
shutil.copy2(weights_path, dest_weights)
print(f"[OK] Salin best.pt ke: {upload_dir}")

# ──────────────────────────────────────────────
# CEK & INSTALL roboflow
# ──────────────────────────────────────────────
try:
    from roboflow import Roboflow
    print("[OK] Library roboflow sudah terinstall.")
except ImportError:
    print("[INFO] Library roboflow belum ada, menginstall...")
    os.system(f"{sys.executable} -m pip install roboflow")
    from roboflow import Roboflow
    print("[OK] Instalasi roboflow selesai.")

print()

# ──────────────────────────────────────────────
# UPLOAD MODEL KE ROBOFLOW
# ──────────────────────────────────────────────
print("=" * 55)
print(" UPLOAD YOLOv12 MODEL KE ROBOFLOW")
print("=" * 55)
print(f" Workspace : {WORKSPACE}")
print(f" Project   : {PROJECT}")
print(f" Version   : {VERSION}")
print(f" Model Type: {MODEL_TYPE}")
print(f" Weights   : {dest_weights}")
print("=" * 55)
print()

try:
    rf      = Roboflow(api_key=API_KEY)
    project = rf.workspace(WORKSPACE).project(PROJECT)
    version = project.version(VERSION)

    print("[INFO] Memulai upload... (bisa memakan waktu beberapa menit)")
    version.deploy(
        model_type=MODEL_TYPE,
        model_path=upload_dir,      # folder yang berisi best.pt
        filename="best.pt"
    )
    print()
    print("[SUCCESS] ✅ Model berhasil diupload ke Roboflow!")
    print(f"          Cek di: https://app.roboflow.com/{WORKSPACE}/{PROJECT}/models")

except Exception as e:
    print(f"[ERROR] Upload gagal: {e}")
    print()
    print("Kemungkinan penyebab:")
    print("  1. API key salah / kedaluwarsa")
    print("  2. Versi project tidak cocok (coba ganti VERSION = 2)")
    print("  3. Koneksi internet bermasalah")
    print("  4. Roboflow belum mendukung model type ini di workspace gratis")
    print()
    print("Coba alternatif — upload via website Roboflow:")
    print("  1. Buka https://app.roboflow.com/muhammad-aslam-s-workspace/jenis-hama-hlar6/models")
    print("  2. Klik 'Upload Model' / tombol panah atas")
    print("  3. Pilih tipe YOLOv12, lalu upload best.pt secara manual")

finally:
    # Bersihkan folder sementara
    if os.path.exists(upload_dir):
        shutil.rmtree(upload_dir)
        print(f"\n[OK] Folder sementara '{UPLOAD_FOLDER}' dihapus.")
