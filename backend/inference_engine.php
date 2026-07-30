<?php
// inference_engine.php - Core Engine untuk Validasi Piksel, Gemini AI, Roboflow, & Hash Matching
// Version 2.4.1 - Optimized Image Resizing for < 3s Latency

require_once __DIR__ . '/connection.php';

if (!function_exists('getOptimizedBase64')) {
    function getOptimizedBase64($imagePath, $maxDim = 1024, $quality = 85) {
        if (!file_exists($imagePath)) return '';
        $info = @getimagesize($imagePath);
        if (!$info) return base64_encode(file_get_contents($imagePath));
        
        $w = $info[0];
        $h = $info[1];
        
        // Jika sudah <= maxDim, langsung base64
        if ($w <= $maxDim && $h <= $maxDim) {
            return base64_encode(file_get_contents($imagePath));
        }
        
        $mime = $info['mime'];
        if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
            $src = @imagecreatefromjpeg($imagePath);
        } elseif ($mime == 'image/png') {
            $src = @imagecreatefrompng($imagePath);
        } elseif ($mime == 'image/webp') {
            $src = @imagecreatefromwebp($imagePath);
        } else {
            return base64_encode(file_get_contents($imagePath));
        }
        
        if (!$src) return base64_encode(file_get_contents($imagePath));
        
        $scale = min($maxDim / $w, $maxDim / $h);
        $newW = (int)round($w * $scale);
        $newH = (int)round($h * $scale);
        
        $dst = imagecreatetruecolor($newW, $newH);
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $newW, $newH, $w, $h);
        
        ob_start();
        imagejpeg($dst, null, $quality);
        $bytes = ob_get_clean();
        
        imagedestroy($src);
        imagedestroy($dst);
        
        return base64_encode($bytes);
    }
}

if (!function_exists('extractPestNameFromText')) {
    function extractPestNameFromText($text) {
        if (empty($text)) return null;
        $t = strtolower($text);
        if (strpos($t, 'wereng') !== false || strpos($t, 'hopper') !== false || strpos($t, 'brown planthopper') !== false) {
            return 'Wereng Coklat';
        }
        if (strpos($t, 'walang') !== false || strpos($t, 'sangit') !== false || strpos($t, 'stink bug') !== false) {
            return 'Walang Sangit';
        }
        if (strpos($t, 'penggerek') !== false || strpos($t, 'borer') !== false || strpos($t, 'stem borer') !== false || strpos($t, 'sundep') !== false || strpos($t, 'beluk') !== false) {
            return 'Penggerek Batang';
        }
        if (strpos($t, 'grayak') !== false || strpos($t, 'armyworm') !== false || strpos($t, 'spodoptera') !== false || strpos($t, 'ulat') !== false) {
            return 'Ulat Grayak';
        }
        return null;
    }
}

if (!function_exists('extractMaturityFromText')) {
    function extractMaturityFromText($text) {
        if (empty($text)) return null;
        $t = strtolower($text);
        if (strpos($t, 'setengah') !== false || strpos($t, 'half') !== false || strpos($t, 'medium') !== false) {
            return 'Setengah Matang';
        }
        if (strpos($t, 'matang') !== false || strpos($t, 'ripe') !== false || strpos($t, 'mature') !== false || strpos($t, 'panen') !== false) {
            return 'Matang';
        }
        if (strpos($t, 'mentah') !== false || strpos($t, 'unripe') !== false || strpos($t, 'green') !== false || strpos($t, 'muda') !== false) {
            return 'Mentah';
        }
        return null;
    }
}

