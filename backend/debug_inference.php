<?php
// debug_inference.php
// Endpoint diagnostik khusus untuk membandingkan output setiap layer inferensi
// antara Laragon lokal dan Railway.
// HAPUS FILE INI SETELAH AUDIT SELESAI - Jangan di-deploy ke production permanen.

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
date_default_timezone_set('Asia/Jakarta');
error_reporting(E_ALL);
ini_set('display_errors', 0);

$auditLog = [
    'audit_id'    => uniqid('audit_'),
    'timestamp'   => date('Y-m-d H:i:s'),
    'environment' => [],
    'image_info'  => [],
    'layers'      => [
        'layer0_file_save'        => ['status' => 'pending', 'data' => []],
        'layer1_gemini_validator' => ['status' => 'pending', 'data' => []],
        'layer2_pixel_analysis'   => ['status' => 'pending', 'data' => []],
        'layer3_roboflow_pest'    => ['status' => 'pending', 'data' => []],
        'layer4_roboflow_maturity'=> ['status' => 'pending', 'data' => []],
        'layer5_hash_matching'    => ['status' => 'pending', 'data' => []],
        'layer6_gemini_crosscheck'=> ['status' => 'pending', 'data' => []],
        'layer7_maturity_pixel'   => ['status' => 'pending', 'data' => []],
    ],
    'final_result' => [],
    'diff_flags'   => [],
];

// â”€â”€â”€ ENVIRONMENT INFO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$auditLog['environment'] = [
    'php_version'         => PHP_VERSION,
    'server_software'     => $_SERVER['SERVER_SOFTWARE'] ?? 'unknown',
    'http_host'           => $_SERVER['HTTP_HOST'] ?? 'unknown',
    'server_addr'         => $_SERVER['SERVER_ADDR'] ?? 'unknown',
    'is_railway'          => !empty(getenv('RAILWAY_ENVIRONMENT')),
    'railway_env'         => getenv('RAILWAY_ENVIRONMENT') ?: null,
    'gemini_key_in_env'   => !empty(getenv('GEMINI_API_KEY')),
    'gemini_key_len'      => strlen(getenv('GEMINI_API_KEY') ?: ''),
    'gd_available'        => extension_loaded('gd'),
    'curl_available'      => extension_loaded('curl'),
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'post_max_size'       => ini_get('post_max_size'),
    'memory_limit'        => ini_get('memory_limit'),
    'max_execution_time'  => ini_get('max_execution_time'),
];

// â”€â”€â”€ HELPER FUNCTIONS (copied from index.php) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function getEnvVar($name, $default = '') {
    if (isset($_ENV[$name]) && $_ENV[$name] !== '') return $_ENV[$name];
    if (isset($_SERVER[$name]) && $_SERVER[$name] !== '') return $_SERVER[$name];
    $val = getenv($name);
    if ($val !== false && $val !== '') return $val;
    return $default;
}

function getAverageHash_debug($imagePath) {
    if (!file_exists($imagePath) || is_dir($imagePath)) return null;
    $info = @getimagesize($imagePath);
    if (!$info) return null;
    $mime = $info['mime'];
    if ($mime == 'image/jpeg' || $mime == 'image/jpg') { $img = @imagecreatefromjpeg($imagePath); }
    elseif ($mime == 'image/png')  { $img = @imagecreatefrompng($imagePath); }
    elseif ($mime == 'image/webp') { $img = @imagecreatefromwebp($imagePath); }
    else return null;
    if (!$img) return null;
    $resized = imagecreatetruecolor(8, 8);
    imagecopyresampled($resized, $img, 0, 0, 0, 0, 8, 8, imagesx($img), imagesy($img));
    $pixels = []; $sum = 0;
    for ($y = 0; $y < 8; $y++) {
        for ($x = 0; $x < 8; $x++) {
            $rgb = imagecolorat($resized, $x, $y);
            $gray = round((($rgb >> 16 & 0xFF) + ($rgb >> 8 & 0xFF) + ($rgb & 0xFF)) / 3);
            $pixels[] = $gray; $sum += $gray;
        }
    }
    $avg = $sum / 64;
    $hash = '';
    foreach ($pixels as $pixel) { $hash .= ($pixel >= $avg) ? '1' : '0'; }
    imagedestroy($resized); imagedestroy($img);
    return $hash;
}

