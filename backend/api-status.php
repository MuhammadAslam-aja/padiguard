<?php
/**
 * PadiGuard - Halaman Status API (Roboflow + Gemini)
 * Dapat dibuka langsung di browser untuk verifikasi koneksi AI.
 */
date_default_timezone_set('Asia/Jakarta');
error_reporting(0);
ini_set('display_errors', 0);

// ── Helper: baca .env dari parent dir ───────────────────────────────────────
function loadEnv($path) {
    if (!file_exists($path)) return;
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        [$key, $val] = explode('=', $line, 2);
        $_ENV[trim($key)] = trim($val);
        putenv(trim($key) . '=' . trim($val));
    }
}
loadEnv(__DIR__ . '/../.env');
loadEnv(__DIR__ . '/../yolov12n/model_config.env');

$RF_KEY       = getenv('ROBOFLOW_API_KEY') ?: 'nsRtr9srM0kLon24RWka';
$GEMINI_KEY   = getenv('GEMINI_API_KEY') ?: base64_decode('QVEuQWI4Uk42SmNMMkxIWm85Z3FPaVp5UXh1QnhFNzNlOW83VG43VS1XcUhyRk9KZGRVTFE=');

$MODELS = [
    [
        'label'    => 'Deteksi Hama Padi (YOLOv12n)',
        'icon'     => '🐛',
        'endpoint' => 'https://detect.roboflow.com/jenis-hama-hlar6/1',
        'key'      => $RF_KEY,
        'type'     => 'roboflow',
        'perf'     => 'mAP@50: 96.0% · Precision: 94.2% · Recall: 95.0%',
        'classes'  => ['Wereng Coklat', 'Walang Sangit', 'Penggerek Batang', 'Ulat Grayak'],
    ],
    [
        'label'    => 'Deteksi Kematangan Padi (YOLOv12n)',
        'icon'     => '🌾',
        'endpoint' => 'https://detect.roboflow.com/kematangan-ieouc/1',
        'key'      => $RF_KEY,
        'type'     => 'roboflow',
        'perf'     => 'Model: kematangan-ieouc v1',
        'classes'  => ['Matang', 'Setengah Matang', 'Mentah'],
    ],
    [
        'label'    => 'Gemini Vision AI',
        'icon'     => '✨',
        'endpoint' => 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=' . $GEMINI_KEY,
        'key'      => $GEMINI_KEY,
        'type'     => 'gemini',
        'perf'     => 'Cross-validator & Rice Plant Detector',
        'classes'  => ['Rice Validator', 'Pest Cross-Check', 'Maturity Analysis'],
    ],
];

// ── Ping endpoint Roboflow ───────────────────────────────────────────────────
function pingRoboflow($endpoint, $apiKey) {
    $url = $endpoint . '?api_key=' . $apiKey . '&name=ping.jpg';
    $ch  = curl_init();
    // Kirim request ke endpoint tanpa gambar → hasilnya 400 (expected) bukan 401
    curl_setopt_array($ch, [
        CURLOPT_URL            => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => '',
        CURLOPT_TIMEOUT        => 8,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded'],
    ]);
    $body = curl_exec($ch);
    $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err  = curl_error($ch);
    curl_close($ch);

    $data = json_decode($body, true);
    // 400 = model found, key valid, but no image → model is ACTIVE ✔
    // 200 = OK (rare)
    // 401 = invalid api key
    // 404 = model not found
    // 0   = no connection
    if ($code === 200 || $code === 400) {
        return ['ok' => true, 'code' => $code, 'msg' => $code === 200 ? 'Connected' : 'Model Active (awaiting image)'];
    } elseif ($code === 401) {
        return ['ok' => false, 'code' => $code, 'msg' => 'Unauthorized – API Key tidak valid'];
    } elseif ($code === 404) {
        return ['ok' => false, 'code' => $code, 'msg' => 'Model tidak ditemukan di Roboflow'];
    } elseif ($code === 0) {
        return ['ok' => false, 'code' => 0, 'msg' => 'Tidak dapat terhubung ke Roboflow (network error)'];
    } else {
        $msg = isset($data['message']) ? $data['message'] : $body;
        return ['ok' => false, 'code' => $code, 'msg' => 'HTTP ' . $code . ': ' . substr($msg, 0, 80)];
    }
}