if (!function_exists('analyzeMaturity')) {
    function analyzeMaturity($imagePath) {
        if (!file_exists($imagePath)) return 'Mentah';
        $info = @getimagesize($imagePath);
        if (!$info) return 'Mentah';
        
        $mime = $info['mime'];
        if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
            $img = @imagecreatefromjpeg($imagePath);
        } elseif ($mime == 'image/png') {
            $img = @imagecreatefrompng($imagePath);
        } elseif ($mime == 'image/webp') {
            $img = @imagecreatefromwebp($imagePath);
        } else {
            return 'Mentah';
        }
        if (!$img) return 'Mentah';
        
        $w = imagesx($img);
        $h = imagesy($img);
        
        $greenCount = 0;
        $yellowCount = 0;
        $totalCount = 0;
        
        $sampleX = 30;
        $sampleY = 30;
        $stepX = max(1, (int)($w / $sampleX));
        $stepY = max(1, (int)($h / $sampleY));
        
        for ($x = 0; $x < $w; $x += $stepX) {
            for ($y = 0; $y < $h; $y += $stepY) {
                $totalCount++;
                $rgb = @imagecolorat($img, (int)$x, (int)$y);
                if ($rgb === false) continue;
                $r = ($rgb >> 16) & 0xFF;
                $g = ($rgb >> 8) & 0xFF;
                $b = $rgb & 0xFF;
                
                if ($g > $r && $g > $b && ($g - $r) > 12) {
                    $greenCount++;
                } elseif ($r > 120 && $g > 110 && ($r - $b) > 35 && ($g - $b) > 25 && abs($r - $g) < 40) {
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
}

if (!function_exists('isRicePlantImage')) {
    function isRicePlantImage($imagePath) {
        if (!file_exists($imagePath)) return ['valid' => false, 'reason' => 'File tidak ditemukan'];
        $info = @getimagesize($imagePath);
        if (!$info) return ['valid' => false, 'reason' => 'Format file bukan gambar yang valid'];
        
        $mime = $info['mime'];
        if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
            $img = @imagecreatefromjpeg($imagePath);
        } elseif ($mime == 'image/png') {
            $img = @imagecreatefrompng($imagePath);
        } elseif ($mime == 'image/webp') {
            $img = @imagecreatefromwebp($imagePath);
        } else {
            return ['valid' => false, 'reason' => 'Format gambar harus JPG, PNG, atau WEBP'];
        }
        if (!$img) return ['valid' => false, 'reason' => 'Gagal membuka file gambar'];
        
        // 0. CEK TERLEBIH DAHULU KE DATABASE DATASET HOSTING (Visual Hash Matching)
        global $pdo;
        if (isset($pdo) && $pdo) {
            $uploadHash = getAverageHash($imagePath);
            if ($uploadHash) {
                try {
                    $stmtDsHashes = $pdo->query("SELECT `id`, `label`, `hash` FROM `dataset` WHERE `hash` IS NOT NULL AND `hash` != ''");
                    $dsRows = $stmtDsHashes->fetchAll(PDO::FETCH_ASSOC);
                    foreach ($dsRows as $row) {
                        $dist = getHammingDistance($uploadHash, $row['hash']);
                        if ($dist <= 10) {
                            @imagedestroy($img);
                            return ['valid' => true, 'reason' => ''];
                        }
                    }
                } catch (\Exception $ex) {}
            }
        }

        $w = imagesx($img);
        $h = imagesy($img);
        
        $riceColorCount = 0; // FIX A.1
        $documentBgCount = 0;
        $skinColorCount = 0;
        $artificialClothingCount = 0;
        $blueNonPadiCount = 0;
        $grayNonPadiCount = 0;
        $indoorDarkCount = 0;
        
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
                
                // 1. Karakteristik Tanaman Padi Asli
                $isGreenPadi  = ($g > $r && $g > $b + 8 && $g > 35);
                $isYellowPadi = ($r > 90 && $g > 80 && $b < 140 && ($r - $b) > 25 && ($g - $b) > 15 && abs($r - $g) < 45);
                $isDryPadi    = ($r > 70 && $g > 55 && $b < 105 && $r > $b + 18 && ($r - $g) < 30 && ($g - $b) > 8);
                
                $isRicePixel = ($isGreenPadi || $isYellowPadi || $isDryPadi);
                if ($isRicePixel) {
                    $riceColorCount++;
                }

                // 2. FIX A.2: Deteksi Kulit Manusia Presisi Tinggi
                $cb = 128 - 0.168736 * $r - 0.331264 * $g + 0.5 * $b;
                $cr = 128 + 0.418688 * $r - 0.345842 * $g - 0.072846 * $b;
                $saturation = max($r, $g, $b) - min($r, $g, $b);
                $isRgbSkin   = ($r > 80) && ($g > 45) && ($b > 30) && ($r > $g) && ($g > $b) && (($r - $g) >= 12) && ($r - $b >= 30);
                $isYcbcrSkin = ($cb >= 80 && $cb <= 125) && ($cr >= 135 && $cr <= 175) && ($saturation > 20) && ($r > $b + 20) && !$isRicePixel;
                if ($isRgbSkin || $isYcbcrSkin) {
                    $skinColorCount++;
                }
                
                // 3. Rambut / Ruangan Gelap
                if ($r < 55 && $g < 55 && $b < 55) {
                    $indoorDarkCount++;
                }

                // 4. Deteksi Pakaian
                $isRedShirt    = ($r > 160 && $g < 70 && $b < 70);
                $isBlueShirt   = ($b > 130 && $b > $r + 30 && $b > $g + 30);
                $isPurpleShirt = ($r > 100 && $b > 100 && $g < 80 && abs($r - $b) < 50);
                $isOrangeShirt = ($r > 190 && $g > 75 && $g < 150 && $b < 50);
                if ($isRedShirt || $isBlueShirt || $isPurpleShirt || $isOrangeShirt) {
                    $artificialClothingCount++;
                }
                
                // 5. Background dokumen / solid
                if (($r > 220 && $g > 220 && $b > 220) || ($r < 20 && $g < 20 && $b < 20)) {
                    $documentBgCount++;
                }
                
                // 6. Biru langit
                $isBlueSky = ($b > $r + 20 && $b > $g + 15 && $b > 100);
                if ($isBlueSky) $blueNonPadiCount++;
                
                // 7. Abu-abu netral
                $isGray = (abs($r - $g) < 15 && abs($g - $b) < 15 && abs($r - $b) < 15 && $r > 40 && $r < 210);
                if ($isGray) $grayNonPadiCount++;
            }
        }
        @imagedestroy($img);
        
        if ($totalSamples == 0) return ['valid' => true, 'reason' => ''];
        
        $skinRatio       = $skinColorCount / $totalSamples;
        $indoorDarkRatio = $indoorDarkCount / $totalSamples;
        $clothingRatio   = $artificialClothingCount / $totalSamples;
        $docRatio        = $documentBgCount / $totalSamples;
        $blueRatio       = $blueNonPadiCount / $totalSamples;
        $grayRatio       = $grayNonPadiCount / $totalSamples;
        $riceRatio       = $riceColorCount / $totalSamples;
        
        if ($skinRatio >= 0.12 && $riceRatio < 0.05) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai wajah atau tubuh manusia, bukan tanaman padi.'];
        }

        if ($riceRatio < 0.015 || ($indoorDarkRatio + $grayRatio > 0.50 && $riceRatio < 0.025)) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai foto ruangan/objek indoor, bukan tanaman padi. Harap unggah foto tanaman padi yang valid.'];
        }
        
        if ($clothingRatio > 0.20 && $riceRatio < 0.05) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi mengandung objek buatan (pakaian/baju), bukan tanaman padi.'];
        }
        
        if ($docRatio > 0.80) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai dokumen, screenshot, atau latar polos, bukan tanaman padi.'];
        }
        
        if (($blueRatio + $grayRatio) > 0.85 && $riceRatio < 0.02) {
            return ['valid' => false, 'reason' => 'Gambar didominasi langit atau objek buatan, bukan tanaman padi.'];
        }
        
        if ($riceRatio < 0.015) {
            return ['valid' => false, 'reason' => 'Gambar tidak terdeteksi mengandung tanaman padi (tidak ada daun, batang, gabah, atau sawah).'];
        }
        
        return ['valid' => true, 'reason' => ''];
    }
}
