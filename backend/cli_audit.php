<?php
// cli_audit.php â€” Dijalankan via PHP CLI, bukan via web server
// Tidak memerlukan Apache/Laragon. Langsung jalankan: php cli_audit.php <image_path>
// Output: JSON lengkap tiap layer ke STDOUT dan file log

error_reporting(E_ALL);
ini_set('display_errors', 1);

$imagePath = $argv[1] ?? null;
$outputFile = $argv[2] ?? null;

if (!$imagePath || !file_exists($imagePath)) {
    echo json_encode(['error' => 'Usage: php cli_audit.php <image_path> [output.json]'], JSON_PRETTY_PRINT);
    exit(1);
}

// Simulate superglobals yang dibutuhkan connection.php
$_SERVER['HTTP_HOST']       = 'localhost';
$_SERVER['SERVER_ADDR']     = '127.0.0.1';
$_SERVER['SERVER_SOFTWARE'] = 'Apache/CLI-Test';
$_SERVER['REQUEST_URI']     = '/padibackend/backend/cli_audit.php';
$_SERVER['REQUEST_METHOD']  = 'GET';
$_SERVER['HTTPS']           = 'off';

$auditLog = [
    'audit_id'   => uniqid('cli_audit_'),
    'timestamp'  => date('Y-m-d H:i:s'),
    'environment'=> [
        'type'               => 'CLI_LOCAL_LARAGON',
        'php_version'        => PHP_VERSION,
        'server_software'    => 'CLI (not web)',
        'is_railway'         => false,
        'gemini_key_in_env'  => !empty(getenv('GEMINI_API_KEY')),
        'gemini_key_len'     => strlen(getenv('GEMINI_API_KEY') ?: ''),
        'gd_available'       => extension_loaded('gd'),
        'curl_available'     => extension_loaded('curl'),
        'upload_max_filesize'=> ini_get('upload_max_filesize'),
        'memory_limit'       => ini_get('memory_limit'),
    ],
    'test_image' => [
        'path'      => $imagePath,
        'filename'  => basename($imagePath),
        'size_bytes'=> filesize($imagePath),
        'size_kb'   => round(filesize($imagePath)/1024, 2),
        'sha256'    => hash_file('sha256', $imagePath),
        'mime'      => null,
        'width'     => null,
        'height'    => null,
    ],
    'layers'     => [],
    'final_result'=> [],
    'diff_flags' => [],
];

// Image info
$imgInfo = @getimagesize($imagePath);
if ($imgInfo) {
    $auditLog['test_image']['mime']   = $imgInfo['mime'];
    $auditLog['test_image']['width']  = $imgInfo[0];
    $auditLog['test_image']['height'] = $imgInfo[1];
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// HELPER FUNCTIONS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function getAverageHash_cli($imagePath) {
    if (!file_exists($imagePath)) return null;
    $info = @getimagesize($imagePath);
    if (!$info) return null;
    $mime = $info['mime'];
    if (in_array($mime, ['image/jpeg','image/jpg'])) $img = @imagecreatefromjpeg($imagePath);
    elseif ($mime === 'image/png') $img = @imagecreatefrompng($imagePath);
    elseif ($mime === 'image/webp') $img = @imagecreatefromwebp($imagePath);
    else return null;
    if (!$img) return null;
    $resized = imagecreatetruecolor(8, 8);
    imagecopyresampled($resized, $img, 0, 0, 0, 0, 8, 8, imagesx($img), imagesy($img));
    $pixels = []; $sum = 0;
    for ($y = 0; $y < 8; $y++) for ($x = 0; $x < 8; $x++) {
        $rgb = imagecolorat($resized, $x, $y);
        $gray = round((($rgb >> 16 & 0xFF) + ($rgb >> 8 & 0xFF) + ($rgb & 0xFF)) / 3);
        $pixels[] = $gray; $sum += $gray;
    }
    $avg = $sum / 64;
    $hash = implode('', array_map(fn($p) => $p >= $avg ? '1' : '0', $pixels));
    imagedestroy($resized); imagedestroy($img);
    return $hash;
}

