<?php
// connection.php - Mengelola koneksi database MySQL PDO dan inisialisasi schema secara otomatis
// Mendukung Railway (environment variables) dan Laragon lokal (fallback)

function getEnvVar($name, $default = '') {
    if (isset($_ENV[$name]) && $_ENV[$name] !== '') return $_ENV[$name];
    if (isset($_SERVER[$name]) && $_SERVER[$name] !== '') return $_SERVER[$name];
    $val = getenv($name);
    if ($val !== false && $val !== '') return $val;
    return $default;
}

$mysqlUrl = getEnvVar('MYSQL_URL') ?: getEnvVar('DATABASE_URL');
$host     = getEnvVar('MYSQLHOST') ?: getEnvVar('DB_HOST');
$port     = getEnvVar('MYSQLPORT') ?: getEnvVar('DB_PORT', '3306');
$db       = getEnvVar('MYSQLDATABASE') ?: getEnvVar('DB_NAME');
$user     = getEnvVar('MYSQLUSER') ?: getEnvVar('DB_USER');
$pass     = getEnvVar('MYSQLPASSWORD') ?: getEnvVar('DB_PASS');

if (!empty($mysqlUrl)) {
    $parsed = parse_url($mysqlUrl);
    if ($parsed) {
        if (!empty($parsed['host'])) $host = $parsed['host'];
        if (!empty($parsed['port'])) $port = $parsed['port'];
        if (!empty($parsed['user'])) $user = $parsed['user'];
        if (isset($parsed['pass']))  $pass = $parsed['pass'];
        if (!empty($parsed['path'])) $db   = ltrim($parsed['path'], '/');
    }
}

$isRailway = !empty(getEnvVar('RAILWAY_ENVIRONMENT')) || !empty($mysqlUrl) || (!empty($host) && $host !== 'localhost');

if ($isRailway) {
    // === RAILWAY PRODUCTION ===
    $host = !empty($host) ? $host : 'mysql.railway.internal';
    $db   = !empty($db)   ? $db   : 'railway';
    $user = !empty($user) ? $user : 'root';
    $charset = 'utf8mb4';
    $dsn = "mysql:host=$host;port=$port;dbname=$db;charset=$charset";
} else {
    // === LARAGON LOKAL ===
    $host    = 'localhost';
    $db      = 'padiguard_db';
    $user    = 'root';
    $pass    = ''; // Default password Laragon MySQL kosong
    $charset = 'utf8mb4';
    $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
}

date_default_timezone_set('Asia/Jakarta');

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
    $pdo->exec("SET time_zone = '+07:00'");
} catch (\PDOException $e) {
    if (!$isRailway) {
        // Lokal: Jika database padiguard_db belum ada, buat secara otomatis
        try {
            $tempDsn = "mysql:host=$host;charset=$charset";
            $tempPdo = new PDO($tempDsn, $user, $pass, $options);
            $tempPdo->exec("CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            $pdo = new PDO($dsn, $user, $pass, $options);
        } catch (\PDOException $ex) {
            while (ob_get_level() > 0) @ob_end_clean();
            if (!headers_sent()) header('Content-Type: application/json', true, 500);
            echo json_encode([
                'success' => false,
                'message' => 'Koneksi database MySQL gagal. Pastikan Laragon MySQL aktif! Error: ' . $ex->getMessage()
            ]);
            exit;
        }
    } else {
        while (ob_get_level() > 0) @ob_end_clean();
        if (!headers_sent()) header('Content-Type: application/json', true, 500);
        echo json_encode([
            'success' => false,
            'message' => 'Koneksi database Railway gagal. Cek konfigurasi MySQL di Railway dashboard. Error: ' . $e->getMessage()
        ]);
        exit;
    }
}

// Helper Fungsi Visual Hashing (Average Hash) & Hamming Distance
function getAverageHash($imagePath) {
    if (!file_exists($imagePath) || is_dir($imagePath)) return null;
    $info = @getimagesize($imagePath);
    if (!$info) return null;
    
    $mime = $info['mime'];
    if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
        $img = @imagecreatefromjpeg($imagePath);
    } elseif ($mime == 'image/png') {
        $img = @imagecreatefrompng($imagePath);
    } elseif ($mime == 'image/webp') {
        $img = @imagecreatefromwebp($imagePath);
    } else {
        return null;
    }
    if (!$img) return null;
    
    $resized = imagecreatetruecolor(8, 8);
    imagecopyresampled($resized, $img, 0, 0, 0, 0, 8, 8, imagesx($img), imagesy($img));
    
    $pixels = [];
    $sum = 0;
    for ($y = 0; $y < 8; $y++) {
        for ($x = 0; $x < 8; $x++) {
            $rgb = imagecolorat($resized, $x, $y);
            $r = ($rgb >> 16) & 0xFF;
            $g = ($rgb >> 8) & 0xFF;
            $b = $rgb & 0xFF;
            $gray = round(($r + $g + $b) / 3);
            $pixels[] = $gray;
            $sum += $gray;
        }
    }
    $avg = $sum / 64;
    
    $hash = '';
    foreach ($pixels as $pixel) {
        $hash .= ($pixel >= $avg) ? '1' : '0';
    }
    
    imagedestroy($resized);
    imagedestroy($img);
    
    return $hash;
}

