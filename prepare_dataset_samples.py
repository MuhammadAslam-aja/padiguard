import os
import shutil
from PIL import Image

base_dir = r"c:\laragon\www\KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI"
source_gambar_padi = os.path.join(base_dir, "Gambar Padi")
target_dir = os.path.join(base_dir, "backend", "dataset_samples")

os.makedirs(target_dir, exist_ok=True)

categories = [
    ("Hama/padi sehat", "Padi Sehat", 8),
    ("Hama/penggerek batang", "Penggerek Batang", 8),
    ("Hama/wareng", "Wereng Coklat", 8),
    ("Hama/rumput", "Rumput / Gulma", 10),
    ("kematangan/Matang", "Matang - Sehat", 8),
    ("kematangan/Mentah", "Mentah - Sehat", 8),
    ("kematangan/Setengah Matang", "Setengah Matang - Sehat", 8),
]

count = 0
for rel_path, label, max_count in categories:
    folder_path = os.path.join(source_gambar_padi, rel_path)
    if not os.path.exists(folder_path):
        print(f"Skipping non-existent: {folder_path}")
        continue
    
    files = [f for f in os.listdir(folder_path) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))]
    selected_files = files[:max_count]
    
    for idx, fname in enumerate(selected_files):
        src_file = os.path.join(folder_path, fname)
        safe_label = label.replace(" ", "_").replace("/", "_").lower()
        new_name = f"sample_{safe_label}_{idx+1}.jpg"
        dest_file = os.path.join(target_dir, new_name)
        
        try:
            with Image.open(src_file) as img:
                img.thumbnail((800, 800))
                img.convert("RGB").save(dest_file, "JPEG", quality=85)
                count += 1
                print(f"Saved: {new_name} ({label})")
        except Exception as e:
            print(f"Error processing {src_file}: {e}")

print(f"\nDone! Processed {count} sample images into {target_dir}")
