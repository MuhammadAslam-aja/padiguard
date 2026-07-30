import os
import shutil
from PIL import Image

base_dir = r"c:\laragon\www\KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI"
source_gambar_padi = os.path.join(base_dir, "Gambar Padi")
target_dir = os.path.join(base_dir, "backend", "dataset_samples")

# Reset / re-create target directory
if os.path.exists(target_dir):
    shutil.rmtree(target_dir)
os.makedirs(target_dir, exist_ok=True)

categories = [
    ("Hama/padi sehat", "Padi Sehat"),
    ("Hama/penggerek batang", "Penggerek Batang"),
    ("Hama/wareng", "Wereng Coklat"),
    ("Hama/rumput", "Rumput / Gulma"),
    ("kematangan/Matang", "Matang - Sehat"),
    ("kematangan/Mentah", "Mentah - Sehat"),
    ("kematangan/Setengah Matang", "Setengah Matang - Sehat"),
]

count = 0
processed_hashes = set()

for rel_path, label in categories:
    folder_path = os.path.join(source_gambar_padi, rel_path)
    if not os.path.exists(folder_path):
        print(f"Skipping non-existent: {folder_path}")
        continue
    
    files = [f for f in os.listdir(folder_path) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))]
    print(f"Processing {len(files)} images for {label}...")
    
    for idx, fname in enumerate(files):
        src_file = os.path.join(folder_path, fname)
        safe_label = label.replace(" ", "_").replace("/", "_").lower()
        new_name = f"sample_{safe_label}_{idx+1}.jpg"
        dest_file = os.path.join(target_dir, new_name)
        
        try:
            with Image.open(src_file) as img:
                img.thumbnail((600, 600))
                img.convert("RGB").save(dest_file, "JPEG", quality=80, optimize=True)
                count += 1
        except Exception as e:
            print(f"Error processing {src_file}: {e}")

print(f"\nSuccess! Converted ALL {count} dataset images from 'Gambar Padi' into {target_dir}")
