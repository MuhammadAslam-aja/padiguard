<?php
// benchmark_suite.php - PadiGuard Accuracy & Latency Evaluation Suite
// Menguji minimal 50 gambar real dari folder 'Gambar Padi' dan dataset sample
// Menghitung Accuracy, Precision, Recall, F1-Score, Confusion Matrix, dan Latency.

error_reporting(E_ALL & ~E_DEPRECATED);
ini_set('display_errors', 0);
date_default_timezone_set('Asia/Jakarta');

require_once __DIR__ . '/connection.php';

$targetUrl = $argv[1] ?? 'http://localhost/padibackend/backend/api/detection';
$isRailway = (strpos($targetUrl, 'railway') !== false);
$outputJson = $argv[2] ?? (__DIR__ . '/' . ($isRailway ? 'benchmark_railway.json' : 'benchmark_local.json'));

echo "=========================================================================\n";
echo "           PADIGUARD BENCHMARK SUITE (Accuracy & Parity)               \n";
echo " Target URL : $targetUrl\n";
echo " Mode       : " . ($isRailway ? "RAILWAY PRODUCTION" : "LOCAL LARAGON") . "\n";
echo " Time       : " . date('Y-m-d H:i:s') . "\n";
echo "=========================================================================\n\n";

// Kumpulkan 50+ gambar uji dari folder "Gambar Padi"
$baseDir = dirname(__DIR__);
$datasetDirs = [
    'Wereng Coklat'    => "$baseDir/Gambar Padi/Hama/wareng",
    'Penggerek Batang' => "$baseDir/Gambar Padi/Hama/penggerek batang",
    'Padi Sehat'       => "$baseDir/Gambar Padi/Hama/padi sehat",
    'Matang'           => "$baseDir/Gambar Padi/kematangan/Matang",
    'Mentah'           => "$baseDir/Gambar Padi/kematangan/Mentah",
    'Setengah Matang'  => "$baseDir/Gambar Padi/kematangan/Setengah Matang",
];

$testSamples = [];
$totalCollected = 0;

foreach ($datasetDirs as $expectedLabel => $dirPath) {
    if (!file_exists($dirPath)) continue;
    $files = glob("$dirPath/*.{jpg,jpeg,png,JPG,JPEG,PNG}", GLOB_BRACE);
    if (!$files) continue;
    
    // Ambil hingga 10 gambar per kategori
    $selected = array_slice($files, 0, 10);
    foreach ($selected as $f) {
        $testSamples[] = [
            'path'     => $f,
            'filename' => basename($f),
            'expected' => $expectedLabel,
            'category' => in_array($expectedLabel, ['Wereng Coklat','Penggerek Batang','Walang Sangit','Ulat Grayak']) ? 'hama' : ($expectedLabel === 'Padi Sehat' ? 'sehat' : 'kematangan')
        ];
        $totalCollected++;
    }
}

// Tambahkan sample tambahan jika kurang dari 50
if ($totalCollected < 50) {
    $samplesDir = __DIR__ . '/dataset_samples';
    if (file_exists($samplesDir)) {
        $extraFiles = glob("$samplesDir/*.{jpg,jpeg,png}", GLOB_BRACE);
        foreach ($extraFiles as $ef) {
            if ($totalCollected >= 60) break;
            $fn = strtolower(basename($ef));
            $exp = 'Padi Sehat';
            if (strpos($fn, 'wereng') !== false) $exp = 'Wereng Coklat';
            elseif (strpos($fn, 'penggerek') !== false) $exp = 'Penggerek Batang';
            elseif (strpos($fn, 'matang_-_sehat') !== false) $exp = 'Matang';
            elseif (strpos($fn, 'mentah_-_sehat') !== false) $exp = 'Mentah';
            elseif (strpos($fn, 'setengah') !== false) $exp = 'Setengah Matang';

            $testSamples[] = [
                'path'     => $ef,
                'filename' => basename($ef),
                'expected' => $exp,
                'category' => in_array($exp, ['Wereng Coklat','Penggerek Batang']) ? 'hama' : ($exp === 'Padi Sehat' ? 'sehat' : 'kematangan')
            ];
            $totalCollected++;
        }
    }
}

echo "Total Gambar Uji Terkumpul: " . count($testSamples) . " gambar\n";
echo "Memulai pengujian inferensi...\n\n";

$results = [];
$confusionMatrix = [
    'TP' => 0, // True Positive (Hama/Kematangan terdeteksi dengan benar)
    'TN' => 0, // True Negative (Padi sehat terdeteksi sebagai Aman/Sehat)
    'FP' => 0, // False Positive (Padi sehat salah terdeteksi hama, atau hama salah kelas)
    'FN' => 0, // False Negative (Hama tidak terdeteksi / terlewat)
];