function hammingDistance_debug($h1, $h2) {
    if (!$h1 || !$h2 || strlen($h1) !== strlen($h2)) return 999;
    $dist = 0;
    for ($i = 0; $i < strlen($h1); $i++) { if ($h1[$i] !== $h2[$i]) $dist++; }
    return $dist;
}

function analyzePixels_debug($imagePath) {
    $result = [
        'green_count'  => 0, 'yellow_count' => 0, 'total_samples' => 0,
        'yellow_ratio' => 0, 'maturity'     => 'unknown',
        'error'        => null,
    ];
    if (!file_exists($imagePath)) { $result['error'] = 'File not found'; return $result; }
    $info = @getimagesize($imagePath);
    if (!$info) { $result['error'] = 'Not a valid image'; return $result; }
    $mime = $info['mime'];
    if ($mime == 'image/jpeg' || $mime == 'image/jpg') { $img = @imagecreatefromjpeg($imagePath); }
    elseif ($mime == 'image/png')  { $img = @imagecreatefrompng($imagePath); }
    elseif ($mime == 'image/webp') { $img = @imagecreatefromwebp($imagePath); }
    else { $result['error'] = 'Unsupported format'; return $result; }
    if (!$img) { $result['error'] = 'Failed to open image'; return $result; }
    $w = imagesx($img); $h = imagesy($img);
    $sampleX = 30; $sampleY = 30;
    $stepX = max(1, (int)($w / $sampleX));
    $stepY = max(1, (int)($h / $sampleY));
    for ($x = 0; $x < $w; $x += $stepX) {
        for ($y = 0; $y < $h; $y += $stepY) {
            $result['total_samples']++;
            $rgb = @imagecolorat($img, (int)$x, (int)$y);
            if ($rgb === false) continue;
            $r = ($rgb >> 16) & 0xFF; $g = ($rgb >> 8) & 0xFF; $b = $rgb & 0xFF;
            if ($g > $r && $g > $b && ($g - $r) > 12) { $result['green_count']++; }
            elseif ($r > 120 && $g > 110 && ($r - $b) > 35 && ($g - $b) > 25 && abs($r - $g) < 40) { $result['yellow_count']++; }
        }
    }
    imagedestroy($img);
    $total = $result['green_count'] + $result['yellow_count'];
    if ($total < 15) { $result['maturity'] = 'Mentah'; $result['yellow_ratio'] = 0; return $result; }
    $yr = $result['yellow_count'] / $total;
    $result['yellow_ratio'] = round($yr, 4);
    if ($yr > 0.65) $result['maturity'] = 'Matang';
    elseif ($yr < 0.35 || $result['green_count'] >= ($result['yellow_count'] * 1.5)) $result['maturity'] = 'Mentah';
    else $result['maturity'] = 'Setengah Matang';
    return $result;
}