function hammingDist_cli($h1, $h2) {
    if (!$h1 || !$h2 || strlen($h1) !== strlen($h2)) return 999;
    $d = 0; for ($i = 0; $i < strlen($h1); $i++) if ($h1[$i] !== $h2[$i]) $d++;
    return $d;
}

function callGemini_cli($imagePath, $apiKey, $mode = 'validator') {
    $t0 = microtime(true);
    $result = [
        'called' => false, 'api_key_len' => strlen($apiKey),
        'api_key_prefix' => $apiKey ? (substr($apiKey, 0, 6) . '...') : 'EMPTY',
        'http_code' => 0, 'model_used' => null,
        'raw_text' => null, 'parsed' => null,
        'curl_error' => null, 'latency_ms' => 0, 'error' => null,
    ];
    if (empty($apiKey)) { $result['error'] = 'API key empty or missing'; return $result; }
    if (!extension_loaded('curl')) { $result['error'] = 'curl not available'; return $result; }

    $result['called'] = true;
    $imageData = base64_encode(file_get_contents($imagePath));
    $mimeType = $imgInfo['mime'] ?? 'image/jpeg';
    $info = @getimagesize($imagePath);
    if ($info) $mimeType = $info['mime'];

    $prompt = ($mode === 'validator')
        ? 'Anda adalah sistem pakar AI pertanian padi Indonesia. Tentukan apakah gambar ini adalah TANAMAN PADI/SAWAH. Jawab HANYA dalam format JSON: {"is_rice_plant": true/false, "hama_name": "Wereng Coklat"|"Penggerek Batang"|"Walang Sangit"|"Ulat Grayak"|"Padi Sehat"|null, "kematangan": "Matang"|"Setengah Matang"|"Mentah", "confidence": 0.70-0.98, "reason": "alasan singkat max 10 kata"}'
        : 'Anda adalah pakar hama padi. Analisis gambar ini. Jawab HANYA dalam format JSON: {"hama_detected": true/false, "hama_name": "Wereng Coklat"|"Walang Sangit"|"Ulat Grayak"|"Penggerek Batang"|null, "confidence": 0.60-0.92, "description": "penjelasan singkat max 20 kata"}';

    $payload = ["contents" => [["parts" => [["inlineData" => ["mimeType" => $mimeType, "data" => $imageData]], ["text" => $prompt]]]], "generationConfig" => ["temperature" => 0.05, "maxOutputTokens" => 256]];
    $models = ['gemini-2.0-flash', 'gemini-1.5-flash-latest', 'gemini-1.5-flash'];

    foreach ($models as $model) {
        $t1 = microtime(true);
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_TIMEOUT, 20);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $resp = curl_exec($ch);
        $result['http_code']   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $result['curl_error']  = curl_error($ch) ?: null;
        $result['latency_ms']  = round((microtime(true) - $t1) * 1000);
        $result['model_used']  = $model;
        curl_close($ch);
        if ($result['http_code'] === 200 && !empty($resp)) break;
    }
    $result['total_latency_ms'] = round((microtime(true) - $t0) * 1000);
    if ($result['http_code'] !== 200 || empty($resp)) {
        $result['error'] = "HTTP {$result['http_code']}";
        $result['raw_response_snippet'] = substr($resp ?: '', 0, 300);
        return $result;
    }
    $data = json_decode($resp, true);
    $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    $result['raw_text'] = $text;
    preg_match('/\{.*?\}/s', $text, $m);
    $result['parsed'] = !empty($m) ? json_decode($m[0], true) : null;
    return $result;
}

