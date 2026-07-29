import os
import shutil
import subprocess

base_dir = r"c:\laragon\www\KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI"
build_web_dir = os.path.join(base_dir, "build", "web")
backend_dir = os.path.join(base_dir, "backend")

print("1. Running flutter build web --release...")
res = subprocess.run(["flutter", "build", "web", "--release"], cwd=base_dir, shell=True)
if res.returncode != 0:
    print("Build failed!")
    exit(1)

print("\n2. Copying compiled Flutter Web files from build/web into backend/...")
if not os.path.exists(build_web_dir):
    print("build/web does not exist!")
    exit(1)

# List of item names in build/web to copy into backend
for item in os.listdir(build_web_dir):
    src = os.path.join(build_web_dir, item)
    dest = os.path.join(backend_dir, item)
    
    # Don't overwrite PHP files or database uploads
    if item in ["index.php", "connection.php", "database.sql", "uploads", "dataset_samples", "request_log.txt", "import_dataset.php"]:
        continue
        
    if os.path.isdir(src):
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        print(f"Copied directory: {item}")
    else:
        shutil.copy2(src, dest)
        print(f"Copied file: {item}")

print("\n3. Synchronization complete! All updated Web frontend files are now inside backend/")
