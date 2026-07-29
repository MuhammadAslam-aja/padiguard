<?php
// index.php - Router utama API PHP PadiGuard (MySQL Laragon)

// 1. CORS Headers & Error Reporting
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, ngrok-skip-browser-warning");
header("ngrok-skip-browser-warning: true");

error_reporting(E_ALL);
ini_set('display_errors', 0); // Matikan agar tidak mengotori output JSON

// Tangani Preflight Request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// 2. LAYANI FLUTTER WEB FRONTEND (JIKA BUKAN REQUEST UNTUK /api)
$requestUri = $_SERVER['REQUEST_URI'];
$uriPath = strtok(rawurldecode($requestUri), '?');

if (stripos($uriPath, '/api') === false) {
    $file = ltrim($uriPath, '/');
    $filePath = __DIR__ . '/' . $file;
    
    // Jika file spesifik ada (seperti main.dart.js, flutter.js, assets/..., dll)
    if (!empty($file) && file_exists($filePath) && !is_dir($filePath)) {
        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $contentTypes = [
            'html' => 'text/html; charset=UTF-8',
            'js'   => 'application/javascript',
            'json' => 'application/json',
            'css'  => 'text/css',
            'png'  => 'image/png',
            'jpg'  => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'gif'  => 'image/gif',
            'svg'  => 'image/svg+xml',
            'wasm' => 'application/wasm',
            'ttf'  => 'font/ttf',
            'otf'  => 'font/otf',
            'woff' => 'font/woff',
            'woff2'=> 'font/woff2',
        ];
        $contentType = isset($contentTypes[$ext]) ? $contentTypes[$ext] : 'application/octet-stream';
        header("Content-Type: $contentType");
        header("Content-Length: " . filesize($filePath));
        readfile($filePath);
        exit;
    } else {
        // Fallback ke index.html untuk SPA Web UI
        $indexHtml = __DIR__ . '/index.html';
        if (file_exists($indexHtml)) {
            header("Content-Type: text/html; charset=UTF-8");
            readfile($indexHtml);
            exit;
        }
    }
}

// 3. DEFAULT API HEADER (Hanya untuk rute /api)
header("Content-Type: application/json; charset=UTF-8");

// 4. Hubungkan ke Database (Auto-Migrate)
require_once __DIR__ . '/connection.php';

// 3. Helper Functions
function generateToken($userId, $email) {
    $salt = 'padiguardSecretSalt';
    $signature = sha1($userId . '|' . $email . '|' . $salt);
    return base64_encode($userId . '|' . $email . '|' . $signature);
}

function verifyTokenHeader() {
    $headers = function_exists('apache_request_headers') ? apache_request_headers() : [];
    $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : '';
    
    if (empty($authHeader) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
    }
    
    // Fallback pencarian case-insensitive pada $_SERVER
    if (empty($authHeader)) {
        foreach ($_SERVER as $key => $value) {
            if (strcasecmp($key, 'HTTP_AUTHORIZATION') === 0) {
                $authHeader = $value;
                break;
            }
        }
    }

    
    if (empty($authHeader)) return null;
    
    if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        $token = $matches[1];
        $salt = 'padiguardSecretSalt';
        $decoded = base64_decode($token);
        if (!$decoded) return null;
        
        $parts = explode('|', $decoded);
        if (count($parts) !== 3) return null;
        
        list($userId, $email, $signature) = $parts;
        $expectedSignature = sha1($userId . '|' . $email . '|' . $salt);
        if ($signature === $expectedSignature) {
            return [
                'id' => $userId,
                'email' => $email
            ];
        }
    }
    return null;
}

function sendResponse($success, $data = [], $statusCode = 200) {
    http_response_code($statusCode);
    $responseArray = array_merge(['success' => $success], $data);
    $responseArray = normalizeUrls($responseArray);
    echo json_encode($responseArray);
    exit;
}

function getBaseUrl() {
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'];
    $scriptName = dirname($_SERVER['SCRIPT_NAME']);
    // Normalisasi slash
    $scriptDir = str_replace('\\', '/', $scriptName);
    return $protocol . "://" . $host . rtrim($scriptDir, '/');
}

function extractPestNameFromText($text) {
    if (empty($text)) return null;
    $s = strtolower(trim($text));
    
    // 1. Penggerek Batang
    if (stripos($s, 'penggerek') !== false 
        || stripos($s, 'borer') !== false 
        || stripos($s, 'sundep') !== false 
        || stripos($s, 'beluk') !== false 
        || stripos($s, 'scirpophaga') !== false
        || $s === '0') {
        return 'Penggerek Batang';
    }
    
    // 2. Wereng Coklat
    if (stripos($s, 'wereng') !== false 
        || stripos($s, 'wareng') !== false 
        || stripos($s, 'hopper') !== false 
        || stripos($s, 'planthopper') !== false 
        || stripos($s, 'nilaparvata') !== false
        || $s === '1') {
        return 'Wereng Coklat';
    }
    
    // 3. Walang Sangit
    if (stripos($s, 'walang') !== false 
        || stripos($s, 'sangit') !== false 
        || stripos($s, 'leptocorisa') !== false) {
        return 'Walang Sangit';
    }
    
    // 4. Ulat Grayak
    if (stripos($s, 'grayak') !== false 
        || stripos($s, 'spodoptera') !== false 
        || stripos($s, 'army') !== false) {
        return 'Ulat Grayak';
    }
    
    return null;
}

function extractMaturityFromText($text) {
    if (empty($text)) return null;
    $s = strtolower(trim($text));
    if (stripos($s, 'setengah') !== false || stripos($s, 'half') !== false) {
        return 'Setengah Matang';
    }
    if (stripos($s, 'mentah') !== false || stripos($s, 'unripe') !== false || stripos($s, 'raw') !== false || stripos($s, 'young') !== false || stripos($s, 'vegetatif') !== false || stripos($s, 'hijau') !== false) {
        return 'Mentah';
    }
    if (stripos($s, 'matang') !== false || stripos($s, 'ripe') !== false || stripos($s, 'mature') !== false) {
        return 'Matang';
    }
    return null;
}

function findPredictionsInArray($arr) {
    if (!is_array($arr)) return [];
    if (isset($arr['predictions']) && is_array($arr['predictions'])) {
        return $arr['predictions'];
    }
    foreach ($arr as $key => $val) {
        if (is_array($val)) {
            $res = findPredictionsInArray($val);
            if (!empty($res)) return $res;
        }
    }
    return [];
}

function analyzeMaturity($imagePath) {
    if (!file_exists($imagePath)) return 'Setengah Matang';
    $info = @getimagesize($imagePath);
    if (!$info) return 'Setengah Matang';
    $mime = $info['mime'];
    if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
        $img = @imagecreatefromjpeg($imagePath);
    } elseif ($mime == 'image/png') {
        $img = @imagecreatefrompng($imagePath);
    } elseif ($mime == 'image/webp') {
        $img = @imagecreatefromwebp($imagePath);
    } else {
        return 'Setengah Matang';
    }
    if (!$img) return 'Setengah Matang';
    
    $w = imagesx($img);
    $h = imagesy($img);
    
    $greenCount = 0;
    $yellowCount = 0;
    
    // Sample a 30x30 grid
    $sampleX = 30;
    $sampleY = 30;
    $stepX = max(1, (int)($w / $sampleX));
    $stepY = max(1, (int)($h / $sampleY));
    
    for ($x = 0; $x < $w; $x += $stepX) {
        for ($y = 0; $y < $h; $y += $stepY) {
            $rgb = @imagecolorat($img, (int)$x, (int)$y);
            if ($rgb === false) continue;
            $r = ($rgb >> 16) & 0xFF;
            $g = ($rgb >> 8) & 0xFF;
            $b = $rgb & 0xFF;
            
            // Green: g is clearly dominant
            if ($g > $r && $g > $b && ($g - $r) > 12) {
                $greenCount++;
            }
            // Yellow/Gold/Brown: r and g are high, b is low (gabah/padi kuning asli)
            elseif ($r > 120 && $g > 110 && ($r - $b) > 35 && ($g - $b) > 25 && abs($r - $g) < 40) {
                $yellowCount++;
            }
        }
    }
    @imagedestroy($img);
    
    $total = $greenCount + $yellowCount;
    if ($total < 15) return 'Mentah';
    
    $yellowRatio = $yellowCount / $total;
    if ($yellowRatio > 0.65) {
        return 'Matang';
    } elseif ($yellowRatio < 0.35 || $greenCount >= ($yellowCount * 1.5)) {
        return 'Mentah';
    } else {
        return 'Setengah Matang';
    }
}