function callRoboflow_cli($base64Image, $apiKey, $modelId, $version) {
    $t0 = microtime(true);
    $result = [
        'model' => "$modelId/$version", 'http_code' => 0,
        'latency_ms' => 0, 'curl_error' => null,
        'predictions' => [], 'raw_response' => null, 'error' => null,
    ];
    $url = "https://detect.roboflow.com/{$modelId}/{$version}?api_key={$apiKey}&name=image.png";
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $base64Image);
    curl_setopt($ch, CURLOPT_TIMEOUT, 25);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $resp = curl_exec($ch);
    $result['http_code']  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $result['curl_error'] = curl_error($ch) ?: null;
    $result['latency_ms'] = round((microtime(true) - $t0) * 1000);
    curl_close($ch);
    if (!$resp) { $result['error'] = 'Empty response'; return $result; }
    $dec = json_decode($resp, true);
    $result['raw_response'] = $dec;
    $result['predictions']  = $dec['predictions'] ?? [];
    if (isset($dec['error'])) $result['error'] = $dec['error'];
    return $result;
}

function analyzePixels_cli($imagePath) {
    $r = ['green' => 0, 'yellow' => 0, 'total' => 0, 'yellow_ratio' => 0.0, 'maturity' => 'unknown', 'error' => null];
    if (!file_exists($imagePath)) { $r['error'] = 'file not found'; return $r; }
    $info = @getimagesize($imagePath);
    if (!$info) { $r['error'] = 'invalid image'; return $r; }
    $mime = $info['mime'];
    if (in_array($mime, ['image/jpeg','image/jpg'])) $img = @imagecreatefromjpeg($imagePath);
    elseif ($mime === 'image/png') $img = @imagecreatefrompng($imagePath);
    elseif ($mime === 'image/webp') $img = @imagecreatefromwebp($imagePath);
    else { $r['error'] = 'unsupported format'; return $r; }
    if (!$img) { $r['error'] = 'failed to open'; return $r; }
    $w = imagesx($img); $h = imagesy($img);
    $stepX = max(1, (int)($w / 30)); $stepY = max(1, (int)($h / 30));
    for ($x = 0; $x < $w; $x += $stepX) for ($y = 0; $y < $h; $y += $stepY) {
        $r['total']++;
        $rgb = @imagecolorat($img, $x, $y);
        if ($rgb === false) continue;
        $rv = ($rgb >> 16) & 0xFF; $g = ($rgb >> 8) & 0xFF; $b = $rgb & 0xFF;
        if ($g > $rv && $g > $b && ($g - $rv) > 12) $r['green']++;
        elseif ($rv > 120 && $g > 110 && ($rv - $b) > 35 && ($g - $b) > 25 && abs($rv - $g) < 40) $r['yellow']++;
    }
    imagedestroy($img);
    $total = $r['green'] + $r['yellow'];
    if ($total < 15) { $r['maturity'] = 'Mentah'; return $r; }
    $yr = $r['yellow'] / $total;
    $r['yellow_ratio'] = round($yr, 4);
    if ($yr > 0.65) $r['maturity'] = 'Matang';
    elseif ($yr < 0.35 || $r['green'] >= $r['yellow'] * 1.5) $r['maturity'] = 'Mentah';
    else $r['maturity'] = 'Setengah Matang';
    return $r;
}