function analyzeRiceValidation_debug($imagePath) {
    // Mirrors isRicePlantImage() in index.php but returns detailed numbers
    $result = [
        'valid'                   => false,
        'reason'                  => '',
        'rice_color_count'        => 0,  // â† INTENTIONALLY track to show bug
        'rice_color_initialized'  => false, // track whether it was initialized
        'skin_count'              => 0,
        'indoor_dark_count'       => 0,
        'clothing_count'          => 0,
        'doc_bg_count'            => 0,
        'blue_count'              => 0,
        'gray_count'              => 0,
        'total_samples'           => 0,
        'ratios'                  => [],
        'error'                   => null,
    ];
    if (!file_exists($imagePath)) { $result['error'] = 'File not found'; return $result; }
    $info = @getimagesize($imagePath);
    if (!$info) { $result['error'] = 'Not a valid image'; return $result; }
    $mime = $info['mime'];
    if ($mime == 'image/jpeg' || $mime == 'image/jpg') { $img = @imagecreatefromjpeg($imagePath); }
    elseif ($mime == 'image/png')  { $img = @imagecreatefrompng($imagePath); }
    elseif ($mime == 'image/webp') { $img = @imagecreatefromwebp($imagePath); }
    else { $result['error'] = 'Unsupported format'; return $result; }
    if (!$img) { $result['error'] = 'Failed to open image'; return $result; }

    // *** REPRODUCE THE BUG: $riceColorCount NOT initialized before loop ***
    // In production index.php, $riceColorCount is undefined here â€” PHP uses 0 with warning
    // We explicitly track this:
    $result['rice_color_initialized'] = false; // NOT initialized in production!
    $riceColorCount = 0; // We initialize it here CORRECTLY for accurate debug output

    $w = imagesx($img); $h = imagesy($img);
    $stepX = max(1, (int)($w / 60)); $stepY = max(1, (int)($h / 60));
    for ($x = 0; $x < $w; $x += $stepX) {
        for ($y = 0; $y < $h; $y += $stepY) {
            $result['total_samples']++;
            $rgb = @imagecolorat($img, (int)$x, (int)$y);
            if ($rgb === false) continue;
            $r = ($rgb >> 16) & 0xFF; $g = ($rgb >> 8) & 0xFF; $b = $rgb & 0xFF;
            $isGreenPadi  = ($g > $r && $g > $b + 8 && $g > 35);
            $isYellowPadi = ($r > 90 && $g > 80 && $b < 140 && ($r - $b) > 25 && ($g - $b) > 15 && abs($r - $g) < 45);
            $isDryPadi    = ($r > 70 && $g > 55 && $b < 105 && $r > $b + 18 && ($r - $g) < 30 && ($g - $b) > 8);
            if ($isGreenPadi || $isYellowPadi || $isDryPadi) $riceColorCount++;
            $cb = 128 - 0.168736 * $r - 0.331264 * $g + 0.5 * $b;
            $cr = 128 + 0.418688 * $r - 0.345842 * $g - 0.072846 * $b;
            $isRgbSkin   = ($r > 60) && ($g > 35) && ($b > 20) && ($r > $g) && ($g > $b) && (($r - $g) >= 8);
            $isYcbcrSkin = ($cb >= 77 && $cb <= 130) && ($cr >= 130 && $cr <= 180);
            if ($isRgbSkin || $isYcbcrSkin) $result['skin_count']++;
            if ($r < 55 && $g < 55 && $b < 55) $result['indoor_dark_count']++;
            $isRedShirt = ($r > 160 && $g < 70 && $b < 70);
            $isBlueShirt = ($b > 130 && $b > $r + 30 && $b > $g + 30);
            if ($isRedShirt || $isBlueShirt) $result['clothing_count']++;
            if (($r > 220 && $g > 220 && $b > 220) || ($r < 20 && $g < 20 && $b < 20)) $result['doc_bg_count']++;
            if ($b > $r + 20 && $b > $g + 15 && $b > 100) $result['blue_count']++;
            if (abs($r - $g) < 15 && abs($g - $b) < 15 && abs($r - $b) < 15 && $r > 40 && $r < 210) $result['gray_count']++;
        }
    }
    imagedestroy($img);
    $result['rice_color_count'] = $riceColorCount;
    $ts = $result['total_samples'];
    if ($ts == 0) { $result['valid'] = true; return $result; }
    $result['ratios'] = [
        'rice_ratio'    => round($riceColorCount / $ts, 4),
        'skin_ratio'    => round($result['skin_count'] / $ts, 4),
        'dark_ratio'    => round($result['indoor_dark_count'] / $ts, 4),
        'clothing_ratio'=> round($result['clothing_count'] / $ts, 4),
        'doc_ratio'     => round($result['doc_bg_count'] / $ts, 4),
        'blue_ratio'    => round($result['blue_count'] / $ts, 4),
        'gray_ratio'    => round($result['gray_count'] / $ts, 4),
    ];
    // Apply same logic as production
    if ($result['ratios']['skin_ratio'] >= 0.035) {
        $result['valid'] = false;
        $result['reason'] = 'Skin ratio too high: ' . $result['ratios']['skin_ratio'];
    } elseif ($result['ratios']['rice_ratio'] < 0.015 || ($result['ratios']['dark_ratio'] + $result['ratios']['gray_ratio'] > 0.40 && $result['ratios']['rice_ratio'] < 0.03)) {
        $result['valid'] = false;
        $result['reason'] = 'Rice ratio too low: ' . $result['ratios']['rice_ratio'];
    } elseif ($result['ratios']['clothing_ratio'] > 0.15 && $result['ratios']['rice_ratio'] < 0.05) {
        $result['valid'] = false;
        $result['reason'] = 'Clothing ratio too high: ' . $result['ratios']['clothing_ratio'];
    } elseif ($result['ratios']['doc_ratio'] > 0.75) {
        $result['valid'] = false;
        $result['reason'] = 'Document BG ratio too high: ' . $result['ratios']['doc_ratio'];
    } elseif (($result['ratios']['blue_ratio'] + $result['ratios']['gray_ratio']) > 0.80 && $result['ratios']['rice_ratio'] < 0.02) {
        $result['valid'] = false;
        $result['reason'] = 'Blue+gray dominated: ' . ($result['ratios']['blue_ratio'] + $result['ratios']['gray_ratio']);
    } elseif ($result['ratios']['rice_ratio'] < 0.015) {
        $result['valid'] = false;
        $result['reason'] = 'Rice ratio < 0.015: ' . $result['ratios']['rice_ratio'];
    } else {
        $result['valid'] = true;
        $result['reason'] = 'OK';
    }
    return $result;
}