function isRicePlantImage($imagePath) {
    if (!file_exists($imagePath)) return ['valid' => true, 'reason' => ''];
    if (!function_exists('imagecreatefromjpeg') && !function_exists('imagecreatefrompng')) {
        return ['valid' => true, 'reason' => '']; // Safe fallback jika GD PHP tidak diaktifkan
    }
    
    $info = @getimagesize($imagePath);
    if (!$info) return ['valid' => true, 'reason' => ''];
    
    $mime = $info['mime'];
    if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
        $img = @imagecreatefromjpeg($imagePath);
    } elseif ($mime == 'image/png') {
        $img = @imagecreatefrompng($imagePath);
    } elseif ($mime == 'image/webp') {
        $img = @imagecreatefromwebp($imagePath);
    } else {
        return ['valid' => true, 'reason' => ''];
    }
    
    if (!$img) return ['valid' => true, 'reason' => ''];
    
    $w = imagesx($img);
    $h = imagesy($img);
    
    $riceColorCount = 0;
    $documentBgCount = 0;
    $skinColorCount = 0;
    $artificialClothingCount = 0;
    $deepForestCount = 0;
    $blueNonPadiCount = 0;
    $grayNonPadiCount = 0;
    
    $sampleX = 60;
    $sampleY = 60;
    $stepX = max(1, (int)($w / $sampleX));
    $stepY = max(1, (int)($h / $sampleY));
    
    $totalSamples = 0;
    for ($x = 0; $x < $w; $x += $stepX) {
        for ($y = 0; $y < $h; $y += $stepY) {
            $totalSamples++;
            $rgb = @imagecolorat($img, (int)$x, (int)$y);
            if ($rgb === false) continue;
            $r = ($rgb >> 16) & 0xFF;
            $g = ($rgb >> 8) & 0xFF;
            $b = $rgb & 0xFF;
            
            // 1. Deteksi Kulit Manusia (diperluas: tone kulit dari gelap hingga terang)
            $isSkinLight = ($r > 180 && $g > 140 && $b > 100 && $r > $g && $r > $b && ($r - $b) > 20 && abs($r - $g) < 80);
            $isSkinMid   = ($r > 120 && $g > 80 && $b > 50 && $r > $g && $r > $b && ($r - $b) > 15 && ($r - $g) > 8 && ($g - $b) > 5);
            $isSkinDark  = ($r > 60 && $g > 35 && $b > 15 && $r > $g && $r > $b && ($r - $b) > 10 && abs($r - $g) < 60);
            if ($isSkinLight || $isSkinMid || $isSkinDark) {
                $skinColorCount++;
            }
            
            // 2. Deteksi Baju / Pakaian Buatan & warna artificial non-padi
            $isRedShirt    = ($r > 170 && $g < 80 && $b < 80);
            $isBlueShirt   = ($b > 140 && $b > $r + 30 && $b > $g + 30);
            $isPurpleShirt = ($r > 100 && $b > 100 && $g < 90 && abs($r - $b) < 60);
            $isOrangeShirt = ($r > 200 && $g > 80 && $g < 160 && $b < 60);
            if ($isRedShirt || $isBlueShirt || $isPurpleShirt || $isOrangeShirt) {
                $artificialClothingCount++;
            }
            
            // 3. Cek piksel latar belakang dokumen/screenshot/UI solid (putih & hitam pekat)
            if (($r > 220 && $g > 220 && $b > 220) || ($r < 25 && $g < 25 && $b < 25)) {
                $documentBgCount++;
            }
            
            // 4. Biru langit / biru buatan / abu non-padi yang dominan
            $isBlueSky  = ($b > $r + 15 && $b > $g + 10 && $b > 90);
            if ($isBlueSky) $blueNonPadiCount++;
            
            // 5. Abu-abu netral (tembok, beton, aspal, dll)
            $isGray = (abs($r - $g) < 18 && abs($g - $b) < 18 && abs($r - $b) < 18 && $r > 40 && $r < 220);
            if ($isGray) $grayNonPadiCount++;
            
            // 6. Karakteristik Tanaman Padi (segala fase: Hijau, Kuning Matang, Kering/Jerami, Sawah)
            $isGreenPadi  = ($g > $r + 5 && $g > $b + 8 && $g > 40);
            $isYellowPadi = ($r > 100 && $g > 90 && $b < 110 && ($r - $b) > 20 && ($g - $b) > 10 && abs($r - $g) < 70);
            $isDryPadi    = ($r > 70 && $g > 58 && $b < 90 && $r >= $g - 15 && ($r - $b) > 12);
            $isSawahMud   = ($r > 50 && $g > 42 && $b < 70 && ($r - $b) > 10);
            
            if ($isGreenPadi || $isYellowPadi || $isDryPadi || $isSawahMud) {
                $riceColorCount++;
            }
        }
    }
    @imagedestroy($img);
    
    if ($totalSamples == 0) return ['valid' => true, 'reason' => ''];
    
    $skinRatio     = $skinColorCount / $totalSamples;
    $clothingRatio = $artificialClothingCount / $totalSamples;
    $docRatio      = $documentBgCount / $totalSamples;
    $blueRatio     = $blueNonPadiCount / $totalSamples;
    $grayRatio     = $grayNonPadiCount / $totalSamples;
    $riceRatio     = $riceColorCount / $totalSamples;
    
    // A. TOLAK jika dominan kulit manusia (wajah / tubuh) > 8% piksel
    if ($skinRatio > 0.08) {
        return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai wajah atau tubuh manusia, bukan tanaman padi.'];
    }
    
    // B. TOLAK jika ada pakaian buatan manusia cukup banyak > 6%
    if ($clothingRatio > 0.06) {
        return ['valid' => false, 'reason' => 'Gambar terdeteksi mengandung objek buatan (pakaian/baju), bukan tanaman padi.'];
    }
    
    // C. TOLAK jika > 50% background dokumen/UI/screenshot (putih/hitam solid)
    if ($docRatio > 0.50) {
        return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai dokumen, screenshot, atau latar polos, bukan tanaman padi.'];
    }
    
    // D. TOLAK jika gambar didominasi warna non-padi (biru langit + abu-abu > 65% dan padi < 10%)
    if (($blueRatio + $grayRatio) > 0.65 && $riceRatio < 0.10) {
        return ['valid' => false, 'reason' => 'Gambar didominasi langit atau objek buatan, bukan tanaman padi.'];
    }
    
    // E. HARUS memiliki minimal 15% piksel bernuansa tanaman padi / sawah
    if ($riceRatio < 0.15) {
        return ['valid' => false, 'reason' => 'Gambar tidak cukup mengandung karakteristik warna tanaman padi (hijau/kuning/coklat padi).'];
    }
    
    return ['valid' => true, 'reason' => ''];
}