function analyzeRicePixels_cli($imagePath) {
    // Reproduce exact isRicePlantImage() logic including the bug check
    $r = [
        'valid' => false, 'reason' => '',
        'bug_riceColorCount_uninitialized' => true, // Flag the known bug
        'rice_count_with_init' => 0,   // What the value IS (correct)
        'rice_count_without_init' => 0, // What it would be if NOT initialized (same in PHP 8 = 0 with notice)
        'skin_count' => 0, 'dark_count' => 0, 'clothing_count' => 0,
        'doc_count' => 0, 'blue_count' => 0, 'gray_count' => 0, 'total' => 0,
        'ratios' => [], 'decision_path' => []
    ];
    if (!file_exists($imagePath)) { $r['reason'] = 'file not found'; return $r; }
    $info = @getimagesize($imagePath);
    if (!$info) { $r['reason'] = 'invalid image'; return $r; }
    $mime = $info['mime'];
    if (in_array($mime, ['image/jpeg','image/jpg'])) $img = @imagecreatefromjpeg($imagePath);
    elseif ($mime === 'image/png') $img = @imagecreatefrompng($imagePath);
    elseif ($mime === 'image/webp') $img = @imagecreatefromwebp($imagePath);
    else { $r['reason'] = 'unsupported format'; return $r; }
    if (!$img) { $r['reason'] = 'failed to open'; return $r; }
    $w = imagesx($img); $h = imagesy($img);
    $stepX = max(1, (int)($w / 60)); $stepY = max(1, (int)($h / 60));
    $rice = 0;
    for ($x = 0; $x < $w; $x += $stepX) for ($y = 0; $y < $h; $y += $stepY) {
        $r['total']++;
        $rgb = @imagecolorat($img, $x, $y);
        if ($rgb === false) continue;
        $rv = ($rgb >> 16) & 0xFF; $g = ($rgb >> 8) & 0xFF; $b = $rgb & 0xFF;
        $isGreenPadi  = ($g > $rv && $g > $b + 8 && $g > 35);
        $isYellowPadi = ($rv > 90 && $g > 80 && $b < 140 && ($rv - $b) > 25 && ($g - $b) > 15 && abs($rv - $g) < 45);
        $isDryPadi    = ($rv > 70 && $g > 55 && $b < 105 && $rv > $b + 18 && ($rv - $g) < 30 && ($g - $b) > 8);
        if ($isGreenPadi || $isYellowPadi || $isDryPadi) $rice++;
        $cb = 128 - 0.168736 * $rv - 0.331264 * $g + 0.5 * $b;
        $cr = 128 + 0.418688 * $rv - 0.345842 * $g - 0.072846 * $b;
        if (($rv > 60 && $g > 35 && $b > 20 && $rv > $g && $g > $b && ($rv - $g) >= 8) || ($cb >= 77 && $cb <= 130 && $cr >= 130 && $cr <= 180)) $r['skin_count']++;
        if ($rv < 55 && $g < 55 && $b < 55) $r['dark_count']++;
        if (($rv > 160 && $g < 70 && $b < 70) || ($b > 130 && $b > $rv + 30 && $b > $g + 30)) $r['clothing_count']++;
        if (($rv > 220 && $g > 220 && $b > 220) || ($rv < 20 && $g < 20 && $b < 20)) $r['doc_count']++;
        if ($b > $rv + 20 && $b > $g + 15 && $b > 100) $r['blue_count']++;
        if (abs($rv - $g) < 15 && abs($g - $b) < 15 && abs($rv - $b) < 15 && $rv > 40 && $rv < 210) $r['gray_count']++;
    }
    imagedestroy($img);
    $r['rice_count_with_init'] = $rice;
    $ts = $r['total'] ?: 1;
    $r['ratios'] = [
        'rice'    => round($rice / $ts, 4),
        'skin'    => round($r['skin_count'] / $ts, 4),
        'dark'    => round($r['dark_count'] / $ts, 4),
        'clothing'=> round($r['clothing_count'] / $ts, 4),
        'doc'     => round($r['doc_count'] / $ts, 4),
        'blue'    => round($r['blue_count'] / $ts, 4),
        'gray'    => round($r['gray_count'] / $ts, 4),
    ];
    // Decision logic (mirrors production)
    if ($r['ratios']['skin'] >= 0.035) {
        $r['valid'] = false; $r['reason'] = "REJECT: skin_ratio={$r['ratios']['skin']} >= 0.035";
        $r['decision_path'][] = "A_SKIN_REJECT";
    } elseif ($r['ratios']['rice'] < 0.015 || ($r['ratios']['dark'] + $r['ratios']['gray'] > 0.40 && $r['ratios']['rice'] < 0.03)) {
        $r['valid'] = false; $r['reason'] = "REJECT: rice_ratio={$r['ratios']['rice']} < 0.015";
        $r['decision_path'][] = "B_RICE_TOO_LOW";
    } elseif ($r['ratios']['clothing'] > 0.15 && $r['ratios']['rice'] < 0.05) {
        $r['valid'] = false; $r['reason'] = "REJECT: clothing_ratio={$r['ratios']['clothing']} > 0.15";
        $r['decision_path'][] = "C_CLOTHING_REJECT";
    } elseif ($r['ratios']['doc'] > 0.75) {
        $r['valid'] = false; $r['reason'] = "REJECT: doc_ratio={$r['ratios']['doc']} > 0.75";
        $r['decision_path'][] = "D_DOCUMENT_REJECT";
    } elseif ($r['ratios']['blue'] + $r['ratios']['gray'] > 0.80 && $r['ratios']['rice'] < 0.02) {
        $r['valid'] = false; $r['reason'] = "REJECT: blue+gray={$r['ratios']['blue']} + {$r['ratios']['gray']} > 0.80";
        $r['decision_path'][] = "E_BLUE_GRAY_REJECT";
    } elseif ($r['ratios']['rice'] < 0.015) {
        $r['valid'] = false; $r['reason'] = "REJECT: rice_ratio={$r['ratios']['rice']} < 0.015 (second check)";
        $r['decision_path'][] = "F_RICE_SECOND_REJECT";
    } else {
        $r['valid'] = true; $r['reason'] = "VALID: rice_ratio={$r['ratios']['rice']}";
        $r['decision_path'][] = "G_VALID";
    }
    return $r;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RUN LAYERS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

$GEMINI_KEY = getenv('GEMINI_API_KEY') ?: getenv('GEMINI_API_KEY');
$RF_KEY     = 'nsRtr9srM0kLon24RWka';

// Layer 1: Gemini Validator
echo "[" . date('H:i:s') . "] Running Layer 1: Gemini Validator...\n";
$gv = callGemini_cli($imagePath, $GEMINI_KEY, 'validator');
$auditLog['layers']['L1_gemini_validator'] = ['status' => $gv['http_code'] === 200 ? 'ok' : 'failed', 'data' => $gv];

// Layer 2: Pixel analysis (rice validation)
echo "[" . date('H:i:s') . "] Running Layer 2: Pixel Rice Validation...\n";
$pix = analyzeRicePixels_cli($imagePath);
$auditLog['layers']['L2_pixel_rice_validation'] = ['status' => $pix['valid'] ? 'valid' : 'rejected', 'data' => $pix];

// Layer 3: Roboflow Pest
echo "[" . date('H:i:s') . "] Running Layer 3: Roboflow Pest Detection...\n";
$b64 = base64_encode(file_get_contents($imagePath));
$rfPest = callRoboflow_cli($b64, $RF_KEY, 'jenis-hama-hlar6', '1');
$auditLog['layers']['L3_roboflow_pest'] = ['status' => $rfPest['http_code'] === 200 ? 'ok' : 'failed', 'data' => $rfPest];

// Layer 4: Roboflow Maturity
echo "[" . date('H:i:s') . "] Running Layer 4: Roboflow Maturity Detection...\n";
$rfMat = callRoboflow_cli($b64, $RF_KEY, 'kematangan-ieouc', '1');
$auditLog['layers']['L4_roboflow_maturity'] = ['status' => $rfMat['http_code'] === 200 ? 'ok' : 'failed', 'data' => $rfMat];

// Layer 5: Hash Matching (DB)
echo "[" . date('H:i:s') . "] Running Layer 5: Hash Matching (DB)...\n";
$uploadedHash = getAverageHash_cli($imagePath);
$hashResult = [
    'uploaded_hash' => $uploadedHash,
    'db_available'  => false,
    'dataset_count' => 0,
    'matched'       => false,
    'best_distance' => 999,
    'threshold'     => 32,
    'top3'          => [],
    'error'         => null,
];
try {
    require_once __DIR__ . '/connection.php';
    $hashResult['db_available'] = true;
    $stmt = $pdo->query("SELECT id, label, hash FROM `dataset` WHERE hash IS NOT NULL AND hash != ''");
    $ds = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $hashResult['dataset_count'] = count($ds);
    $dists = [];
    foreach ($ds as $d) { $dists[] = ['id' => $d['id'], 'label' => $d['label'], 'distance' => hammingDist_cli($uploadedHash, $d['hash'])]; }
    usort($dists, fn($a,$b) => $a['distance'] <=> $b['distance']);
    $hashResult['top3'] = array_slice($dists, 0, 3);
    if (!empty($dists) && $dists[0]['distance'] < 32) {
        $hashResult['matched'] = true;
        $hashResult['best_match'] = $dists[0];
        $hashResult['best_distance'] = $dists[0]['distance'];
    }
} catch (Exception $e) { $hashResult['error'] = $e->getMessage(); }
$auditLog['layers']['L5_hash_matching'] = ['status' => $hashResult['matched'] ? 'matched' : 'no_match', 'data' => $hashResult];

// Layer 6: Gemini Cross-check (if no pest from Roboflow)
$allPreds = array_merge($rfPest['predictions'], $rfMat['predictions']);
$foundHama = null;
foreach ($allPreds as $pred) {
    $c = strtolower($pred['class'] ?? ''); $conf = (float)($pred['confidence'] ?? 0);
    if ($conf < 0.30) continue;
    if (stripos($c, 'wereng') !== false || stripos($c, 'hopper') !== false) { $foundHama = 'Wereng Coklat'; break; }
    if (stripos($c, 'penggerek') !== false || stripos($c, 'borer') !== false) { $foundHama = 'Penggerek Batang'; break; }
    if (stripos($c, 'walang') !== false) { $foundHama = 'Walang Sangit'; break; }
    if (stripos($c, 'grayak') !== false || stripos($c, 'army') !== false) { $foundHama = 'Ulat Grayak'; break; }
}

$gcc = null;
if ($foundHama === null) {
    echo "[" . date('H:i:s') . "] Running Layer 6: Gemini Cross-check (no pest from Roboflow)...\n";
    $gcc = callGemini_cli($imagePath, $GEMINI_KEY, 'crosscheck');
} else {
    echo "[" . date('H:i:s') . "] Layer 6: SKIPPED (pest found by Roboflow: $foundHama)\n";
}
$auditLog['layers']['L6_gemini_crosscheck'] = [
    'status' => $gcc ? ($gcc['http_code'] === 200 ? 'ok' : 'failed') : 'skipped',
    'data'   => $gcc ?? ['reason' => "Skipped â€” Roboflow found: $foundHama"],
];

// Layer 7: Maturity pixel analysis
echo "[" . date('H:i:s') . "] Running Layer 7: Maturity Pixel Analysis...\n";
$matPix = analyzePixels_cli($imagePath);
$auditLog['layers']['L7_maturity_pixel'] = ['status' => 'ok', 'data' => $matPix];

// â”€â”€â”€ FINAL RESULT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$gvParsed = $gv['parsed'] ?? null;
$finalHama = $foundHama;
$finalHamaConf = 0.0;
$finalKematangan = null;
$finalKematanganConf = 0.88;
$hamaSource = 'none';
$kematanganSource = 'none';

if (!$finalHama && $gvParsed && !empty($gvParsed['hama_name']) && $gvParsed['hama_name'] !== 'Padi Sehat') {
    $finalHama = $gvParsed['hama_name'];
    $finalHamaConf = $gvParsed['confidence'] ?? 0.88;
    $hamaSource = 'gemini_validator';
} elseif ($foundHama) {
    $hamaSource = 'roboflow';
    foreach ($allPreds as $pred) {
        if (stripos($pred['class'] ?? '', $foundHama[0]) !== false) { $finalHamaConf = $pred['confidence'] ?? 0.85; break; }
    }
}
if (!$finalHama && $hashResult['matched']) {
    $label = $hashResult['best_match']['label'] ?? '';
    foreach (['Wereng Coklat','Penggerek Batang','Walang Sangit','Ulat Grayak'] as $p) {
        if (stripos($label, explode(' ',$p)[0]) !== false) { $finalHama = $p; $finalHamaConf = 0.87; $hamaSource = 'hash_matching'; break; }
    }
}
if (!$finalHama && $gcc) {
    $gccP = $gcc['parsed'] ?? null;
    if ($gccP && !empty($gccP['hama_detected']) && !empty($gccP['hama_name'])) {
        $finalHama = $gccP['hama_name']; $finalHamaConf = $gccP['confidence'] ?? 0.85;
        $hamaSource = 'gemini_crosscheck';
    }
}
if ($gvParsed && !empty($gvParsed['kematangan'])) { $finalKematangan = $gvParsed['kematangan']; $kematanganSource = 'gemini_validator'; }
if (!$finalKematangan) {
    foreach ($rfMat['predictions'] as $pred) {
        $c = strtolower($pred['class'] ?? ''); $conf = $pred['confidence'] ?? 0;
        if ($conf >= 0.25) {
            if (stripos($c, 'matang') !== false && stripos($c, 'setengah') !== false) { $finalKematangan = 'Setengah Matang'; $kematanganSource = 'roboflow_maturity'; break; }
            if (stripos($c, 'matang') !== false) { $finalKematangan = 'Matang'; $kematanganSource = 'roboflow_maturity'; break; }
            if (stripos($c, 'mentah') !== false) { $finalKematangan = 'Mentah'; $kematanganSource = 'roboflow_maturity'; break; }
        }
    }
}
if (!$finalKematangan) { $finalKematangan = $matPix['maturity']; $kematanganSource = 'pixel_analysis'; }

$auditLog['final_result'] = [
    'hama'                 => $finalHama,
    'hama_confidence'      => round($finalHamaConf, 3),
    'hama_source'          => $hamaSource,
    'kematangan'           => $finalKematangan,
    'kematangan_confidence'=> $finalKematanganConf,
    'kematangan_source'    => $kematanganSource,
    'gemini_is_rice_plant' => $gvParsed['is_rice_plant'] ?? null,
    'pixel_is_valid'       => $pix['valid'],
];

$auditLog['diff_flags'] = [
    'gemini_key_configured'     => strlen($GEMINI_KEY) > 10,
    'gemini_key_from_env'       => !empty(getenv('GEMINI_API_KEY')),
    'gemini_validator_ok'       => $gv['http_code'] === 200,
    'gemini_validator_latency'  => $gv['latency_ms'],
    'roboflow_pest_ok'          => $rfPest['http_code'] === 200,
    'roboflow_pest_latency'     => $rfPest['latency_ms'],
    'roboflow_pest_pred_count'  => count($rfPest['predictions']),
    'roboflow_mat_ok'           => $rfMat['http_code'] === 200,
    'roboflow_mat_latency'      => $rfMat['latency_ms'],
    'roboflow_mat_pred_count'   => count($rfMat['predictions']),
    'db_available'              => $hashResult['db_available'],
    'dataset_count_with_hash'   => $hashResult['dataset_count'],
    'hash_matched'              => $hashResult['matched'],
    'pixel_rice_ratio'          => $pix['ratios']['rice'] ?? 0,
    'pixel_valid'               => $pix['valid'],
    'KNOWN_BUG'                 => '$riceColorCount not initialized before pixel loop in production index.php',
];

echo "\n=== AUDIT COMPLETE ===\n";
$json = json_encode($auditLog, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
echo $json . "\n";

if ($outputFile) {
    file_put_contents($outputFile, $json);
    echo "\n[Saved to: $outputFile]\n";
}