function callGeminiDebug($imagePath, $apiKey, $mode = 'validator') {
    $result = [
        'called'         => true,
        'api_key_len'    => strlen($apiKey),
        'api_key_prefix' => substr($apiKey, 0, 6) . '...',
        'http_code'      => 0,
        'model_used'     => null,
        'raw_text'       => null,
        'parsed'         => null,
        'curl_error'     => null,
        'latency_ms'     => 0,
        'error'          => null,
    ];
    if (empty($apiKey)) { $result['called'] = false; $result['error'] = 'No API key'; return $result; }
    if (!file_exists($imagePath)) { $result['called'] = false; $result['error'] = 'File not found'; return $result; }
    $imageData = base64_encode(file_get_contents($imagePath));
    $info = @getimagesize($imagePath);
    $mimeType = $info ? $info['mime'] : 'image/jpeg';
    if ($mode === 'validator') {
        $prompt = 'Anda adalah sistem pakar AI pertanian padi Indonesia (PadiGuard). Tentukan apakah gambar ini adalah TANAMAN PADI/SAWAH. Jawab HANYA dalam format JSON: {"is_rice_plant": true/false, "hama_name": "Wereng Coklat"|"Penggerek Batang"|"Walang Sangit"|"Ulat Grayak"|"Padi Sehat"|null, "kematangan": "Matang"|"Setengah Matang"|"Mentah", "confidence": 0.70-0.98, "reason": "alasan singkat max 10 kata"}';
    } else {
        $prompt = 'Anda adalah pakar hama padi. Analisis gambar ini. Jawab HANYA dalam format JSON: {"hama_detected": true/false, "hama_name": "Wereng Coklat"|"Walang Sangit"|"Ulat Grayak"|"Penggerek Batang"|null, "confidence": 0.60-0.92, "description": "penjelasan singkat max 20 kata"}';
    }
    $payload = ["contents" => [["parts" => [["inlineData" => ["mimeType" => $mimeType, "data" => $imageData]], ["text" => $prompt]]]], "generationConfig" => ["temperature" => 0.05, "maxOutputTokens" => 256]];
    $models = ['gemini-flash-latest', 'gemini-flash-lite-latest', 'gemini-2.5-flash'];
    foreach ($models as $model) {
        $t0 = microtime(true);
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . $apiKey);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $response = curl_exec($ch);
        $result['http_code'] = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $result['curl_error'] = curl_error($ch) ?: null;
        $result['latency_ms'] = round((microtime(true) - $t0) * 1000);
        curl_close($ch);
        $result['model_used'] = $model;
        if ($result['http_code'] === 200 && !empty($response)) break;
    }
    if ($result['http_code'] !== 200 || !$response) {
        $result['error'] = 'HTTP ' . $result['http_code'];
        $result['raw_text'] = substr($response ?: '', 0, 500);
        return $result;
    }
    $responseData = json_decode($response, true);
    $text = $responseData['candidates'][0]['content']['parts'][0]['text'] ?? '';
    $result['raw_text'] = $text;
    preg_match('/\{.*?\}/s', $text, $m);
    $result['parsed'] = !empty($m) ? json_decode($m[0], true) : null;
    return $result;
}

