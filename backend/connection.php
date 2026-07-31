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

    // Pastikan tabel password_resets ada (untuk fitur Lupa Password via OTP Email)
    // Dibungkus try-catch sendiri agar tidak merusak flow koneksi utama
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `password_resets` (
            `id` int NOT NULL AUTO_INCREMENT,
            `email` varchar(100) NOT NULL,
            `otp_token` varchar(10) NOT NULL,
            `expires_at` datetime NOT NULL,
            `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_email` (`email`),
            KEY `idx_otp` (`otp_token`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Hapus OTP yang sudah kadaluarsa (cleanup otomatis, abaikan jika gagal)
        @$pdo->exec("DELETE FROM `password_resets` WHERE `expires_at` < NOW()");
    } catch (\PDOException $migErr) {
        // Abaikan error migrasi password_resets — tidak kritis
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
    
    // Seed default users (Hanya 1 User: aslam@gmail.com)
    $defaultUsers = [
        [
            'id' => 'u_1',
            'name' => 'aslam',
            'email' => 'aslam@gmail.com',
            'password' => password_hash('petani123', PASSWORD_DEFAULT),
            'role' => 'petani',
            'avatar' => 'https://api.dicebear.com/7.x/adventurer/png?seed=aslam',
            'createdAt' => '2026-05-10 08:30:00'
        ]
    ];
    
    $stmt = $pdo->prepare("INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `avatar`, `createdAt`) VALUES (:id, :name, :email, :password, :role, :avatar, :createdAt)");
    foreach ($defaultUsers as $u) {
        $stmt->execute($u);
    }
}

// Sterilisasi Database: Kosongkan seluruh riwayat deteksi (0 deteksi) & sisakan 1 user (aslam@gmail.com)
try {
    // 1. Sterilkan / kosongkan tabel detections (0 deteksi)
    $pdo->exec("DELETE FROM `detections`");

    // 2. Sisakan tepat 1 akun user (aslam@gmail.com)
    $allUsers = $pdo->query("SELECT `id`, `email` FROM `users` ORDER BY `createdAt` DESC")->fetchAll();
    if (count($allUsers) > 0) {
        $keepUser = $allUsers[0];
        foreach ($allUsers as $u) {
            if ($u['email'] === 'aslam@gmail.com') {
                $keepUser = $u;
                break;
            }
        }
        $pdo->prepare("DELETE FROM `users` WHERE `id` != ?")->execute([$keepUser['id']]);
    }
} catch (\Exception $exSterile) {}

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
            $sqlLines = file($seedFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($sqlLines as $line) {
                $line = trim($line);
                if (!empty($line) && (strpos($line, 'INSERT') === 0 || strpos($line, 'CREATE') === 0)) {
                    try {
                        $pdo->exec($line);
                    } catch (\Exception $ex) {}
                }
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