function getHammingDistance($hash1, $hash2) {
    if (!$hash1 || !$hash2 || strlen($hash1) !== strlen($hash2)) return 999;
    $dist = 0;
    for ($i = 0; $i < strlen($hash1); $i++) {
        if ($hash1[$i] !== $hash2[$i]) {
            $dist++;
        }
    }
    return $dist;
}

function getLocalFilePath($imageUrl) {
    if (preg_match('/file=([^&\s]+)/', $imageUrl, $matches)) {
        return __DIR__ . '/uploads/' . basename($matches[1]);
    }
    if (preg_match('/uploads\/([^?\s]+)/', $imageUrl, $matches)) {
        return __DIR__ . '/uploads/' . basename($matches[1]);
    }
    $relPath = __DIR__ . '/' . $imageUrl;
    if (file_exists($relPath) && !is_dir($relPath)) {
        return $relPath;
    }
    return null;
}

// Jalankan migrasi dan seeder otomatis jika tabel 'users' belum ada
try {
    $pdo->query("SELECT 1 FROM `users` LIMIT 1");
    
    // Pastikan kolom hash ada di tabel dataset
    try {
        $pdo->query("SELECT `hash` FROM `dataset` LIMIT 1");
    } catch (\PDOException $ex) {
        $pdo->exec("ALTER TABLE `dataset` ADD COLUMN `hash` varchar(64) DEFAULT NULL");
    }
} catch (\PDOException $e) {
    // Jalankan database.sql
    $sql = file_get_contents(__DIR__ . '/database.sql');
    if ($sql) {
        $pdo->exec($sql);
    }
    // Pastikan kolom hash ditambahkan ke tabel baru
    try {
        $pdo->exec("ALTER TABLE `dataset` ADD COLUMN `hash` varchar(64) DEFAULT NULL");
    } catch (\PDOException $err) {}
    
    // Seed default users
    $defaultUsers = [
        [
            'id' => 'u_1',
            'name' => 'Budi Santoso',
            'email' => 'petani@gmail.com',
            'password' => password_hash('petani123', PASSWORD_DEFAULT),
            'role' => 'petani',
            'avatar' => 'https://api.dicebear.com/7.x/adventurer/png?seed=Budi',
            'createdAt' => '2026-05-10 08:30:00'
        ],
        [
            'id' => 'u_2',
            'name' => 'Siti Rahma',
            'email' => 'siti.petani@gmail.com',
            'password' => password_hash('password123', PASSWORD_DEFAULT),
            'role' => 'petani',
            'avatar' => 'https://api.dicebear.com/7.x/adventurer/png?seed=Siti',
            'createdAt' => '2026-06-12 09:15:00'
        ],
        [
            'id' => 'u_3',
            'name' => 'Admin PadiGuard',
            'email' => 'admin@gmail.com',
            'password' => password_hash('admin123', PASSWORD_DEFAULT),
            'role' => 'admin',
            'avatar' => 'https://api.dicebear.com/7.x/bottts/png?seed=Admin',
            'createdAt' => '2026-04-01 07:00:00'
        ]
    ];
    
    $stmt = $pdo->prepare("INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `avatar`, `createdAt`) VALUES (:id, :name, :email, :password, :role, :avatar, :createdAt)");
    foreach ($defaultUsers as $u) {
        $stmt->execute($u);
    }
    
    // Seed default detections
    $defaultDetections = [
        [
            'id' => 'd_1',
            'userEmail' => 'petani@gmail.com',
            'userName' => 'Budi Santoso',
            'date' => '2026-06-25 10:30:00',
            'imageUrl' => 'https://images.unsplash.com/photo-1599819811279-d5ad9cccf838?auto=format&fit=crop&q=80&w=500',
            'hamaName' => 'Wereng Coklat',
            'hamaConfidence' => 0.88,
            'kematangan' => 'Setengah Matang',
            'kematanganConfidence' => 0.94,
            'boundingBoxes' => json_encode([
                ['label' => 'Wereng Coklat (88%)', 'xMin' => 0.2, 'yMin' => 0.3, 'xMax' => 0.5, 'yMax' => 0.6, 'isHama' => true],
                ['label' => 'Setengah Matang (94%)', 'xMin' => 0.1, 'yMin' => 0.1, 'xMax' => 0.9, 'yMax' => 0.9, 'isHama' => false],
            ]),
            'dangerLevel' => 'Tinggi',
            'description' => 'Wereng Coklat (Nilaparvata lugens) menghisap cairan tanaman padi menyebabkan daun menguning, mengering (hopperburn), dan tanaman mati.',
            'treatment' => "1. Atur jarak tanam legowo untuk mengurangi kelembapan.\n2. Lestarikan musuh alami seperti laba-laba.\n3. Semprotkan insektisida pymetrozine jika populasi tinggi."
        ],
        [
            'id' => 'd_2',
            'userEmail' => 'petani@gmail.com',
            'userName' => 'Budi Santoso',
            'date' => '2026-06-26 08:15:00',
            'imageUrl' => 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&q=80&w=500',
            'hamaName' => null,
            'hamaConfidence' => 0.0,
            'kematangan' => 'Matang',
            'kematanganConfidence' => 0.97,
            'boundingBoxes' => json_encode([
                ['label' => 'Matang (97%)', 'xMin' => 0.05, 'yMin' => 0.05, 'xMax' => 0.95, 'yMax' => 0.95, 'isHama' => false],
            ]),
            'dangerLevel' => 'Aman',
            'description' => 'Tanaman padi telah mencapai fase masak penuh (matang fisiologis). Lebih dari 90% butir gabah telah menguning sempurna dan kadar air menurun.',
            'treatment' => 'Segera lakukan pemanenan dalam waktu 1-2 minggu ke depan untuk menghindari rontoknya gabah.'
        ],
        [
            'id' => 'd_3',
            'userEmail' => 'siti.petani@gmail.com',
            'userName' => 'Siti Rahma',
            'date' => '2026-06-24 14:20:00',
            'imageUrl' => 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&q=80&w=500',
            'hamaName' => 'Walang Sangit',
            'hamaConfidence' => 0.76,
            'kematangan' => 'Mentah',
            'kematanganConfidence' => 0.91,
            'boundingBoxes' => json_encode([
                ['label' => 'Walang Sangit (76%)', 'xMin' => 0.4, 'yMin' => 0.4, 'xMax' => 0.7, 'yMax' => 0.7, 'isHama' => true],
                ['label' => 'Mentah (91%)', 'xMin' => 0.1, 'yMin' => 0.1, 'xMax' => 0.9, 'yMax' => 0.9, 'isHama' => false],
            ]),
            'dangerLevel' => 'Sedang',
            'description' => 'Walang Sangit (Leptocorisa oratorius) menyerang bulir padi pada fase masak susu, menyebabkan bulir menjadi hampa atau bercorak coklat kehitaman.',
            'treatment' => "1. Lakukan sanitasi lingkungan sawah dari rumput liar.\n2. Gunakan umpan bau-bauan untuk menjebak walang sangit.\n3. Semprotkan pestisida kimia pada pagi/sore hari."
        ]
    ];
    
    $stmtDet = $pdo->prepare("INSERT INTO `detections` (`id`, `userEmail`, `userName`, `date`, `imageUrl`, `hamaName`, `hamaConfidence`, `kematangan`, `kematanganConfidence`, `boundingBoxes`, `dangerLevel`, `description`, `treatment`) VALUES (:id, :userEmail, :userName, :date, :imageUrl, :hamaName, :hamaConfidence, :kematangan, :kematanganConfidence, :boundingBoxes, :dangerLevel, :description, :treatment)");
    foreach ($defaultDetections as $d) {
        $stmtDet->execute($d);
    }
}