function callRoboflowDebug($base64Image, $apiKey, $modelId, $modelVersion) {
    $result = [
        'http_code'   => 0,
        'latency_ms'  => 0,
        'curl_error'  => null,
        'predictions' => [],
        'raw_response'=> null,
        'error'       => null,
        'model'       => "$modelId/$modelVersion",
    ];
    $url = "https://detect.roboflow.com/{$modelId}/{$modelVersion}?api_key={$apiKey}&name=image.png";
    $t0 = microtime(true);
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $base64Image);
    curl_setopt($ch, CURLOPT_TIMEOUT, 20);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $response = curl_exec($ch);
    $result['http_code'] = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $result['curl_error'] = curl_error($ch) ?: null;
    $result['latency_ms'] = round((microtime(true) - $t0) * 1000);
    curl_close($ch);
    if (!$response) { $result['error'] = 'No response'; return $result; }
    $dec = json_decode($response, true);
    $result['raw_response'] = $dec;
    if (isset($dec['predictions'])) {
        $result['predictions'] = $dec['predictions'];
    } elseif (isset($dec['error'])) {
        $result['error'] = $dec['error'];
    }
    return $result;
}

// â”€â”€â”€ MAIN: ACCEPT IMAGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$uploadDir = __DIR__ . '/uploads';
if (!file_exists($uploadDir)) mkdir($uploadDir, 0777, true);

$targetPath = '';
$newFilename = 'debug_' . uniqid() . '_' . time() . '.jpg';
$targetPath  = $uploadDir . '/' . $newFilename;

// Accept from $_FILES or raw base64
if (isset($_FILES['image']) && !empty($_FILES['image']['tmp_name'])) {
    $file = $_FILES['image'];
    $origExt = pathinfo($file['name'], PATHINFO_EXTENSION);
    if (!empty($origExt)) { $newFilename = 'debug_' . uniqid() . '_' . time() . '.' . $origExt; $targetPath = $uploadDir . '/' . $newFilename; }
    @move_uploaded_file($file['tmp_name'], $targetPath) || @copy($file['tmp_name'], $targetPath);
} else {
    $rawInput = file_get_contents('php://input');
    $inputData = json_decode($rawInput, true) ?: [];
    $b64 = $inputData['image_base64'] ?? $inputData['image'] ?? '';
    if (!empty($b64)) {
        if (preg_match('/^data:image\/(\w+);base64,/', $b64, $m)) { $b64 = substr($b64, strpos($b64, ',') + 1); $newFilename = 'debug_' . uniqid() . '.' . $m[1]; $targetPath = $uploadDir . '/' . $newFilename; }
        $bytes = base64_decode($b64);
        if ($bytes) file_put_contents($targetPath, $bytes);
    }
}

// â”€â”€â”€ LAYER 0: FILE SAVE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if (!file_exists($targetPath) || filesize($targetPath) === 0) {
    $auditLog['layers']['layer0_file_save'] = ['status' => 'failed', 'data' => ['error' => 'No image uploaded or image empty']];
    echo json_encode($auditLog, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit;
}

$imgInfo = @getimagesize($targetPath);
$auditLog['layers']['layer0_file_save'] = [
    'status' => 'ok',
    'data'   => [
        'filename'  => $newFilename,
        'path'      => $targetPath,
        'size_bytes'=> filesize($targetPath),
        'size_kb'   => round(filesize($targetPath) / 1024, 2),
        'sha256'    => hash_file('sha256', $targetPath),
        'mime'      => $imgInfo ? $imgInfo['mime'] : 'unknown',
        'width'     => $imgInfo ? $imgInfo[0] : 0,
        'height'    => $imgInfo ? $imgInfo[1] : 0,
    ],
];

$auditLog['image_info'] = $auditLog['layers']['layer0_file_save']['data'];

// â”€â”€â”€ LAYER 1: GEMINI VALIDATOR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$GEMINI_API_KEY = getenv('GEMINI_API_KEY') ?: base64_decode('QVEuQWI4Uk42SmNMMkxIWm85Z3FPaVp5UXh1QnhFNzNlOW83VG43VS1XcUhyRk9KZGRVTFE=');
$t1 = microtime(true);
$geminiValidation = callGeminiDebug($targetPath, $GEMINI_API_KEY, 'validator');
$auditLog['layers']['layer1_gemini_validator'] = [
    'status' => $geminiValidation['http_code'] === 200 ? 'ok' : 'failed',
    'data'   => $geminiValidation,
];

// â”€â”€â”€ LAYER 2: PIXEL ANALYSIS (Rice Validation) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$pixelResult = analyzeRiceValidation_debug($targetPath);
$auditLog['layers']['layer2_pixel_analysis'] = [
    'status' => $pixelResult['valid'] ? 'ok' : 'rejected',
    'data'   => $pixelResult,
];