$classStats = [
    'Wereng Coklat'    => ['tp' => 0, 'fp' => 0, 'fn' => 0],
    'Penggerek Batang' => ['tp' => 0, 'fp' => 0, 'fn' => 0],
    'Padi Sehat'       => ['tp' => 0, 'fp' => 0, 'fn' => 0],
    'Matang'           => ['tp' => 0, 'fp' => 0, 'fn' => 0],
    'Mentah'           => ['tp' => 0, 'fp' => 0, 'fn' => 0],
    'Setengah Matang'  => ['tp' => 0, 'fp' => 0, 'fn' => 0],
];

$totalLatency = 0;
$successfulRequests = 0;

foreach ($testSamples as $idx => $sample) {
    $num = $idx + 1;
    $imgPath = $sample['path'];
    $expected = $sample['expected'];
    
    $imageBytes = file_get_contents($imgPath);
    $boundary = 'BenchmarkBoundary' + md5($imgPath);
    $nl = "\r\n";
    $header  = "--$boundary$nl";
    $header .= "Content-Disposition: form-data; name=\"image\"; filename=\"" . basename($imgPath) . "\"$nl";
    $header .= "Content-Type: image/jpeg$nl$nl";
    $footer  = "$nl--$boundary--$nl";
    
    $body = $header . $imageBytes . $footer;
    
    $t0 = microtime(true);
    $ch = curl_init($targetUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: multipart/form-data; boundary=$boundary"]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $latencyMs = round((microtime(true) - $t0) * 1000);
    curl_close($ch);
    
    $detectedHama = null;
    $detectedKematangan = null;
    $isCorrect = false;
    $statusText = "FAIL";
    
    if ($httpCode === 200 || $httpCode === 201) {
        $dec = json_decode($response, true);
        if (isset($dec['detection'])) {
            $det = $dec['detection'];
            $detectedHama = $det['hamaName'] ?? null;
            $detectedKematangan = $det['kematangan'] ?? null;
            $successfulRequests++;
            $totalLatency += $latencyMs;
            
            // Evaluasi Kebenaran
            if ($sample['category'] === 'hama') {
                if ($detectedHama === $expected) {
                    $isCorrect = true;
                    $confusionMatrix['TP']++;
                    if (isset($classStats[$expected])) $classStats[$expected]['tp']++;
                } else {
                    $confusionMatrix['FN']++;
                    if (isset($classStats[$expected])) $classStats[$expected]['fn']++;
                    if ($detectedHama !== null && isset($classStats[$detectedHama])) $classStats[$detectedHama]['fp']++;
                }
            } elseif ($sample['category'] === 'sehat') {
                if ($detectedHama === null) {
                    $isCorrect = true;
                    $confusionMatrix['TN']++;
                    if (isset($classStats['Padi Sehat'])) $classStats['Padi Sehat']['tp']++;
                } else {
                    $confusionMatrix['FP']++;
                    if (isset($classStats['Padi Sehat'])) $classStats['Padi Sehat']['fn']++;
                    if (isset($classStats[$detectedHama])) $classStats[$detectedHama]['fp']++;
                }
            } elseif ($sample['category'] === 'kematangan') {
                if ($detectedKematangan === $expected) {
                    $isCorrect = true;
                    $confusionMatrix['TP']++;
                    if (isset($classStats[$expected])) $classStats[$expected]['tp']++;
                } else {
                    $confusionMatrix['FN']++;
                    if (isset($classStats[$expected])) $classStats[$expected]['fn']++;
                    if ($detectedKematangan !== null && isset($classStats[$detectedKematangan])) $classStats[$detectedKematangan]['fp']++;
                }
            }
        }
    }
    
    $statusText = $isCorrect ? "✓ MATCH" : "✗ MISMATCH";
    $actualStr = $detectedHama ? "Hama: $detectedHama" : "Kem: $detectedKematangan (Aman)";
    
    printf("[%02d/%02d] %-30s | Exp: %-16s | Act: %-22s | %-8s | %4d ms\n", 
        $num, count($testSamples), substr($sample['filename'], 0, 30), 
        $expected, $actualStr, $statusText, $latencyMs
    );
    
    $results[] = [
        'sample'      => $sample['filename'],
        'expected'    => $expected,
        'detected_hama' => $detectedHama,
        'detected_kematangan' => $detectedKematangan,
        'is_correct'  => $isCorrect,
        'latency_ms'  => $latencyMs,
        'http_code'   => $httpCode
    ];
}

// Determinism Check: Panggil gambar pertama 2x untuk memverifikasi 100% konsistensi
$determinismPassed = false;
if (!empty($testSamples)) {
    $firstImg = $testSamples[0]['path'];
    $b1 = file_get_contents($firstImg);
    $bnd = 'DetCheck' . time();
    $bdy = "--$bnd\r\nContent-Disposition: form-data; name=\"image\"; filename=\"test.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n" . $b1 . "\r\n--$bnd--\r\n";
    
    $ch1 = curl_init($targetUrl);
    curl_setopt($ch1, CURLOPT_RETURNTRANSFER, true); curl_setopt($ch1, CURLOPT_POST, true);
    curl_setopt($ch1, CURLOPT_POSTFIELDS, $bdy);
    curl_setopt($ch1, CURLOPT_HTTPHEADER, ["Content-Type: multipart/form-data; boundary=$bnd"]);
    curl_setopt($ch1, CURLOPT_SSL_VERIFYPEER, false);
    $r1 = curl_exec($ch1); curl_close($ch1);
    
    $ch2 = curl_init($targetUrl);
    curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true); curl_setopt($ch2, CURLOPT_POST, true);
    curl_setopt($ch2, CURLOPT_POSTFIELDS, $bdy);
    curl_setopt($ch2, CURLOPT_HTTPHEADER, ["Content-Type: multipart/form-data; boundary=$bnd"]);
    curl_setopt($ch2, CURLOPT_SSL_VERIFYPEER, false);
    $r2 = curl_exec($ch2); curl_close($ch2);
    
    $d1 = json_decode($r1, true)['detection'] ?? null;
    $d2 = json_decode($r2, true)['detection'] ?? null;
    
    if ($d1 && $d2 && $d1['hamaName'] === $d2['hamaName'] && $d1['kematangan'] === $d2['kematangan'] && $d1['hamaConfidence'] === $d2['hamaConfidence']) {
        $determinismPassed = true;
    }
}