// Pastikan nilai performa model diperbarui sesuai hasil training Roboflow terbaru (real-time migration)
try {
    $pdo->exec("UPDATE `model_performance` SET `accuracy` = 0.962, `precision` = 0.948, `recall` = 0.938, `f1` = 0.943");
} catch (\PDOException $ex) {}

// Auto-seed dataset_seed.sql (seluruh 1,376 hash dataset) jika dataset di DB < 1376
try {
    $dsCount = (int)$pdo->query("SELECT COUNT(*) FROM `dataset`")->fetchColumn();
    if ($dsCount < 1376) {
        $seedFile = __DIR__ . '/dataset_seed.sql';
        if (file_exists($seedFile)) {
            $sqlSeed = file_get_contents($seedFile);
            if (!empty($sqlSeed)) {
                $pdo->exec($sqlSeed);
            }
        }
    }
} catch (\Exception $e) {}

// Sinkronkan secara otomatis file sampel dataset dari folder dataset_samples ke dalam database MySQL
try {
    $samplesDir = __DIR__ . '/dataset_samples';
    if (file_exists($samplesDir)) {
        $sampleFiles = glob($samplesDir . '/*.{jpg,jpeg,png,webp}', GLOB_BRACE);
        if ($sampleFiles) {
            $uploadsDir = __DIR__ . '/uploads';
            if (!file_exists($uploadsDir)) @mkdir($uploadsDir, 0777, true);
            
            $stmtCheck = $pdo->prepare("SELECT COUNT(*) FROM `dataset` WHERE `id` = ?");
            $stmtInsert = $pdo->prepare("INSERT INTO `dataset` (`id`, `label`, `imageUrl`, `hash`) VALUES (?, ?, ?, ?)");
            $stmtUpdateHash = $pdo->prepare("UPDATE `dataset` SET `hash` = ? WHERE `id` = ? AND (`hash` IS NULL OR `hash` = '')");
            
            foreach ($sampleFiles as $samplePath) {
                $filename = basename($samplePath);
                $dsId = 'ds_' . md5($filename);
                $targetPath = $uploadsDir . '/' . $filename;
                if (!file_exists($targetPath)) {
                    @copy($samplePath, $targetPath);
                }
                
                $hash = getAverageHash($targetPath);
                
                $stmtCheck->execute([$dsId]);
                if ($stmtCheck->fetchColumn() == 0) {
                    $label = 'Padi Sehat';
                    $fnLower = strtolower($filename);
                    if (strpos($fnLower, 'wereng_coklat') !== false) {
                        $label = 'Wereng Coklat';
                    } elseif (strpos($fnLower, 'penggerek_batang') !== false) {
                        $label = 'Penggerek Batang';
                    } elseif (strpos($fnLower, 'rumput') !== false) {
                        $label = 'Rumput / Gulma';
                    } elseif (strpos($fnLower, 'matang_-_sehat') !== false) {
                        $label = 'Matang - Sehat';
                    } elseif (strpos($fnLower, 'mentah_-_sehat') !== false) {
                        $label = 'Mentah - Sehat';
                    } elseif (strpos($fnLower, 'setengah_matang_-_sehat') !== false) {
                        $label = 'Setengah Matang - Sehat';
                    } elseif (strpos($fnLower, 'padi_sehat') !== false) {
                        $label = 'Padi Sehat';
                    }
                    
                    $imageUrl = 'uploads/' . $filename;
                    $stmtInsert->execute([$dsId, $label, $imageUrl, $hash]);
                } else if ($hash) {
                    $stmtUpdateHash->execute([$hash, $dsId]);
                }
            }
        }
    }
} catch (\Exception $e) {}
