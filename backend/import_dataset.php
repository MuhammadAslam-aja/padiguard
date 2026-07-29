<?php
// import_dataset.php - Import dataset gambar dari folder "Gambar Padi" ke database & uploads.
// Struktur Folder:
//   Gambar Padi/
//     Hama/
//       padi sehat/        -> label: Padi Sehat
//       penggerek batang/  -> label: Penggerek Batang
//       wareng/            -> label: Wereng Coklat
//     kematangan/
//       Matang/            -> label: Matang
//       Mentah/            -> label: Mentah
//       Setengah Matang/   -> label: Setengah Matang

require_once __DIR__ . '/connection.php';

ini_set('memory_limit', -1);
set_time_limit(0);

echo "===========================================\n";
echo "  PadiGuard - Import Dataset Gambar Padi\n";
echo "===========================================\n\n";

$sourceRoot = dirname(__DIR__) . '/Gambar Padi';
$uploadDir  = __DIR__ . '/uploads';

// Base URL sesuai endpoint API image
$baseUrl = 'http://localhost/KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI/backend/api/image?file=';

if (!is_dir($sourceRoot)) {
    die("ERROR: Folder 'Gambar Padi' tidak ditemukan di: $sourceRoot\n");
}

if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
    echo "Created uploads directory: $uploadDir\n";
}

// Mapping: [path relatif dari 'Gambar Padi'] => [label dataset]
$categoryMap = [
    'Hama/padi sehat'       => 'Padi Sehat',
    'Hama/penggerek batang' => 'Penggerek Batang',
    'Hama/wareng'           => 'Wereng Coklat',
    'Hama/rumput'           => 'Rumput/Gulma',
    'kematangan/Matang'     => 'Matang',
    'kematangan/Mentah'     => 'Mentah',
    'kematangan/Setengah Matang' => 'Setengah Matang',
    'kematangan/rumput'     => 'Rumput/Gulma',
];

$successCount = 0;
$skippedCount = 0;
$errorCount   = 0;

foreach ($categoryMap as $relativePath => $label) {
    $dirPath = $sourceRoot . '/' . $relativePath;

    if (!is_dir($dirPath)) {
        echo "WARNING: Folder tidak ditemukan, dilewati: $dirPath\n";
        continue;
    }

    echo "\n[Memproses] $relativePath  =>  Label: \"$label\"\n";
    echo str_repeat('-', 60) . "\n";

    $files = scandir($dirPath);
    $folderCount = 0;

    foreach ($files as $file) {
        if ($file === '.' || $file === '..') continue;

        $sourceFilePath = $dirPath . '/' . $file;
        if (is_dir($sourceFilePath)) continue;

        $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) continue;

        // Buat nama file bersih untuk disimpan di uploads/
        $cleanFilename = preg_replace('/[^a-zA-Z0-9_.-]/', '_', $file);
        $categorySlug  = strtolower(preg_replace('/[^a-zA-Z0-9]/', '_', $relativePath));
        $newFilename   = 'ds_' . $categorySlug . '_' . $cleanFilename;
        $targetFilePath = $uploadDir . '/' . $newFilename;
        $dbImageUrl    = $baseUrl . $newFilename;

        // Cek apakah sudah ada di database (berdasarkan filename)
        $stmtCheck = $pdo->prepare("SELECT COUNT(*) FROM `dataset` WHERE `imageUrl` LIKE ?");
        $stmtCheck->execute(['%' . $newFilename . '%']);
        if ($stmtCheck->fetchColumn() > 0) {
            echo "  [SKIP] Sudah ada: $file\n";
            $skippedCount++;
            continue;
        }

        // Salin file ke uploads/
        if (!copy($sourceFilePath, $targetFilePath)) {
            echo "  [ERROR] Gagal menyalin: $file\n";
            $errorCount++;
            continue;
        }

        // Hitung average hash untuk duplicate detection
        $hash = getAverageHash($targetFilePath);
        if (!$hash) {
            echo "  [WARNING] Gagal hash (format tidak didukung): $file - tetap diimpor tanpa hash\n";
        }

        // Masukkan ke database
        $id = 'ds_' . uniqid();
        try {
            $stmt = $pdo->prepare(
                "INSERT INTO `dataset` (`id`, `label`, `imageUrl`, `hash`) VALUES (?, ?, ?, ?)"
            );
            $stmt->execute([$id, $label, $dbImageUrl, $hash]);
            echo "  [OK] $file\n";
            $successCount++;
            $folderCount++;
        } catch (\Exception $e) {
            echo "  [DB ERROR] $file: " . $e->getMessage() . "\n";
            @unlink($targetFilePath);
            $errorCount++;
        }
    }

    echo "  => $folderCount gambar berhasil diimpor dari folder ini.\n";
}

echo "\n===========================================\n";
echo "  Import Selesai!\n";
echo "===========================================\n";
echo "  Berhasil diimpor : $successCount file\n";
echo "  Sudah ada (skip) : $skippedCount file\n";
echo "  Error            : $errorCount file\n";
echo "===========================================\n";