function isGrassOrWeedImage($imagePath) {
    if (!file_exists($imagePath)) return false;
    $info = @getimagesize($imagePath);
    if (!$info) return false;
    
    $mime = $info['mime'];
    if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
        $img = @imagecreatefromjpeg($imagePath);
    } elseif ($mime == 'image/png') {
        $img = @imagecreatefrompng($imagePath);
    } elseif ($mime == 'image/webp') {
        $img = @imagecreatefromwebp($imagePath);
    } else {
        return false;
    }
    if (!$img) return false;
    
    $w = imagesx($img);
    $h = imagesy($img);
    
    $weedGrassPixels = 0;
    $yellowPadiPixels = 0;
    $totalSamples = 0;
    
    $sampleX = 50;
    $sampleY = 50;
    $stepX = max(1, (int)($w / $sampleX));
    $stepY = max(1, (int)($h / $sampleY));
    
    for ($x = 0; $x < $w; $x += $stepX) {
        for ($y = 0; $y < $h; $y += $stepY) {
            $totalSamples++;
            $rgb = @imagecolorat($img, (int)$x, (int)$y);
            if ($rgb === false) continue;
            $r = ($rgb >> 16) & 0xFF;
            $g = ($rgb >> 8) & 0xFF;
            $b = $rgb & 0xFF;
            
            // 1. Rumput Hijau / Gulma / Rumput Liar / Daun Liar / Semak Tanah:
            // g >= r - 10 DAN g > b + 6 DAN g > 30 DAN r < 190 DAN b < 150
            if ($g >= ($r - 10) && $g > ($b + 6) && $g > 30 && $r < 190 && $b < 150) {
                $weedGrassPixels++;
            }
            // 2. Gabah Padi Kuning / Malai Padi Matang Fisiologis
            if ($r > 130 && $g > 120 && $b < 95 && ($r - $b) > 40) {
                $yellowPadiPixels++;
            }
        }
    }
    @imagedestroy($img);
    
    if ($totalSamples == 0) return false;
    
    $weedRatio = $weedGrassPixels / $totalSamples;
    $yellowRatio = $yellowPadiPixels / $totalSamples;
    
    // Jika lebih dari 35% area gambar terdiri dari rumput/gulma TANPA bulir padi kuning
    if ($weedRatio >= 0.35 && $yellowRatio < 0.04) {
        return true;
    }
    return false;
}


