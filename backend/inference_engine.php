<?php
// inference_engine.php - Core Engine untuk Validasi Piksel, Gemini AI, Roboflow, & Hash Matching
// Version 2.4.2 - Strict Human Face & Non-Padi Image Validation

require_once __DIR__ . '/connection.php';

if (!function_exists('getOptimizedBase64')) {
    function getOptimizedBase64($imagePath, $maxDim = 1024, $quality = 85) {
        if (!file_exists($imagePath)) return '';
        $info = @getimagesize($imagePath);
        if (!$info) return base64_encode(file_get_contents($imagePath));
        
        $w = $info[0];
        $h = $info[1];
        
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

        $w = imagesx($img);
        $h = imagesy($img);
        
        $riceColorCount = 0;
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
                
                // 1. Karakteristik Tanaman Padi Asli (Hijau / Kuning Padi / Coklat Batang)
                $isGreenPadi  = ($g > $r && $g > $b + 8 && $g > 35);
                $isYellowPadi = ($r > 90 && $g > 80 && $b < 140 && ($r - $b) > 25 && ($g - $b) > 15 && abs($r - $g) < 45);
                $isDryPadi    = ($r > 70 && $g > 55 && $b < 105 && $r > $b + 18 && ($r - $g) < 30 && ($g - $b) > 8);
                
                $isRicePixel = ($isGreenPadi || $isYellowPadi || $isDryPadi);
                if ($isRicePixel) {
                    $riceColorCount++;
                }

                // 2. Deteksi Kulit Manusia / Wajah (RGB & YCbCr Mode Presisi Tinggi)
                $cb = 128 - 0.168736 * $r - 0.331264 * $g + 0.5 * $b;
                $cr = 128 + 0.418688 * $r - 0.345842 * $g - 0.072846 * $b;
                $saturation = max($r, $g, $b) - min($r, $g, $b);
                
                $isRgbSkin   = ($r > 60) && ($g > 35) && ($b > 20) && ($r > $g) && ($g > $b) && (($r - $g) >= 8) && ($r - $b >= 15);
                $isYcbcrSkin = ($cb >= 77 && $cb <= 128) && ($cr >= 130 && $cr <= 175) && ($saturation > 15);
                
                if (($isRgbSkin || $isYcbcrSkin) && !$isRicePixel) {
                    $skinColorCount++;
                }
                
                // 3. Rambut / Ruangan Gelap / Dinding Indoor
                if ($r < 60 && $g < 60 && $b < 60) {
                    $indoorDarkCount++;
                }

                // 4. Deteksi Baju / Pakaian Manusia
                $isRedShirt    = ($r > 150 && $g < 80 && $b < 80);
                $isBlueShirt   = ($b > 120 && $b > $r + 20 && $b > $g + 20);
                $isPurpleShirt = ($r > 90 && $b > 90 && $g < 80);
                $isOrangeShirt = ($r > 180 && $g > 70 && $g < 160 && $b < 60);
                if ($isRedShirt || $isBlueShirt || $isPurpleShirt || $isOrangeShirt) {
                    $artificialClothingCount++;
                }
                
                // 5. Background dokumen / solid / tembok
                if (($r > 215 && $g > 215 && $b > 215) || ($r < 25 && $g < 25 && $b < 25)) {
                    $documentBgCount++;
                }
                
                // 6. Biru langit / tembok
                $isBlueSky = ($b > $r + 15 && $b > $g + 10 && $b > 90);
                if ($isBlueSky) $blueNonPadiCount++;
                
                // 7. Abu-abu netral
                $isGray = (abs($r - $g) < 18 && abs($g - $b) < 18 && abs($r - $b) < 18 && $r > 35 && $r < 215);
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
        
        // KRITERIA PENOLAKAN FOTO WAJAH MANUSIA (Strict Rejection Threshold)
        if ($skinRatio >= 0.05 && $riceRatio < 0.08) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai wajah atau tubuh manusia, bukan tanaman padi. Harap ambil foto tanaman padi yang valid (sawah/daun/batang padi).'];
        }

        if ($riceRatio < 0.03 || ($indoorDarkRatio + $grayRatio > 0.45 && $riceRatio < 0.05)) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai foto ruangan/objek indoor, bukan tanaman padi. Harap unggah foto tanaman padi yang jelas.'];
        }
        
        if ($clothingRatio > 0.15 && $riceRatio < 0.08) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi mengandung objek buatan (pakaian/baju), bukan tanaman padi.'];
        }
        
        if ($docRatio > 0.75) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai dokumen, screenshot, atau latar polos, bukan tanaman padi.'];
        }
        
        if (($blueRatio + $grayRatio) > 0.80 && $riceRatio < 0.03) {
            return ['valid' => false, 'reason' => 'Gambar didominasi langit atau objek buatan, bukan tanaman padi.'];
        }
        
        return ['valid' => true, 'reason' => ''];
    }
}