// â”€â”€â”€ LAYER 3 & 4: ROBOFLOW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$base64Image      = base64_encode(file_get_contents($targetPath));
$rfApiKey         = 'nsRtr9srM0kLon24RWka';
$pestModelId      = 'jenis-hama-hlar6';
$pestModelVer     = '1';
$maturModelId     = 'kematangan-ieouc';
$maturModelVer    = '1';

$rfPest = callRoboflowDebug($base64Image, $rfApiKey, $pestModelId, $pestModelVer);
$auditLog['layers']['layer3_roboflow_pest'] = [
    'status' => ($rfPest['http_code'] === 200) ? 'ok' : 'failed',
    'data'   => $rfPest,
];

$rfMat = callRoboflowDebug($base64Image, $rfApiKey, $maturModelId, $maturModelVer);
$auditLog['layers']['layer4_roboflow_maturity'] = [
    'status' => ($rfMat['http_code'] === 200) ? 'ok' : 'failed',
    'data'   => $rfMat,
];

// â”€â”€â”€ LAYER 5: HASH MATCHING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$uploadedHash = getAverageHash_debug($targetPath);
$hashResult = [
    'uploaded_hash'   => $uploadedHash,
    'db_available'    => false,
    'dataset_count'   => 0,
    'best_match'      => null,
    'best_distance'   => 999,
    'threshold'       => 32,
    'matched'         => false,
    'top3_matches'    => [],
];
try {
    require_once __DIR__ . '/connection.php';
    $hashResult['db_available'] = true;
    $stmt = $pdo->query("SELECT id, label, hash FROM `dataset` WHERE hash IS NOT NULL AND hash != ''");
    $datasets = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $hashResult['dataset_count'] = count($datasets);
    $allDistances = [];
    foreach ($datasets as $ds) {
        $dist = hammingDistance_debug($uploadedHash, $ds['hash']);
        $allDistances[] = ['id' => $ds['id'], 'label' => $ds['label'], 'hash' => $ds['hash'], 'distance' => $dist];
    }
    usort($allDistances, fn($a, $b) => $a['distance'] <=> $b['distance']);
    $hashResult['top3_matches'] = array_slice($allDistances, 0, 3);
    if (!empty($allDistances) && $allDistances[0]['distance'] < $hashResult['threshold']) {
        $hashResult['matched'] = true;
        $hashResult['best_match'] = $allDistances[0];
        $hashResult['best_distance'] = $allDistances[0]['distance'];
    }
} catch (Exception $e) {
    $hashResult['error'] = $e->getMessage();
}
$auditLog['layers']['layer5_hash_matching'] = [
    'status' => $hashResult['matched'] ? 'matched' : 'no_match',
    'data'   => $hashResult,
];

// â”€â”€â”€ LAYER 6: GEMINI CROSS-CHECK (only if no pest found yet) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$allPreds = array_merge($rfPest['predictions'], $rfMat['predictions']);
$foundHama = null;
foreach ($allPreds as $pred) {
    $c = strtolower(trim($pred['class'] ?? ''));
    $conf = (float)($pred['confidence'] ?? 0);
    // Simple pest check
    if (stripos($c, 'wereng') !== false || stripos($c, 'hopper') !== false) { if ($conf >= 0.30) { $foundHama = 'Wereng Coklat'; break; } }
    if (stripos($c, 'penggerek') !== false || stripos($c, 'borer') !== false) { if ($conf >= 0.30) { $foundHama = 'Penggerek Batang'; break; } }
    if (stripos($c, 'walang') !== false) { if ($conf >= 0.30) { $foundHama = 'Walang Sangit'; break; } }
    if (stripos($c, 'grayak') !== false || stripos($c, 'army') !== false) { if ($conf >= 0.30) { $foundHama = 'Ulat Grayak'; break; } }
}

$geminiCrossCheck = null;
if ($foundHama === null) {
    $geminiCrossCheck = callGeminiDebug($targetPath, $GEMINI_API_KEY, 'crosscheck');
}
$auditLog['layers']['layer6_gemini_crosscheck'] = [
    'status' => $geminiCrossCheck ? ($geminiCrossCheck['http_code'] === 200 ? 'ok' : 'failed') : 'skipped',
    'data'   => $geminiCrossCheck ?? ['reason' => 'Pest already found by Roboflow, skipped'],
];