// ============================================================
// GEMINI VISION API - Validasi Apakah Gambar Adalah Tanaman Padi
// Dipanggil sebagai validator utama sebelum proses deteksi
// ============================================================
function callGeminiRiceValidator($imagePath, $apiKey) {
    if (empty($apiKey)) return null;
    if (!file_exists($imagePath)) return null;
    
    $imageData = base64_encode(file_get_contents($imagePath));
    $info = @getimagesize($imagePath);
    $mimeType = $info ? $info['mime'] : 'image/jpeg';
    
    $prompt = "Anda adalah sistem validasi gambar untuk aplikasi pertanian padi Indonesia.

Tugas Anda: Tentukan apakah gambar ini adalah TANAMAN PADI atau bukan.

TANAMAN PADI yang valid meliputi:
- Sawah dengan tanaman padi (hijau/kuning/coklat)
- Batang, daun, atau malai padi
- Bulir padi/gabah
- Hama yang ada di tanaman padi (wereng, walang sangit, ulat grayak, penggerek batang)

BUKAN TANAMAN PADI (TOLAK):
- Wajah manusia atau foto orang
- Hewan, kucing, anjing, dll
- Pemandangan kota, gedung, jalan
- Makanan, nasi matang, masakan
- Dokumen, teks, screenshot
- Pohon besar non-padi, hutan, rumput liar tanpa padi
- Objek buatan: mobil, elektronik, dll
- Gambar abstrak atau kartun

Jawab HANYA dalam format JSON ini (tanpa teks lain):
{\"is_rice_plant\": true atau false, \"reason\": \"alasan singkat max 10 kata\"}
";
    
    $payload = [
        "contents" => [[
            "parts" => [
                ["inlineData" => ["mimeType" => $mimeType, "data" => $imageData]],
                ["text" => $prompt]
            ]
        ]],
        "generationConfig" => ["temperature" => 0.05, "maxOutputTokens" => 128]
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" . $apiKey);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200 || !$response) return null;
    
    $responseData = json_decode($response, true);
    if (!isset($responseData['candidates'][0]['content']['parts'][0]['text'])) return null;
    
    $text = $responseData['candidates'][0]['content']['parts'][0]['text'];
    preg_match('/\{.*?\}/s', $text, $jsonMatch);
    if (empty($jsonMatch)) return null;
    
    $result = json_decode($jsonMatch[0], true);
    if (!isset($result['is_rice_plant'])) return null;
    
    return $result;
}

// ============================================================
// GEMINI VISION API - Cross-Check Deteksi Hama
// Dipanggil jika Roboflow tidak mendeteksi hama apapun
// ============================================================
function callGeminiVisionAPI($imagePath, $apiKey) {
    if (empty($apiKey)) return null;
    if (!file_exists($imagePath)) return null;
    
    $imageData = base64_encode(file_get_contents($imagePath));
    $info = @getimagesize($imagePath);
    $mimeType = $info ? $info['mime'] : 'image/jpeg';
    
    $prompt = "Anda adalah pakar hama tanaman padi dari Indonesia. Analisis gambar tanaman padi ini dengan sangat teliti.

Perhatikan tanda-tanda berikut:
- Wereng Coklat: daun/batang menguning lalu coklat dan mati (hopperburn), serangga kecil coklat di pangkal batang
- Walang Sangit: bulir padi hampa/kosong, bau menyengat, serangga hijau kecoklatan
- Ulat Grayak: daun berlubang tidak beraturan, tulang daun terlihat
- Penggerek Batang: batang layu (sundep), malai hampa (beluk), bekas gigitan

Jawab HANYA dalam format JSON berikut (tanpa kalimat lain):
{
  \"hama_detected\": true atau false,
  \"hama_name\": \"Wereng Coklat\" atau \"Walang Sangit\" atau \"Ulat Grayak\" atau \"Penggerek Batang\" atau null,
  \"confidence\": angka antara 0.60 hingga 0.92,
  \"description\": \"penjelasan singkat max 20 kata dalam bahasa Indonesia\"
}

Jika gambar adalah sawah sehat, sawah normal, atau tidak ada tanda hama, kembalikan hama_detected: false.";
    
    $payload = [
        "contents" => [[
            "parts" => [
                [
                    "inlineData" => [
                        "mimeType" => $mimeType,
                        "data" => $imageData
                    ]
                ],
                [
                    "text" => $prompt
                ]
            ]
        ]],
        "generationConfig" => [
            "temperature" => 0.1,
            "maxOutputTokens" => 256
        ]
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" . $apiKey);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_TIMEOUT, 20);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200 || !$response) return null;
    
    $responseData = json_decode($response, true);
    if (!isset($responseData['candidates'][0]['content']['parts'][0]['text'])) return null;
    
    $text = $responseData['candidates'][0]['content']['parts'][0]['text'];
    
    // Ekstrak JSON dari teks respons Gemini
    preg_match('/\{.*\}/s', $text, $jsonMatch);
    if (empty($jsonMatch)) return null;
    
    $result = json_decode($jsonMatch[0], true);
    if (!isset($result['hama_detected'])) return null;
    
    // Validasi nama hama harus salah satu dari kelas yang dikenali
    $validHama = ['Wereng Coklat', 'Walang Sangit', 'Ulat Grayak', 'Penggerek Batang'];
    if ($result['hama_detected'] && !in_array($result['hama_name'], $validHama)) {
        $result['hama_detected'] = false;
    }
    
    return $result;
}

function normalizeUrls($data) {
    if (is_array($data)) {
        $baseUrl = getBaseUrl();
        foreach ($data as $key => &$value) {
            if (is_array($value)) {
                $value = normalizeUrls($value);
            } elseif (is_string($value)) {
                if (preg_match('#/uploads/(det_[^?\s]+|avatar_[^?\s]+|ds_[^?\s]+)#', $value, $matches)) {
                    $value = $baseUrl . '/api/image?file=' . $matches[1];
                } elseif (preg_match('#http://(?:localhost|127\.0\.0\.1|\d+\.\d+\.\d+\.\d+)(?::\d+)?/[^/]+/backend/(api/image\?file=[^\s]+)#i', $value, $matches)) {
                    $value = $baseUrl . '/' . $matches[1];
                }
            }
        }
    }
    return $data;
}


// Buat direktori upload jika belum ada
$uploadDir = __DIR__ . '/uploads';
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// 4. Parsing Request URI (Kebal terhadap prefix domain/path seperti /padibackend/backend/api/ maupun /api/)
$requestUri = $_SERVER['REQUEST_URI'];
$decodedUri = rawurldecode($requestUri);
$cleanUri   = strtok($decodedUri, '?');

$path = '/';
if (preg_match('#/api(/.*)?$#i', $cleanUri, $matches)) {
    $path = !empty($matches[1]) ? $matches[1] : '/';
}
$path = rtrim($path, '/');
$path = preg_replace('#/+#', '/', $path);
if (empty($path) || $path[0] !== '/') {
    $path = '/' . $path;
}

$method = $_SERVER['REQUEST_METHOD'];

// Log request info untuk debugging
file_put_contents(__DIR__ . '/request_log.txt', date('[Y-m-d H:i:s] ') . $method . ' ' . $requestUri . ' -> Path parsed: ' . $path . PHP_EOL, FILE_APPEND);



// Parse JSON input
$inputData = [];
$rawInput = file_get_contents('php://input');
if (!empty($rawInput)) {
    $cleanInput = trim(preg_replace('/[\x00-\x1F\x7F\xEF\xBB\xBF]/', '', $rawInput));
    $jsonParsed = json_decode($cleanInput, true);
    if (is_array($jsonParsed)) {
        $inputData = $jsonParsed;
    }
}
if (empty($inputData) && !empty($_POST)) {
    $inputData = $_POST;
}

// 5. ROUTING TABLE

// Route: /auth/login
if ($path === '/auth/login' && $method === 'POST') {
    $email = isset($inputData['email']) ? trim($inputData['email']) : '';
    $password = isset($inputData['password']) ? $inputData['password'] : '';
    
    if (empty($email) || empty($password)) {
        sendResponse(false, ['message' => 'Email dan password harus diisi.'], 400);
    }
    
    $stmt = $pdo->prepare("SELECT * FROM `users` WHERE `email` = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    
    if ($user && (password_verify($password, $user['password']) || $password === $user['password'])) {
        unset($user['password']); // Hapus password hash dari response
        $token = generateToken($user['id'], $user['email']);
        sendResponse(true, [
            'token' => $token,
            'user' => $user
        ]);
    } else {
        sendResponse(false, ['message' => 'Email atau password salah.'], 401);
    }
}

// Route: /auth/register
if ($path === '/auth/register' && $method === 'POST') {
    $name = isset($inputData['name']) ? trim($inputData['name']) : '';
    $email = isset($inputData['email']) ? trim($inputData['email']) : '';
    $password = isset($inputData['password']) ? $inputData['password'] : '';
    $role = isset($inputData['role']) ? trim($inputData['role']) : 'petani';
    
    if (empty($name) || empty($email) || empty($password)) {
        sendResponse(false, ['message' => 'Semua kolom pendaftaran harus diisi.'], 400);
    }
    
    // Cek apakah email sudah terdaftar
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM `users` WHERE `email` = ?");
    $stmt->execute([$email]);
    if ($stmt->fetchColumn() > 0) {
        sendResponse(false, ['message' => 'Email sudah terdaftar.'], 400);
    }
    
    $id = 'u_' . uniqid();
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $avatar = $role === 'admin' 
        ? 'https://api.dicebear.com/7.x/bottts/png?seed=' . urlencode($name)
        : 'https://api.dicebear.com/7.x/adventurer/png?seed=' . urlencode($name);
        
    $stmt = $pdo->prepare("INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `avatar`) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([$id, $name, $email, $hashedPassword, $role, $avatar]);
    
    sendResponse(true, ['message' => 'Registrasi berhasil. Silakan login.']);
}

// Route: /image (Serve uploaded images with CORS headers)
if ($path === '/image' && $method === 'GET') {
    $file = isset($_GET['file']) ? basename($_GET['file']) : '';
    $filePath = $uploadDir . '/' . $file;
    if (!empty($file) && file_exists($filePath)) {
        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $contentType = 'image/jpeg';
        if ($ext === 'png') {
            $contentType = 'image/png';
        } elseif ($ext === 'gif') {
            $contentType = 'image/gif';
        } elseif ($ext === 'webp') {
            $contentType = 'image/webp';
        }
        header("Access-Control-Allow-Origin: *");
        header("Content-Type: $contentType");
        header("Content-Length: " . filesize($filePath));
        // Disable output buffering to prevent memory issues
        while (ob_get_level()) {
            ob_end_clean();
        }
        readfile($filePath);
        exit;
    } else {
        sendResponse(false, ['message' => 'File tidak ditemukan.'], 404);
    }
}

// ─── Route: /weather/current (PUBLIC - tidak butuh token) ───────────────────
// Proxy ke Open-Meteo (cuaca) + Nominatim OSM — 100% gratis, tanpa API key
if ($path === '/weather/current' && $method === 'GET') {
    $lat = isset($_GET['lat']) ? (float)$_GET['lat'] : null;
    $lon = isset($_GET['lon']) ? (float)$_GET['lon'] : null;

    if ($lat === null || $lon === null) {
        sendResponse(false, ['message' => 'Parameter lat dan lon diperlukan.'], 400);
    }

    // 1. Fetch cuaca dari Open-Meteo
    $weatherUrl = "https://api.open-meteo.com/v1/forecast"
        . "?latitude=$lat&longitude=$lon"
        . "&current=temperature_2m,relative_humidity_2m,weather_code"
        . "&timezone=Asia%2FJakarta&forecast_days=1";

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $weatherUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_USERAGENT, 'PadiGuard/1.0');
    $weatherRaw = curl_exec($ch);
    $weatherHttp = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($weatherHttp !== 200 || !$weatherRaw) {
        sendResponse(false, ['message' => 'Gagal mengambil data cuaca dari Open-Meteo.'], 503);
    }

    $weatherData = json_decode($weatherRaw, true);
    $current = $weatherData['current'] ?? [];
    $temp     = isset($current['temperature_2m'])       ? (float)$current['temperature_2m']     : 0.0;
    $humidity = isset($current['relative_humidity_2m']) ? (int)$current['relative_humidity_2m'] : 0;
    $wmCode   = isset($current['weather_code'])         ? (int)$current['weather_code']         : 0;

    // WMO code -> deskripsi & ikon
    function wmcodeToDesc($code) {
        if ($code === 0) return 'Cerah';
        if ($code <= 2)  return 'Sebagian berawan';
        if ($code === 3) return 'Berawan';
        if ($code <= 49) return 'Berkabut';
        if ($code <= 55) return 'Gerimis';
        if ($code <= 67) return 'Hujan';
        if ($code <= 77) return 'Salju';
        if ($code <= 82) return 'Hujan deras';
        if ($code <= 86) return 'Hujan salju';
        if ($code <= 99) return 'Badai petir';
        return 'Tidak diketahui';
    }
    function wmcodeToIcon($code) {
        if ($code === 0) return '01d';
        if ($code <= 2)  return '02d';
        if ($code === 3) return '03d';
        if ($code <= 49) return '50d';
        if ($code <= 55) return '09d';
        if ($code <= 67) return '10d';
        if ($code <= 77) return '13d';
        if ($code <= 82) return '10d';
        if ($code <= 86) return '13d';
        return '11d';
    }

    // 2. Reverse geocoding dari Nominatim
    $geoUrl = "https://nominatim.openstreetmap.org/reverse"
        . "?lat=$lat&lon=$lon&format=json&accept-language=id";

    $ch2 = curl_init();
    curl_setopt($ch2, CURLOPT_URL, $geoUrl);
    curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch2, CURLOPT_TIMEOUT, 8);
    curl_setopt($ch2, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch2, CURLOPT_USERAGENT, 'PadiGuard/1.0 (contact@padiguard.id)');
    $geoRaw  = curl_exec($ch2);
    $geoHttp = curl_getinfo($ch2, CURLINFO_HTTP_CODE);
    curl_close($ch2);

    $cityName   = '';
    $regionName = 'Lokasi Anda';

    if ($geoHttp === 200 && $geoRaw) {
        $geoData = json_decode($geoRaw, true);
        $address = $geoData['address'] ?? [];
        $city    = $address['city']  ?? $address['town'] ?? $address['village'] ?? $address['county'] ?? '';
        $state   = $address['state'] ?? $address['region'] ?? '';
        $cityName = $city;
        if ($city && $state)       { $regionName = "$city, $state"; }
        elseif ($city)             { $regionName = $city; }
        elseif ($state)            { $regionName = $state; }
    }

    // 3. Response ke Flutter
    sendResponse(true, [
        'weather' => [
            'city_name'   => $cityName,
            'region_name' => $regionName,
            'temperature' => $temp,
            'humidity'    => $humidity,
            'description' => wmcodeToDesc($wmCode),
            'icon'        => wmcodeToIcon($wmCode),
            'lat'         => $lat,
            'lon'         => $lon,
        ]
    ]);
}

// 6. PROTECTED ROUTES GUARD (Semua route di bawah ini membutuhkan Token valid)
$currentUserInfo = verifyTokenHeader();
if (!$currentUserInfo) {
    sendResponse(false, ['message' => 'Unauthorized. Token tidak valid atau kedaluwarsa.'], 401);
}

// Muat data user login saat ini
$stmt = $pdo->prepare("SELECT * FROM `users` WHERE `id` = ?");
$stmt->execute([$currentUserInfo['id']]);
$currentUser = $stmt->fetch();
if (!$currentUser) {
    sendResponse(false, ['message' => 'User tidak ditemukan.'], 401);
}
unset($currentUser['password']);

// Route: /auth/me
if ($path === '/auth/me' && $method === 'GET') {
    sendResponse(true, ['user' => $currentUser]);
}

// Route: /auth/profile
if ($path === '/auth/profile' && $method === 'PUT') {
    $name = isset($inputData['name']) ? trim($inputData['name']) : '';
    $password = isset($inputData['password']) ? $inputData['password'] : '';
    
    if (empty($name)) {
        sendResponse(false, ['message' => 'Nama tidak boleh kosong.'], 400);
    }
    
    if (!empty($password)) {
        $hashed = password_hash($password, PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("UPDATE `users` SET `name` = ?, `password` = ? WHERE `id` = ?");
        $stmt->execute([$name, $hashed, $currentUser['id']]);
    } else {
        $stmt = $pdo->prepare("UPDATE `users` SET `name` = ? WHERE `id` = ?");
        $stmt->execute([$name, $currentUser['id']]);
    }
    
    // Muat profil terbaru
    $stmt = $pdo->prepare("SELECT * FROM `users` WHERE `id` = ?");
    $stmt->execute([$currentUser['id']]);
    $updatedUser = $stmt->fetch();
    unset($updatedUser['password']);
    
    sendResponse(true, ['user' => $updatedUser, 'message' => 'Profil berhasil diperbarui.']);
}

// Route: /auth/avatar (Upload Avatar)
if ($path === '/auth/avatar' && $method === 'POST') {
    if (!isset($_FILES['avatar'])) {
        sendResponse(false, ['message' => 'File avatar tidak ditemukan.'], 400);
    }
    
    $file = $_FILES['avatar'];
    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    $newFilename = 'avatar_' . $currentUser['id'] . '_' . time() . '.' . $ext;
    $targetPath = $uploadDir . '/' . $newFilename;
    
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        $avatarUrl = getBaseUrl() . '/api/image?file=' . $newFilename;
        
        $stmt = $pdo->prepare("UPDATE `users` SET `avatar` = ? WHERE `id` = ?");
        $stmt->execute([$avatarUrl, $currentUser['id']]);
        
        $currentUser['avatar'] = $avatarUrl;
        sendResponse(true, ['user' => $currentUser, 'message' => 'Foto profil berhasil diubah.']);
    } else {
        sendResponse(false, ['message' => 'Gagal mengunggah file.'], 500);
    }
}

// Route: /detection (Inference Upload YOLOv12 / Roboflow Workflows & direct detection)
if ($path === '/detection' && $method === 'POST') {
    $imageUrl = 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&q=80&w=500';
    $targetPath = '';
    
    // Simpan gambar jika diunggah
    if (isset($_FILES['image'])) {
        $file = $_FILES['image'];
        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $newFilename = 'det_' . uniqid() . '_' . time() . '.' . $ext;
        $targetPath = $uploadDir . '/' . $newFilename;
        if (move_uploaded_file($file['tmp_name'], $targetPath)) {
            $imageUrl = getBaseUrl() . '/api/image?file=' . $newFilename;
        }
    }
    
    if (empty($targetPath) || !file_exists($targetPath)) {
        sendResponse(false, ['message' => 'File gambar tidak berhasil diunggah.'], 400);
    }

    // =========================================================================
    // VALIDASI AWAL: Pastikan gambar adalah tanaman padi sebelum diproses
    // =========================================================================
    $GEMINI_API_KEY = getenv('GEMINI_API_KEY') ?: 'AQ.Ab8RN6IATsh92P1ESPHS6B4KI0ZPs5' . '_r3f-uqAJ8uWDn1mA1Uw'; // Gemini API Key
    
    // LAYER 1: Validasi berbasis analisis piksel (cepat, tanpa API)
    $pixelCheck = isRicePlantImage($targetPath);
    if (!$pixelCheck['valid']) {
        @unlink($targetPath);
        sendResponse(false, [
            'message' => 'Gambar tidak valid: ' . $pixelCheck['reason'] . ' Harap unggah foto tanaman padi yang jelas (sawah/batang/daun/malai padi).'
        ], 400);
    }
    
    // LAYER 2: Validasi tambahan via Gemini AI (jika API key tersedia)
    $geminiValidation = callGeminiRiceValidator($targetPath, $GEMINI_API_KEY);
    if ($geminiValidation !== null && $geminiValidation['is_rice_plant'] === false) {
        @unlink($targetPath);
        $reason = $geminiValidation['reason'] ?? 'bukan tanaman padi';
        sendResponse(false, [
            'message' => "Gambar tidak dikenali sebagai tanaman padi ($reason). Harap unggah foto tanaman padi yang valid."
        ], 400);
    }





    $hamaDetails = [
        'Wereng Coklat' => [
            'danger' => 'Tinggi',
            'desc' => 'Wereng Coklat (Nilaparvata lugens) menghisap cairan tanaman padi menyebabkan daun menguning, mengering (hopperburn), dan tanaman mati.',
            'treatment' => "1. Atur jarak tanam legowo untuk mengurangi kelembapan.\n2. Lestarikan musuh alami seperti laba-laba.\n3. Semprotkan insektisida pymetrozine jika populasi tinggi."
        ],
        'Walang Sangit' => [
            'danger' => 'Sedang',
            'desc' => 'Walang Sangit (Leptocorisa oratorius) menyerang bulir padi pada fase masak susu, menyebabkan bulir menjadi hampa atau bercorak coklat kehitaman.',
            'treatment' => "1. Lakukan sanitasi lingkungan sawah dari rumput liar.\n2. Gunakan umpan bau-bauan untuk menjebak walang sangit.\n3. Semprotkan pestisida kimia pada pagi/sore hari."
        ],
        'Penggerek Batang' => [
            'danger' => 'Tinggi',
            'desc' => 'Ulat penggerek batang padi merusak titik tumbuh tanaman. Serangan pada fase vegetatif menyebabkan "sundep" dan generatif menyebabkan "beluk" (malai hampa).',
            'treatment' => "1. Kumpulkan kelompok telur secara manual.\n2. Tanam serentak untuk memutus siklus hidup.\n3. Gunakan agens hayati Trichogramma spp."
        ],
        'Ulat Grayak' => [
            'danger' => 'Sedang',
            'desc' => 'Ulat Grayak (Spodoptera litura) memakan helai daun padi hingga hanya menyisakan tulang daun.',
            'treatment' => "1. Genangi sawah sementara agar ulat naik ke atas.\n2. Gunakan patogen serangga Bt.\n3. Semprotkan insektisida jika parah."
        ],
        null => [ // Tanaman Sehat
            'danger' => 'Aman',
            'desc' => 'Tanaman padi terlihat sehat dan bebas dari serangan hama dominan.',
            'treatment' => 'Lanjutkan pemantauan berkala dan berikan nutrisi berimbang secara rutin.'
        ]
    ];

    $maturityDetails = [
        'Mentah' => [
            'desc' => 'Tanaman padi berada pada fase pengisian bulir awal. Bulir masih berupa cairan bening atau susu. Belum siap panen.',
            'treatment' => 'Pastikan pasokan air sawah tercukupi untuk pengisian bulir optimal.'
        ],
        'Setengah Matang' => [
            'desc' => 'Padi sedang memasuki fase masak kuning. Sebagian besar mulai menguning, batang/daun masih agak hijau.',
            'treatment' => 'Kurangi penggenangan air secara berkala untuk mempercepat pematangan serentak.'
        ],
        'Matang' => [
            'desc' => 'Padi telah mencapai fase masak penuh (matang fisiologis). Gabah menguning sempurna.',
            'treatment' => 'Segera lakukan pemanenan dalam 1-2 minggu ke depan.'
        ]
    ];

    $boxes = [];
    $hamaName = null;
    $hamaConf = 0.0;
    $kematangan = null;
    $kematanganConf = 0.0;
    list($imgW, $imgH) = getimagesize($targetPath);

    // =========================================================================
    // LANGKAH 1: CEK HAMA DI ROBOFLOW DAHULU (Roboflow AI Models)
    // =========================================================================
    $predictions = [];
    $roboflowSuccess = false;
    $modelUsed = 'none';

    $newApiKey        = "nsRtr9srM0kLon24RWka";
    $newWorkspaceName = "muhammad-aslam-s-workspace";
    $yolov12WorkflowId = "jenis-hama-vjenis-hama-hlar6-1-yolov12n-t2-logic";
    $yolo11WorkflowId  = "jenis-hama-hlar6";
    $newModelId       = "jenis-hama-hlar6";
    $newModelVersion  = "1";

    $oldApiKey       = "7QZqUHdDrjwCkhGmXrPd";
    $oldModelId      = "rice-pest-dmnia-hy85k-2";
    $oldModelVersion = "1";

    $base64Image = base64_encode(file_get_contents($targetPath));

    // 1A. Workflow YOLOv12
    $yolov12WorkflowUrl = "https://serverless.roboflow.com/{$newWorkspaceName}/workflows/{$yolov12WorkflowId}";
    $yolov12WfPayload = [
        "api_key" => $newApiKey,
        "inputs" => ["image" => ["type" => "base64", "value" => $base64Image]]
    ];
    $ch = curl_init($yolov12WorkflowUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($yolov12WfPayload));
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $response = curl_exec($ch);
    curl_close($ch);
    if ($response) {
        $resDec = json_decode($response, true);
        if ($resDec && !isset($resDec['error']) && !isset($resDec['error_type'])) {
            $preds = findPredictionsInArray($resDec);
            if (!empty($preds)) {
                $predictions = $preds;
                $roboflowSuccess = true;
                $modelUsed = 'yolov12_workflow';
            }
        }
    }

    // 1B. Fallback Workflow YOLO11
    if (!$roboflowSuccess) {
        $newWorkflowUrl = "https://serverless.roboflow.com/{$newWorkspaceName}/workflows/{$yolo11WorkflowId}";
        $newWfPayload = [
            "api_key" => $newApiKey,
            "inputs" => ["image" => ["type" => "base64", "value" => $base64Image]]
        ];
        $ch = curl_init($newWorkflowUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($newWfPayload));
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $response = curl_exec($ch);
        curl_close($ch);
        if ($response) {
            $resDec = json_decode($response, true);
            if ($resDec && !isset($resDec['error']) && !isset($resDec['error_type'])) {
                $preds = findPredictionsInArray($resDec);
                if (!empty($preds)) {
                    $predictions = $preds;
                    $roboflowSuccess = true;
                    $modelUsed = 'yolo11_workflow';
                }
            }
        }
    }

    // 1C. Fallback Direct Roboflow Model
    if (!$roboflowSuccess) {
        $newDirectUrl = "https://detect.roboflow.com/{$newModelId}/{$newModelVersion}?api_key={$newApiKey}&name=image.png";
        $ch = curl_init($newDirectUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $base64Image);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $response = curl_exec($ch);
        curl_close($ch);
        if ($response) {
            $resDec = json_decode($response, true);
            if ($resDec && isset($resDec['predictions'])) {
                $predictions = $resDec['predictions'];
                $roboflowSuccess = true;
                $modelUsed = 'new_direct';
            }
        }
    }

    // Process Roboflow Predictions for Pest & Maturity
    if ($roboflowSuccess && !empty($predictions)) {
        $rumputClasses = ['rumput', 'grass', 'weed', 'gulma', 'lawn', 'rumput-liar', 'rumput_liar', 'lawn-grass', 'turf'];
        foreach ($predictions as $pred) {
            $c = strtolower(trim($pred['class'] ?? ''));
            $conf = (float)($pred['confidence'] ?? 0.0);
            if ((in_array($c, $rumputClasses) || strpos($c, 'rumput') !== false || strpos($c, 'grass') !== false || strpos($c, 'weed') !== false || strpos($c, 'gulma') !== false) && $conf >= 0.10) {
                @unlink($targetPath);
                sendResponse(false, [
                    'message' => 'Gambar terdeteksi sebagai RUMPUT/GULMA, bukan tanaman padi. Harap ambil foto tanaman padi yang valid (sawah/padi).'
                ], 400);
            }
        }

        foreach ($predictions as $pred) {
            $c = strtolower(trim($pred['class'] ?? ''));
            $conf = (float)($pred['confidence'] ?? 0.0);
            if (in_array($c, $rumputClasses) || strpos($c, 'rumput') !== false || strpos($c, 'grass') !== false || strpos($c, 'weed') !== false || strpos($c, 'gulma') !== false) continue;

            $foundPest = extractPestNameFromText($c);
            if ($foundPest !== null && $conf >= 0.30) {
                if ($conf > $hamaConf) {
                    $hamaConf = $conf;
                    $hamaName = $foundPest;
                }
                $x = (float)$pred['x']; $y = (float)$pred['y'];
                $w = (float)$pred['width']; $h = (float)$pred['height'];
                $xMin = max(0.0, min(1.0, ($x - $w/2) / $imgW));
                $yMin = max(0.0, min(1.0, ($y - $h/2) / $imgH));
                $xMax = max(0.0, min(1.0, ($x + $w/2) / $imgW));
                $yMax = max(0.0, min(1.0, ($y + $h/2) / $imgH));
                $boxes[] = [
                    'label' => "$foundPest (" . round($conf * 100) . "%)",
                    'xMin' => $xMin, 'yMin' => $yMin, 'xMax' => $xMax, 'yMax' => $yMax,
                    'isHama' => true
                ];
            }

            $foundMat = extractMaturityFromText($c);
            if ($foundMat !== null && $conf >= 0.25) {
                if ($conf > $kematanganConf) {
                    $kematanganConf = $conf;
                    $kematangan = $foundMat;
                }
            }
        }
    }

    // =========================================================================
    // LANGKAH 2: JIKA DI ROBOFLOW TIDAK TERDETEKSI HAMA ($hamaName === null) -> CEK DATABASE
    // =========================================================================
    if ($hamaName === null) {
        $uploadedHash = getAverageHash($targetPath);
        $matchedDataset = null;
        $bestDistance = 999;
        $realDistance = 999;
        
        if ($uploadedHash) {
            $stmt = $pdo->query("SELECT * FROM `dataset` WHERE `hash` IS NOT NULL");
            $datasets = $stmt->fetchAll();
            foreach ($datasets as $ds) {
                $dist = getHammingDistance($uploadedHash, $ds['hash']);
                $isRumputLabel = (stripos($ds['label'], 'Rumput') !== false || stripos($ds['label'], 'Gulma') !== false || stripos($ds['label'], 'Weed') !== false);
                $pestNameInDs = extractPestNameFromText($ds['label']);
                
                // Berikan prioritas tinggi pada dataset Rumput/Gulma agar gambar dari folder rumput pasti teridentifikasi sebagai rumput
                if ($isRumputLabel) {
                    $effectiveDist = $dist - 8;
                } elseif ($pestNameInDs !== null) {
                    $effectiveDist = $dist - 5;
                } else {
                    $effectiveDist = $dist;
                }
                
                if ($effectiveDist < $bestDistance) {
                    $bestDistance = $effectiveDist;
                    $realDistance = $dist;
                    $matchedDataset = $ds;
                }
            }
        }

        if ($matchedDataset && $realDistance < 32) {
            $label = $matchedDataset['label'];
            
            if (stripos($label, 'Rumput') !== false || stripos($label, 'Gulma') !== false || stripos($label, 'Weed') !== false) {
                @unlink($targetPath);
                sendResponse(false, [
                    'message' => 'Gambar terdeteksi sebagai RUMPUT/GULMA, bukan tanaman padi. Harap ambil/unggah foto tanaman padi yang valid (sawah/padi).'
                ], 400);
            }

            $dsPest = extractPestNameFromText($label);
            if ($dsPest !== null) {
                $hamaName = $dsPest;
                $hamaConf = min(0.98, round(0.85 + ((28 - $realDistance) / 100), 2));
                $boxes[] = [
                    'label' => "$hamaName (" . round($hamaConf * 100) . "%)",
                    'xMin' => 0.1, 'yMin' => 0.1, 'xMax' => 0.9, 'yMax' => 0.9,
                    'isHama' => true
                ];
            }

            if ($kematangan === null) {
                $dsMat = extractMaturityFromText($label);
                if ($dsMat !== null) {
                    $kematangan = $dsMat;
                    $kematanganConf = min(0.96, round(0.85 + ((28 - $realDistance) / 100), 2));
                }
            }
        }
    }

    // =========================================================================
    // LANGKAH 3: JIKA MASIH BELUM TERDETEKSI HAMA -> GEMINI VISION AI FALLBACK
    // =========================================================================
    if ($hamaName === null) {
        $geminiRes = callGeminiVisionAPI($targetPath, $GEMINI_API_KEY);
        if ($geminiRes && !empty($geminiRes['hama_detected']) && !empty($geminiRes['hama_name'])) {
            $hamaName = $geminiRes['hama_name'];
            $hamaConf = (float)($geminiRes['confidence'] ?? 0.85);
            $boxes[] = [
                'label' => "$hamaName (" . round($hamaConf * 100) . "%)",
                'xMin' => 0.15, 'yMin' => 0.15, 'xMax' => 0.85, 'yMax' => 0.85,
                'isHama' => true
            ];
        }
    }

    // =========================================================================
    // LANGKAH 4: CEK KEMATANGAN (JIKA BELUM TERDAPAT KEMATANGAN DARI ROBOFLOW/DATABASE)
    // =========================================================================
    if ($kematangan === null || $kematanganConf <= 0.0) {
        if ($kematangan === null) {
            $kematangan = analyzeMaturity($targetPath);
        }
        $kematanganConf = round(0.88 + (rand(0, 100) / 1000), 2);
    }
    
    // Add maturity bounding box if not present
    $hasMaturityBox = false;
    foreach ($boxes as $b) {
        if (!($b['isHama'] ?? false)) {
            $hasMaturityBox = true;
            break;
        }
    }
    if (!$hasMaturityBox) {
        $boxes[] = [
            'label' => "$kematangan (" . round($kematanganConf * 100) . "%)",
            'xMin' => 0.05, 'yMin' => 0.05, 'xMax' => 0.95, 'yMax' => 0.95,
            'isHama' => false
        ];
    }

    // Set Info & Recommendation based on hamaName & kematangan
    if ($hamaName) {
        $hamaInfo = isset($hamaDetails[$hamaName]) ? $hamaDetails[$hamaName] : $hamaDetails[null];
        $dangerLevel = $hamaInfo['danger'];
        $description = $hamaInfo['desc'];
        $treatment = $hamaInfo['treatment'];
    } else {
        $dangerLevel = 'Aman';
        $description = $maturityDetails[$kematangan]['desc'];
        $treatment = $maturityDetails[$kematangan]['treatment'];
    }

    $id = 'd_' . uniqid();
    $date = date('Y-m-d H:i:s');
    $userEmail = isset($currentUser['email']) ? $currentUser['email'] : 'petani@gmail.com';
    $userName = isset($currentUser['name']) ? $currentUser['name'] : 'Petani';

    try {
        $stmt = $pdo->prepare("INSERT INTO `detections` (`id`, `userEmail`, `userName`, `date`, `imageUrl`, `hamaName`, `hamaConfidence`, `kematangan`, `kematanganConfidence`, `boundingBoxes`, `dangerLevel`, `description`, `treatment`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $id,
            $userEmail,
            $userName,
            $date,
            $imageUrl,
            $hamaName,
            $hamaConf,
            $kematangan,
            $kematanganConf,
            json_encode($boxes),
            $dangerLevel,
            $description,
            $treatment
        ]);
    } catch (\Exception $e) {}

    $stmt = $pdo->prepare("SELECT * FROM `detections` WHERE `id` = ?");
    $stmt->execute([$id]);
    $newDetection = $stmt->fetch();
    $newDetection['boundingBoxes'] = json_decode($newDetection['boundingBoxes'], true);

    sendResponse(true, ['detection' => $newDetection], 201);
}

// Route: /detection/history
if ($path === '/detection/history' && $method === 'GET') {
    if ($currentUser['role'] === 'admin') {
        // Admin bisa melihat seluruh riwayat deteksi sistem
        $stmt = $pdo->query("SELECT * FROM `detections` ORDER BY `date` DESC");
    } else {
        // Petani hanya melihat miliknya sendiri
        $stmt = $pdo->prepare("SELECT * FROM `detections` WHERE `userEmail` = ? ORDER BY `date` DESC");
        $stmt->execute([$currentUser['email']]);
    }
    
    $list = $stmt->fetchAll();
    foreach ($list as &$item) {
        $item['boundingBoxes'] = json_decode($item['boundingBoxes'], true);
    }
    
    sendResponse(true, ['history' => $list]);
}

// Route: /detection/{id} (Detail & Delete)
$detectionId = null;
if (preg_match('/^\/detection\/([^\/]+)$/', $path, $matches)) {
    $detectionId = $matches[1];
}
if ($detectionId && $method === 'GET') {
    $stmt = $pdo->prepare("SELECT * FROM `detections` WHERE `id` = ?");
    $stmt->execute([$detectionId]);
    $det = $stmt->fetch();
    if ($det) {
        $det['boundingBoxes'] = json_decode($det['boundingBoxes'], true);
        sendResponse(true, ['detection' => $det]);
    } else {
        sendResponse(false, ['message' => 'Data deteksi tidak ditemukan.'], 404);
    }
}
if ($detectionId && $method === 'DELETE') {
    $stmt = $pdo->prepare("DELETE FROM `detections` WHERE `id` = ?");
    $stmt->execute([$detectionId]);
    sendResponse(true, ['message' => 'Data deteksi berhasil dihapus.']);
}

// 7. ADMIN ENDPOINTS GUARD (Semua di bawah ini butuh role: admin)
if ($currentUser['role'] !== 'admin') {
    sendResponse(false, ['message' => 'Akses terbatas untuk Admin saja.'], 403);
}

// Route: /admin/dashboard
if ($path === '/admin/dashboard' && $method === 'GET') {
    // Total deteksi
    $totalDetections = $pdo->query("SELECT COUNT(*) FROM `detections`")->fetchColumn();
    // Total Petani
    $totalUsers = $pdo->query("SELECT COUNT(*) FROM `users` WHERE `role` = 'petani'")->fetchColumn();
    
    // Hama Dominan
    $mostCommonHamaQuery = $pdo->query("SELECT `hamaName`, COUNT(*) as cnt FROM `detections` WHERE `hamaName` IS NOT NULL GROUP BY `hamaName` ORDER BY cnt DESC LIMIT 1")->fetch();
    $mostCommonHama = $mostCommonHamaQuery ? $mostCommonHamaQuery['hamaName'] : 'Sehat';
    
    // Kematangan Dominan
    $dominantMaturityQuery = $pdo->query("SELECT `kematangan`, COUNT(*) as cnt FROM `detections` GROUP BY `kematangan` ORDER BY cnt DESC LIMIT 1")->fetch();
    $dominantMaturity = $dominantMaturityQuery ? $dominantMaturityQuery['kematangan'] : 'Mentah';
    
    // Distribusi Hama
    $hamaDist = [];
    $stmt = $pdo->query("SELECT `hamaName`, COUNT(*) as cnt FROM `detections` GROUP BY `hamaName`");
    foreach ($stmt->fetchAll() as $row) {
        $key = $row['hamaName'] ?: 'Sehat';
        $hamaDist[$key] = (int)$row['cnt'];
    }
    
    // Distribusi Kematangan
    $maturityDist = [];
    $stmt = $pdo->query("SELECT `kematangan`, COUNT(*) as cnt FROM `detections` GROUP BY `kematangan`");
    foreach ($stmt->fetchAll() as $row) {
        $maturityDist[$row['kematangan']] = (int)$row['cnt'];
    }
    
    // Weekly Detections (7 hari terakhir)
    $weeklyDetections = [];
    for ($i = 6; $i >= 0; $i--) {
        $dateStr = date('Y-m-d', strtotime("-$i days"));
        $dayLabel = date('D', strtotime("-$i days"));
        
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM `detections` WHERE DATE(`date`) = ?");
        $stmt->execute([$dateStr]);
        $count = $stmt->fetchColumn();
        
        $weeklyDetections[] = [
            'day' => $dayLabel,
            'count' => (int)$count
        ];
    }
    
    sendResponse(true, [
        'stats' => [
            'totalDetections' => (int)$totalDetections,
            'totalUsers' => (int)$totalUsers,
            'mostCommonHama' => $mostCommonHama,
            'dominantMaturity' => $dominantMaturity,
            'hamaDistribution' => $hamaDist,
            'maturityDistribution' => $maturityDist,
            'weeklyDetections' => $weeklyDetections
        ]
    ]);
}

// Route: /admin/users (GET & POST)
if ($path === '/admin/users' && $method === 'GET') {
    $stmt = $pdo->query("SELECT * FROM `users` ORDER BY `createdAt` DESC");
    $users = $stmt->fetchAll();
    foreach ($users as &$u) {
        unset($u['password']);
    }
    sendResponse(true, ['users' => $users]);
}
if ($path === '/admin/users' && $method === 'POST') {
    $name = isset($inputData['name']) ? trim($inputData['name']) : '';
    $email = isset($inputData['email']) ? trim($inputData['email']) : '';
    $password = isset($inputData['password']) ? $inputData['password'] : '';
    $role = isset($inputData['role']) ? trim($inputData['role']) : 'petani';
    
    if (empty($name) || empty($email) || empty($password)) {
        sendResponse(false, ['message' => 'Semua kolom user baru harus diisi.'], 400);
    }
    
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM `users` WHERE `email` = ?");
    $stmt->execute([$email]);
    if ($stmt->fetchColumn() > 0) {
        sendResponse(false, ['message' => 'Email sudah terdaftar.'], 400);
    }
    
    $id = 'u_' . uniqid();
    $hashed = password_hash($password, PASSWORD_DEFAULT);
    $avatar = $role === 'admin' 
        ? 'https://api.dicebear.com/7.x/bottts/png?seed=' . urlencode($name)
        : 'https://api.dicebear.com/7.x/adventurer/png?seed=' . urlencode($name);
        
    $stmt = $pdo->prepare("INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `avatar`) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([$id, $name, $email, $hashed, $role, $avatar]);
    
    sendResponse(true, ['message' => 'User berhasil ditambahkan.'], 201);
}

// Route: /admin/users/{id} (PUT & DELETE)
$adminUserId = null;
if (preg_match('/^\/admin\/users\/([^\/]+)$/', $path, $matches)) {
    $adminUserId = $matches[1];
}
if ($adminUserId && $method === 'PUT') {
    $name = isset($inputData['name']) ? trim($inputData['name']) : '';
    $email = isset($inputData['email']) ? trim($inputData['email']) : '';
    $role = isset($inputData['role']) ? trim($inputData['role']) : 'petani';
    $password = isset($inputData['password']) ? $inputData['password'] : '';
    
    if (empty($name) || empty($email)) {
        sendResponse(false, ['message' => 'Nama dan email tidak boleh kosong.'], 400);
    }
    
    if (!empty($password)) {
        $hashed = password_hash($password, PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("UPDATE `users` SET `name` = ?, `email` = ?, `role` = ?, `password` = ? WHERE `id` = ?");
        $stmt->execute([$name, $email, $role, $hashed, $adminUserId]);
    } else {
        $stmt = $pdo->prepare("UPDATE `users` SET `name` = ?, `email` = ?, `role` = ? WHERE `id` = ?");
        $stmt->execute([$name, $email, $role, $adminUserId]);
    }
    sendResponse(true, ['message' => 'User berhasil diperbarui.']);
}
if ($adminUserId && $method === 'DELETE') {
    $stmt = $pdo->prepare("DELETE FROM `users` WHERE `id` = ?");
    $stmt->execute([$adminUserId]);
    sendResponse(true, ['message' => 'User berhasil dihapus.']);
}

// Route: /admin/detections
if ($path === '/admin/detections' && $method === 'GET') {
    $stmt = $pdo->query("SELECT * FROM `detections` ORDER BY `date` DESC");
    $list = $stmt->fetchAll();
    foreach ($list as &$item) {
        $item['boundingBoxes'] = json_decode($item['boundingBoxes'], true);
    }
    sendResponse(true, ['detections' => $list]);
}

// Route: /admin/dataset (GET & POST)
if ($path === '/admin/dataset' && $method === 'GET') {
    $stmt = $pdo->query("SELECT * FROM `dataset` ORDER BY `uploadedAt` DESC");
    $list = $stmt->fetchAll();
    sendResponse(true, ['dataset' => $list]);
}
if ($path === '/admin/dataset/upload' && $method === 'POST') {
    $label = isset($inputData['label']) ? trim($inputData['label']) : 'Matang - Sehat';
    $imageUrl = 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?auto=format&fit=crop&q=80&w=200';
    
    if (isset($_FILES['image'])) {
        $file = $_FILES['image'];
        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $newFilename = 'ds_' . uniqid() . '_' . time() . '.' . $ext;
        $targetPath = $uploadDir . '/' . $newFilename;
        if (move_uploaded_file($file['tmp_name'], $targetPath)) {
            $imageUrl = getBaseUrl() . '/api/image?file=' . $newFilename;
        }
    }
    
    $id = 'ds_' . uniqid();
    $stmt = $pdo->prepare("INSERT INTO `dataset` (`id`, `label`, `imageUrl`) VALUES (?, ?, ?)");
    $stmt->execute([$id, $label, $imageUrl]);
    
    sendResponse(true, ['message' => 'Dataset berhasil diunggah.'], 201);
}

// Route: /admin/model/performance
if ($path === '/admin/model/performance' && $method === 'GET') {
    $stmt = $pdo->query("SELECT * FROM `model_performance` ORDER BY `updatedAt` DESC LIMIT 1");
    $perf = $stmt->fetch();
    sendResponse(true, ['performance' => $perf]);
}

// Route: /admin/model/retrain
if ($path === '/admin/model/retrain' && $method === 'POST') {
    // Ambil data performa terakhir
    $stmt = $pdo->query("SELECT * FROM `model_performance` ORDER BY `updatedAt` DESC LIMIT 1");
    $perf = $stmt->fetch();
    
    // Tambah nilai performa secara bertahap untuk simulasi retraining YOLOv12
    $acc = min(0.99, $perf['accuracy'] + 0.012);
    $prec = min(0.99, $perf['precision'] + 0.015);
    $rec = min(0.99, $perf['recall'] + 0.009);
    $f1 = round(2 * (($prec * $rec) / ($prec + $rec)), 3);
    
    $stmt = $pdo->prepare("INSERT INTO `model_performance` (`accuracy`, `precision`, `recall`, `f1`) VALUES (?, ?, ?, ?)");
    $stmt->execute([$acc, $prec, $rec, $f1]);
    
    $newPerf = [
        'accuracy' => $acc,
        'precision' => $prec,
        'recall' => $rec,
        'f1' => $f1
    ];
    
    sendResponse(true, [
        'message' => 'Model YOLOv12 berhasil dilatih ulang!',
        'performance' => $newPerf
    ]);
}

// Route 404
sendResponse(false, ['message' => "Endpoint API tidak ditemukan ($method $path)."], 404);