// Hitung Metrik Evaluasi akhir
$totalSamplesCount = count($testSamples);
$correctCount = array_reduce($results, fn($carry, $item) => $carry + ($item['is_correct'] ? 1 : 0), 0);

$accuracy  = $totalSamplesCount > 0 ? round(($correctCount / $totalSamplesCount) * 100, 2) : 0;
$precision = ($confusionMatrix['TP'] + $confusionMatrix['FP']) > 0 ? round(($confusionMatrix['TP'] / ($confusionMatrix['TP'] + $confusionMatrix['FP'])) * 100, 2) : 0;
$recall    = ($confusionMatrix['TP'] + $confusionMatrix['FN']) > 0 ? round(($confusionMatrix['TP'] / ($confusionMatrix['TP'] + $confusionMatrix['FN'])) * 100, 2) : 0;
$f1Score   = ($precision + $recall) > 0 ? round(2 * (($precision * $recall) / ($precision + $recall)), 2) : 0;
$avgLatency = $successfulRequests > 0 ? round($totalLatency / $successfulRequests) : 0;

echo "\n=========================================================================\n";
echo "                      FINAL BENCHMARK SUMMARY                           \n";
echo "=========================================================================\n";
echo " Total Tested         : $totalSamplesCount gambar\n";
echo " Correct Predictions  : $correctCount / $totalSamplesCount\n";
echo " Accuracy             : $accuracy %\n";
echo " Precision            : $precision %\n";
echo " Recall               : $recall %\n";
echo " F1-Score             : $f1Score %\n";
echo " Avg Latency          : $avgLatency ms (" . round($avgLatency/1000, 2) . " s)\n";
echo " Deterministic Output : " . ($determinismPassed ? "PASSED 100% (Identical)" : "FAILED") . "\n";
echo " Confusion Matrix     : TP={$confusionMatrix['TP']}, TN={$confusionMatrix['TN']}, FP={$confusionMatrix['FP']}, FN={$confusionMatrix['FN']}\n";
echo "=========================================================================\n\n";

$summaryData = [
    'target_url'       => $targetUrl,
    'environment'      => $isRailway ? 'railway' : 'local',
    'timestamp'        => date('Y-m-d H:i:s'),
    'metrics' => [
        'total_tested' => $totalSamplesCount,
        'correct'      => $correctCount,
        'accuracy'     => $accuracy,
        'precision'    => $precision,
        'recall'       => $recall,
        'f1_score'     => $f1Score,
        'avg_latency_ms'=> $avgLatency,
        'determinism_passed' => $determinismPassed,
    ],
    'confusion_matrix' => $confusionMatrix,
    'class_stats'      => $classStats,
    'details'          => $results
];

file_put_contents($outputJson, json_encode($summaryData, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
echo "✓ Saved full benchmark report to: $outputJson\n";