// ── Ping endpoint Gemini ─────────────────────────────────────────────────────
function pingGemini($endpoint, $apiKey) {
    $payload = json_encode([
        'contents' => [['parts' => [['text' => 'ping']]]],
        'generationConfig' => ['maxOutputTokens' => 1],
    ]);
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => $endpoint,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $payload,
        CURLOPT_TIMEOUT        => 8,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
    ]);
    $body = curl_exec($ch);
    $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($code === 200) {
        return ['ok' => true, 'code' => 200, 'msg' => 'Connected & Responding'];
    } elseif ($code === 400) {
        // Gemini 400 masih berarti API key valid, hanya payload salah
        return ['ok' => true, 'code' => 400, 'msg' => 'API Key Valid'];
    } elseif ($code === 401 || $code === 403) {
        return ['ok' => false, 'code' => $code, 'msg' => 'API Key tidak valid atau expired'];
    } elseif ($code === 0) {
        return ['ok' => false, 'code' => 0, 'msg' => 'Tidak dapat terhubung ke Google AI (network error)'];
    } else {
        $data = json_decode($body, true);
        $msg  = isset($data['error']['message']) ? $data['error']['message'] : $body;
        return ['ok' => false, 'code' => $code, 'msg' => 'HTTP ' . $code . ': ' . substr($msg, 0, 80)];
    }
}

// ── Jalankan semua ping ──────────────────────────────────────────────────────
$results = [];
$totalOk = 0;
$startAll = microtime(true);

foreach ($MODELS as $m) {
    $t0 = microtime(true);
    if ($m['type'] === 'roboflow') {
        $res = pingRoboflow($m['endpoint'], $m['key']);
    } else {
        $res = pingGemini($m['endpoint'], $m['key']);
    }
    $ms = round((microtime(true) - $t0) * 1000);
    $results[] = array_merge($m, $res, ['latency_ms' => $ms]);
    if ($res['ok']) $totalOk++;
}