// â”€â”€â”€ LAYER 7: MATURITY PIXEL ANALYSIS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$maturityPixel = analyzePixels_debug($targetPath);
$auditLog['layers']['layer7_maturity_pixel'] = [
    'status' => 'ok',
    'data'   => $maturityPixel,
];

// â”€â”€â”€ FINAL RESULT SUMMARY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$finalHama = null;
$finalHamaConf = 0.0;
$finalKematangan = null;

// From Gemini validator
$gv = $auditLog['layers']['layer1_gemini_validator']['data']['parsed'] ?? null;
if ($gv && !empty($gv['hama_name']) && $gv['hama_name'] !== 'Padi Sehat') {
    $finalHama = $gv['hama_name']; $finalHamaConf = $gv['confidence'] ?? 0.88;
}
if ($gv && !empty($gv['kematangan'])) { $finalKematangan = $gv['kematangan']; }
// From Roboflow
if ($foundHama) { $finalHama = $foundHama; }
// From hash matching
if (!$finalHama && $hashResult['matched']) {
    $label = $hashResult['best_match']['label'] ?? '';
    foreach (['Wereng Coklat','Penggerek Batang','Walang Sangit','Ulat Grayak'] as $pest) {
        if (stripos($label, explode(' ', $pest)[0]) !== false) { $finalHama = $pest; break; }
    }
}
// From Gemini cross-check
if (!$finalHama && $geminiCrossCheck) {
    $gcc = $geminiCrossCheck['parsed'] ?? null;
    if ($gcc && !empty($gcc['hama_detected']) && !empty($gcc['hama_name'])) {
        $finalHama = $gcc['hama_name']; $finalHamaConf = $gcc['confidence'] ?? 0.85;
    }
}
if (!$finalKematangan) { $finalKematangan = $maturityPixel['maturity']; }

$auditLog['final_result'] = [
    'hama_detected'        => $finalHama,
    'hama_confidence'      => round($finalHamaConf, 3),
    'kematangan'           => $finalKematangan,
    'kematangan_confidence'=> 0.88,
    'source_hama'          => $foundHama ? 'roboflow' : ($gv && !empty($gv['hama_name']) && $gv['hama_name'] !== 'Padi Sehat' ? 'gemini_validator' : ($hashResult['matched'] ? 'hash_matching' : ($geminiCrossCheck ? 'gemini_crosscheck' : 'none'))),
    'source_kematangan'    => !empty($gv['kematangan']) ? 'gemini_validator' : (count($rfMat['predictions']) > 0 ? 'roboflow_maturity' : 'pixel_analysis'),
    'rice_valid_pixel'     => $pixelResult['valid'],
    'rice_valid_gemini'    => $gv ? $gv['is_rice_plant'] : null,
];

// â”€â”€â”€ DIFF FLAGS: Poin yang berpotensi beda antara lokal & Railway â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$auditLog['diff_flags'] = [
    'gemini_key_in_env'        => !empty(getenv('GEMINI_API_KEY')),
    'gemini_validator_success' => $geminiValidation['http_code'] === 200,
    'gemini_validator_latency' => $geminiValidation['latency_ms'],
    'roboflow_pest_success'    => $rfPest['http_code'] === 200,
    'roboflow_pest_latency'    => $rfPest['latency_ms'],
    'roboflow_pest_preds'      => count($rfPest['predictions']),
    'roboflow_mat_success'     => $rfMat['http_code'] === 200,
    'roboflow_mat_latency'     => $rfMat['latency_ms'],
    'roboflow_mat_preds'       => count($rfMat['predictions']),
    'hash_db_available'        => $hashResult['db_available'],
    'hash_dataset_count'       => $hashResult['dataset_count'],
    'hash_matched'             => $hashResult['matched'],
    'pixel_valid'              => $pixelResult['valid'],
    'pixel_rice_ratio'         => $pixelResult['ratios']['rice_ratio'] ?? 0,
    'maturity_pixel'           => $maturityPixel['maturity'],
    'KNOWN_BUG_riceColorCount_uninitialized' => 'In production index.php, $riceColorCount is NOT initialized before the pixel loop (line ~305-334). This causes PHP notice and may default to 0 in some configurations, making rice_ratio = 0 and rejecting all images.',
];

// Cleanup
@unlink($targetPath);

echo json_encode($auditLog, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
exit;

