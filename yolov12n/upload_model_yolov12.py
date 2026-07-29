"""
upload_model_yolov12.py
=======================
Script untuk upload best.pt (YOLOv12) ke Roboflow
Project: jenis-hama-hlar6 (muhammad-aslam-s-workspace)

Cara pakai:
  1. Buka terminal / CMD di folder root project ini
  2. Jalankan: pip install roboflow
  3. Jalankan: python yolov12n/upload_model_yolov12.py
"""

import os
import shutil
import sys

# ──────────────────────────────────────────────
# KONFIGURASI
# ──────────────────────────────────────────────
API_KEY        = "nsRtr9srM0kLon24RWka"
WORKSPACE      = "muhammad-aslam-s-workspace"
PROJECT        = "jenis-hama-hlar6"
VERSION        = 1
MODEL_TYPE     = "yolov12"
WEIGHTS_FILE   = "best.pt"
UPLOAD_FOLDER  = "yolov12_upload"

# ──────────────────────────────────────────────
# CEK FILE best.pt
# ──────────────────────────────────────────────
script_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.abspath(os.path.join(script_dir, ".."))

weights_path = os.path.join(root_dir, WEIGHTS_FILE)
if not os.path.exists(weights_path):
    weights_path = os.path.join(script_dir, WEIGHTS_FILE)

if not os.path.exists(weights_path):
    print(f"[ERROR] File '{WEIGHTS_FILE}' tidak ditemukan.")
    sys.exit(1)

print(f"[OK] File ditemukan: {weights_path}")
print(f"     Ukuran: {os.path.getsize(weights_path) / 1024 / 1024:.2f} MB")

# ──────────────────────────────────────────────
# BUAT FOLDER UPLOAD & SALIN best.pt
# ──────────────────────────────────────────────
upload_dir = os.path.join(script_dir, UPLOAD_FOLDER)
os.makedirs(upload_dir, exist_ok=True)

dest_weights = os.path.join(upload_dir, "best.pt")
shutil.copy2(weights_path, dest_weights)

# ──────────────────────────────────────────────
# UPLOAD MODEL KE ROBOFLOW
# ──────────────────────────────────────────────
try:
    from roboflow import Roboflow
    rf      = Roboflow(api_key=API_KEY)
    project = rf.workspace(WORKSPACE).project(PROJECT)
    version = project.version(VERSION)

    print("[INFO] Memulai upload YOLOv12 model hama ke Roboflow...")
    version.deploy(
        model_type=MODEL_TYPE,
        model_path=upload_dir,
        filename="best.pt"
    )
    print("[SUCCESS] Model berhasil diupload ke Roboflow!")
    print(f"          https://app.roboflow.com/{WORKSPACE}/{PROJECT}/models")

except Exception as e:
    print(f"[ERROR] Upload gagal: {e}")

finally:
    if os.path.exists(upload_dir):
        shutil.rmtree(upload_dir, ignore_errors=True)