$totalMs  = round((microtime(true) - $startAll) * 1000);
$allOk    = ($totalOk === count($MODELS));
$now      = date('d M Y, H:i:s T');
$maskKey  = substr($RF_KEY, 0, 4) . '****' . substr($RF_KEY, -4);
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PadiGuard – Status AI API</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --bg:        #0b0f1a;
            --surface:   #131929;
            --card:      #1a2236;
            --border:    #243050;
            --green:     #22c55e;
            --green-dim: rgba(34,197,94,.12);
            --red:       #ef4444;
            --red-dim:   rgba(239,68,68,.12);
            --yellow:    #f59e0b;
            --blue:      #3b82f6;
            --blue-dim:  rgba(59,130,246,.12);
            --text:      #e2e8f0;
            --muted:     #64748b;
            --accent:    #4ade80;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            padding: 2rem 1rem;
        }

        /* ── Header ── */
        .header {
            max-width: 860px;
            margin: 0 auto 2.5rem;
            display: flex;
            align-items: center;
            gap: 1.25rem;
        }
        .logo {
            width: 56px; height: 56px;
            background: linear-gradient(135deg, #22c55e, #16a34a);
            border-radius: 16px;
            display: flex; align-items: center; justify-content: center;
            font-size: 1.75rem;
            box-shadow: 0 0 24px rgba(34,197,94,.35);
            flex-shrink: 0;
        }
        .header-text h1 { font-size: 1.6rem; font-weight: 700; }
        .header-text p  { color: var(--muted); font-size: .875rem; margin-top: .25rem; }

        /* ── Overall banner ── */
        .banner {
            max-width: 860px;
            margin: 0 auto 1.75rem;
            padding: 1.1rem 1.5rem;
            border-radius: 14px;
            display: flex;
            align-items: center;
            gap: 1rem;
            font-weight: 600;
            font-size: 1rem;
            border: 1px solid;
            animation: fadeIn .5s ease;
        }
        .banner.ok  { background: var(--green-dim); border-color: rgba(34,197,94,.3); color: var(--green); }
        .banner.err { background: var(--red-dim);   border-color: rgba(239,68,68,.3);  color: var(--red); }
        .banner .dot {
            width: 12px; height: 12px;
            border-radius: 50%;
            background: currentColor;
            box-shadow: 0 0 8px currentColor;
            animation: pulse 1.5s infinite;
        }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }

        /* ── Stat row ── */
        .stats {
            max-width: 860px;
            margin: 0 auto 1.75rem;
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 1rem;
        }
        .stat {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1rem 1.25rem;
            text-align: center;
        }
        .stat .val { font-size: 1.75rem; font-weight: 700; color: var(--accent); }
        .stat .lbl { font-size: .75rem; color: var(--muted); margin-top: .2rem; }

        /* ── Cards ── */
        .cards { max-width: 860px; margin: 0 auto; display: flex; flex-direction: column; gap: 1rem; }

        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 1.4rem 1.6rem;
            display: grid;
            grid-template-columns: auto 1fr auto;
            align-items: center;
            gap: 1.2rem;
            animation: slideUp .45s ease both;
            transition: transform .2s, box-shadow .2s;
        }
        .card:hover { transform: translateY(-2px); box-shadow: 0 8px 32px rgba(0,0,0,.35); }
        .card.ok  { border-left: 4px solid var(--green); }
        .card.err { border-left: 4px solid var(--red); }

        .card-icon { font-size: 2rem; line-height: 1; }

        .card-body h2 { font-size: 1rem; font-weight: 600; margin-bottom: .3rem; }
        .card-body .perf { font-size: .75rem; color: var(--muted); margin-bottom: .5rem; }
        .card-body .tags { display: flex; flex-wrap: wrap; gap: .4rem; }
        .tag {
            font-size: .7rem;
            padding: .2rem .55rem;
            border-radius: 999px;
            background: var(--blue-dim);
            color: var(--blue);
            border: 1px solid rgba(59,130,246,.25);
            font-weight: 500;
        }

        .card-status { text-align: right; flex-shrink: 0; }
        .badge {
            display: inline-flex;
            align-items: center;
            gap: .4rem;
            padding: .35rem .85rem;
            border-radius: 999px;
            font-size: .8rem;
            font-weight: 600;
        }
        .badge.ok  { background: var(--green-dim); color: var(--green); }
        .badge.err { background: var(--red-dim);   color: var(--red); }
        .badge::before { content:''; width:7px; height:7px; border-radius:50%; background:currentColor; }

        .latency   { font-size: .72rem; color: var(--muted); margin-top: .4rem; }
        .http-code { font-size: .72rem; color: var(--muted); }
        .err-msg   { font-size: .72rem; color: var(--red);   margin-top: .3rem; max-width: 220px; }

        /* ── Info box ── */
        .info-box {
            max-width: 860px;
            margin: 1.75rem auto 0;
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 1.2rem 1.6rem;
        }
        .info-box h3 { font-size: .9rem; font-weight: 600; margin-bottom: .75rem; color: var(--muted); text-transform: uppercase; letter-spacing: .05em; }
        .info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: .5rem 2rem; }
        .info-row  { display: flex; justify-content: space-between; font-size: .8rem; padding: .3rem 0; border-bottom: 1px solid var(--border); }
        .info-row:last-child { border: none; }
        .info-row .k { color: var(--muted); }
        .info-row .v { font-weight: 500; font-family: monospace; font-size: .78rem; }

        /* ── Footer ── */
        .footer {
            max-width: 860px;
            margin: 2rem auto 0;
            text-align: center;
            color: var(--muted);
            font-size: .8rem;
        }

        /* ── Animations ── */
        @keyframes fadeIn   { from{opacity:0} to{opacity:1} }
        @keyframes slideUp  { from{opacity:0;transform:translateY(16px)} to{opacity:1;transform:none} }

        .card:nth-child(1) { animation-delay: .05s }
        .card:nth-child(2) { animation-delay: .12s }
        .card:nth-child(3) { animation-delay: .19s }

        @media(max-width:600px){
            .stats { grid-template-columns: 1fr 1fr; }
            .card  { grid-template-columns: auto 1fr; }
            .card-status { grid-column: 1/-1; text-align: left; }
            .info-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<!-- Header -->
<div class="header">
    <div class="logo">🌾</div>
    <div class="header-text">
        <h1>PadiGuard &mdash; Status AI API</h1>
        <p>Verifikasi koneksi real-time ke seluruh model kecerdasan buatan yang digunakan sistem</p>
    </div>
</div>

<!-- Overall banner -->
<div class="banner <?= $allOk ? 'ok' : 'err' ?>">
    <span class="dot"></span>
    <?php if ($allOk): ?>
        Seluruh <?= count($MODELS) ?> layanan AI aktif &amp; berjalan normal
    <?php else: ?>
        <?= $totalOk ?> / <?= count($MODELS) ?> layanan aktif &mdash; ada koneksi bermasalah
    <?php endif; ?>
    <span style="margin-left:auto;font-weight:400;font-size:.85rem;opacity:.75">Diperbarui: <?= $now ?></span>
</div>

<!-- Stats -->
<div class="stats">
    <div class="stat">
        <div class="val"><?= $totalOk ?>/<?= count($MODELS) ?></div>
        <div class="lbl">Model Aktif</div>
    </div>
    <div class="stat">
        <div class="val"><?= $totalMs ?>ms</div>
        <div class="lbl">Total Latency</div>
    </div>
    <div class="stat">
        <div class="val"><?= $allOk ? '✓' : '!' ?></div>
        <div class="lbl">Overall Status</div>
    </div>
</div>

<!-- Cards -->
<div class="cards">
<?php foreach ($results as $r): ?>
    <div class="card <?= $r['ok'] ? 'ok' : 'err' ?>">
        <div class="card-icon"><?= $r['icon'] ?></div>
        <div class="card-body">
            <h2><?= htmlspecialchars($r['label']) ?></h2>
            <div class="perf"><?= htmlspecialchars($r['perf']) ?></div>
            <div class="tags">
                <?php foreach ($r['classes'] as $c): ?>
                    <span class="tag"><?= htmlspecialchars($c) ?></span>
                <?php endforeach; ?>
            </div>
        </div>
        <div class="card-status">
            <div class="badge <?= $r['ok'] ? 'ok' : 'err' ?>">
                <?= $r['ok'] ? 'ONLINE' : 'ERROR' ?>
            </div>
            <div class="latency"><?= $r['latency_ms'] ?>ms</div>
            <div class="http-code">HTTP <?= $r['code'] ?></div>
            <?php if (!$r['ok']): ?>
                <div class="err-msg"><?= htmlspecialchars($r['msg']) ?></div>
            <?php endif; ?>
        </div>
    </div>
<?php endforeach; ?>
</div>

<!-- Info Box -->
<div class="info-box">
    <h3>🔧 Informasi Konfigurasi Model</h3>
    <div class="info-grid">
        <div>
            <div class="info-row"><span class="k">Workspace Roboflow</span><span class="v">muhammad-aslam-s-workspace</span></div>
            <div class="info-row"><span class="k">Model Hama</span><span class="v">jenis-hama-hlar6 / v1</span></div>
            <div class="info-row"><span class="k">Model Kematangan</span><span class="v">kematangan-ieouc / v1</span></div>
            <div class="info-row"><span class="k">API Key (masked)</span><span class="v"><?= htmlspecialchars($maskKey) ?></span></div>
        </div>
        <div>
            <div class="info-row"><span class="k">Arsitektur AI</span><span class="v">YOLOv12n (nano)</span></div>
            <div class="info-row"><span class="k">mAP@50 (Hama)</span><span class="v">96.0%</span></div>
            <div class="info-row"><span class="k">Precision (Hama)</span><span class="v">94.2%</span></div>
            <div class="info-row"><span class="k">AI Cross-validator</span><span class="v">Gemini 2.0 Flash</span></div>
        </div>
    </div>
</div>

<!-- Footer -->
<div class="footer">
    <p>PadiGuard &copy; <?= date('Y') ?> &mdash; Sistem Klasifikasi Hama &amp; Kematangan Tanaman Padi</p>
    <p style="margin-top:.35rem">
        Halaman ini me-refresh otomatis setiap 60 detik &nbsp;|&nbsp;
        <a href="javascript:location.reload()" style="color:#4ade80;text-decoration:none">↻ Refresh sekarang</a>
    </p>
</div>

<script>
    // Auto-refresh setiap 60 detik
    setTimeout(() => location.reload(), 60000);
</script>
</body>
</html>
