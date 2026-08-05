<?php
// inference_engine.php - Core Engine untuk Validasi Piksel, Gemini AI, Roboflow, & Hash Matching
// Version 2.5.0 - Comprehensive Non-Padi Rejection + Improved Messages

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
    /**
     * Validasi piksel apakah gambar adalah tanaman padi.
     * Versi 2.5.0 - Multi-kategori rejection dengan pesan yang tepat.
     * 
     * Perbaikan utama:
     * 1. Pesan error dibedakan per kategori (wajah, makanan, indoor, tembok, dll)
     * 2. Deteksi kulit tidak lagi menimpa deteksi tembok krem/beige
     * 3. Threshold lebih ketat untuk foto makanan, parkiran, ruangan
     * 4. Deteksi tambahan: warna beige/krem tembok, aspal, dan objek buatan
     */
    function isRicePlantImage($imagePath) {
        if (!file_exists($imagePath)) return ['valid' => false, 'reason' => 'File tidak ditemukan.'];
        $info = @getimagesize($imagePath);
        if (!$info) return ['valid' => false, 'reason' => 'Format file bukan gambar yang valid.'];
        
        $mime = $info['mime'];
        if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
            $img = @imagecreatefromjpeg($imagePath);
        } elseif ($mime == 'image/png') {
            $img = @imagecreatefrompng($imagePath);
        } elseif ($mime == 'image/webp') {
            $img = @imagecreatefromwebp($imagePath);
        } else {
            return ['valid' => false, 'reason' => 'Format gambar harus JPG, PNG, atau WEBP.'];
        }
        if (!$img) return ['valid' => false, 'reason' => 'Gagal membuka file gambar.'];

        $w = imagesx($img);
        $h = imagesy($img);
        
        $riceColorCount        = 0;
        $documentBgCount       = 0;
        $skinColorCount        = 0;
        $artificialClothingCount = 0;
        $blueNonPadiCount      = 0;
        $grayNonPadiCount      = 0;
        $indoorDarkCount       = 0;
        $foodColorCount        = 0;   // Warna makanan (kuning gorengan, merah saus, dll)
        $wallBeigeCreamCount   = 0;   // Tembok/plafon krem atau putih tulang
        $asphaltCount          = 0;   // Aspal / lantai gelap
        $brightArtificialCount = 0;   // Lampu, LED, objek sangat terang indoor
        
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
                
                $maxRgb = max($r, $g, $b);
                $minRgb = min($r, $g, $b);
                $saturation = $maxRgb - $minRgb;

                // -------------------------------------------------------
                // 1. Karakteristik Tanaman Padi (Hijau / Kuning Padi / Coklat Batang)
                // -------------------------------------------------------
                $isGreenPadi  = ($g > $r && $g > $b + 8 && $g > 35);
                $isYellowPadi = ($r > 90 && $g > 80 && $b < 140 && ($r - $b) > 25 && ($g - $b) > 15 && abs($r - $g) < 45);
                $isDryPadi    = ($r > 70 && $g > 55 && $b < 105 && $r > $b + 18 && ($r - $g) < 30 && ($g - $b) > 8);
                
                $isRicePixel = ($isGreenPadi || $isYellowPadi || $isDryPadi);
                if ($isRicePixel) {
                    $riceColorCount++;
                }

                // -------------------------------------------------------
                // 2. Deteksi Kulit Manusia / Wajah (YCbCr presisi tinggi)
                //    HANYA dihitung jika BUKAN tembok/krem
                // -------------------------------------------------------
                $cb = 128 - 0.168736 * $r - 0.331264 * $g + 0.5 * $b;
                $cr = 128 + 0.418688 * $r - 0.345842 * $g - 0.072846 * $b;
                
                $isRgbSkin   = ($r > 80) && ($g > 50) && ($b > 30) && ($r > $g) && ($g > $b) && (($r - $g) >= 10) && ($r - $b >= 20) && ($saturation > 20);
                $isYcbcrSkin = ($cb >= 80 && $cb <= 125) && ($cr >= 133 && $cr <= 173) && ($saturation > 20);
                
                // Tembok krem/beige juga punya pola RGB mirip kulit tapi saturation sangat rendah
                $isBeigeCream = ($r > 180 && $g > 155 && $b > 110 && $saturation < 60 && abs($r - $g) < 50);
                $isWallWhite  = ($r > 210 && $g > 200 && $b > 190 && $saturation < 40);
                
                if ($isBeigeCream || $isWallWhite) {
                    $wallBeigeCreamCount++;
                }
                
                // Hitung skin HANYA jika bukan tembok dan bukan pixel padi
                if (($isRgbSkin || $isYcbcrSkin) && !$isRicePixel && !$isBeigeCream && !$isWallWhite) {
                    $skinColorCount++;
                }
                
                // -------------------------------------------------------
                // 3. Rambut / Area Sangat Gelap (Indoor)
                // -------------------------------------------------------
                if ($r < 50 && $g < 50 && $b < 50) {
                    $indoorDarkCount++;
                }

                // -------------------------------------------------------
                // 4. Deteksi Pakaian / Baju Buatan
                // -------------------------------------------------------
                $isRedShirt    = ($r > 150 && $g < 80 && $b < 80);
                $isBlueShirt   = ($b > 120 && $b > $r + 20 && $b > $g + 20);
                $isPurpleShirt = ($r > 90 && $b > 90 && $g < 80);
                $isOrangeShirt = ($r > 180 && $g > 70 && $g < 160 && $b < 60);
                if ($isRedShirt || $isBlueShirt || $isPurpleShirt || $isOrangeShirt) {
                    $artificialClothingCount++;
                }
                
                // -------------------------------------------------------
                // 5. Deteksi Makanan (Kuning gorengan/kentang/mie, Merah saos, Coklat makanan)
                //    Dibedakan dari padi kuning: saturasi tinggi, tidak ada komponen hijau
                // -------------------------------------------------------
                $isFriesYellow  = ($r > 200 && $g > 160 && $g < 220 && $b < 100 && ($r - $b) > 110 && ($g - $b) > 70);
                $isSauceRed     = ($r > 160 && $g < 80 && $b < 80 && ($r - $g) > 90);
                $isBrownFood    = ($r > 120 && $g > 70 && $g < 130 && $b < 70 && ($r - $b) > 60 && ($r - $g) < 70);
                $isPackagingRed = ($r > 180 && $g < 70 && $b < 70);
                $isPackagingGreen = ($g > 140 && $g > $r + 30 && $g > $b + 30 && $b < 80);
                // Packaging/label warna cerah yang tidak alami (seperti bungkus saos Extra Boy)
                $isBrightArtificial = ($r > 220 && $g < 50 && $b < 50) || ($g > 220 && $r < 50 && $b < 50) || ($b > 220 && $r < 50 && $g < 50);
                
                if ($isFriesYellow || $isSauceRed || $isBrownFood || $isPackagingRed) {
                    $foodColorCount++;
                }
                if ($isBrightArtificial) {
                    $brightArtificialCount++;
                }
                
                // -------------------------------------------------------
                // 6. Background dokumen / solid putih / hitam
                // -------------------------------------------------------
                if (($r > 220 && $g > 220 && $b > 220) || ($r < 20 && $g < 20 && $b < 20)) {
                    $documentBgCount++;
                }
                
                // -------------------------------------------------------
                // 7. Langit biru / objek biru buatan
                // -------------------------------------------------------
                $isBlueSky = ($b > $r + 20 && $b > $g + 15 && $b > 90);
                if ($isBlueSky) $blueNonPadiCount++;
                
                // -------------------------------------------------------
                // 8. Abu-abu netral (aspal, tembok beton, motor, mobil)
                // -------------------------------------------------------
                $isGray = (abs($r - $g) < 18 && abs($g - $b) < 18 && abs($r - $b) < 18 && $r > 35 && $r < 215);
                if ($isGray) $grayNonPadiCount++;

                // -------------------------------------------------------
                // 9. Aspal gelap / lantai gelap parkiran
                // -------------------------------------------------------
                $isAsphalt = ($r >= 40 && $r <= 100 && abs($r - $g) < 15 && abs($g - $b) < 15);
                if ($isAsphalt) $asphaltCount++;
            }
        }
        @imagedestroy($img);
        
        if ($totalSamples == 0) return ['valid' => true, 'reason' => ''];
        
        $skinRatio          = $skinColorCount / $totalSamples;
        $indoorDarkRatio    = $indoorDarkCount / $totalSamples;
        $clothingRatio      = $artificialClothingCount / $totalSamples;
        $docRatio           = $documentBgCount / $totalSamples;
        $blueRatio          = $blueNonPadiCount / $totalSamples;
        $grayRatio          = $grayNonPadiCount / $totalSamples;
        $riceRatio          = $riceColorCount / $totalSamples;
        $foodRatio          = $foodColorCount / $totalSamples;
        $wallRatio          = $wallBeigeCreamCount / $totalSamples;
        $asphaltRatio       = $asphaltCount / $totalSamples;
        $brightArtRatio     = $brightArtificialCount / $totalSamples;

        // =======================================================================
        // KRITERIA PENOLAKAN - Multi-Kategori dengan Pesan Tepat
        // =======================================================================

        // [A] Tembok / Lantai Polos / Plafon
        if ($wallRatio > 0.55 && $riceRatio < 0.08) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }

        // [B] Wajah / Tubuh Manusia
        if ($skinRatio >= 0.08 && $riceRatio < 0.10 && $wallRatio < 0.30) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }

        // [C] Makanan
        if ($foodRatio > 0.12 && $riceRatio < 0.10) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }
        
        // [D] Kemasan Produk / Objek Buatan
        if ($brightArtRatio > 0.05 && $riceRatio < 0.08) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }

        // [E] Parkiran / Outdoor Non-Padi
        if (($asphaltRatio + $grayRatio) > 0.50 && $riceRatio < 0.06) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }

        // [F] Ruangan Indoor / Area Gelap
        if ($indoorDarkRatio > 0.25 && ($grayRatio + $asphaltRatio) > 0.30 && $riceRatio < 0.05) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }

        // [G] Non-Padi Umum
        if ($riceRatio < 0.03 || ($indoorDarkRatio + $grayRatio > 0.45 && $riceRatio < 0.05)) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }
        
        // [H] Pakaian / Baju
        if ($clothingRatio > 0.15 && $riceRatio < 0.08) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }
        
        // [I] Dokumen / Screenshot
        if ($docRatio > 0.75) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }
        
        // [J] Langit / Objek Biru
        if (($blueRatio + $grayRatio) > 0.80 && $riceRatio < 0.03) {
            return ['valid' => false, 'reason' => 'Gambar terdeteksi sebagai gambar non-padi.'];
        }
        
        return ['valid' => true, 'reason' => ''];
    }
}

if (!function_exists('getAverageHash')) {
    function getAverageHash($imagePath, $hashSize = 8) {
        if (!file_exists($imagePath)) return null;
        $info = @getimagesize($imagePath);
        if (!$info) return null;
        
        $mime = $info['mime'];
        if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
            $src = @imagecreatefromjpeg($imagePath);
        } elseif ($mime == 'image/png') {
            $src = @imagecreatefrompng($imagePath);
        } elseif ($mime == 'image/webp') {
            $src = @imagecreatefromwebp($imagePath);
        } else {
            return null;
        }
        if (!$src) return null;
        
        $small = imagecreatetruecolor($hashSize, $hashSize);
        imagecopyresampled($small, $src, 0, 0, 0, 0, $hashSize, $hashSize, imagesx($src), imagesy($src));
        imagedestroy($src);
        
        $grayImg = imagecreatetruecolor($hashSize, $hashSize);
        for ($x = 0; $x < $hashSize; $x++) {
            for ($y = 0; $y < $hashSize; $y++) {
                $rgb = imagecolorat($small, $x, $y);
                $r = ($rgb >> 16) & 0xFF;
                $g = ($rgb >> 8) & 0xFF;
                $b = $rgb & 0xFF;
                $gray = (int)(0.299 * $r + 0.587 * $g + 0.114 * $b);
                $color = imagecolorallocate($grayImg, $gray, $gray, $gray);
                imagesetpixel($grayImg, $x, $y, $color);
            }
        }
        
        $totalGray = 0;
        for ($x = 0; $x < $hashSize; $x++) {
            for ($y = 0; $y < $hashSize; $y++) {
                $rgb = imagecolorat($grayImg, $x, $y);
                $totalGray += $rgb & 0xFF;
            }
        }
        $avgGray = $totalGray / ($hashSize * $hashSize);
        
        $hash = '';
        for ($x = 0; $x < $hashSize; $x++) {
            for ($y = 0; $y < $hashSize; $y++) {
                $rgb = imagecolorat($grayImg, $x, $y);
                $gray = $rgb & 0xFF;
                $hash .= ($gray >= $avgGray) ? '1' : '0';
            }
        }
        
        imagedestroy($small);
        imagedestroy($grayImg);
        
        return $hash;
    }
}

if (!function_exists('getHammingDistance')) {
    function getHammingDistance($hash1, $hash2) {
        if (strlen($hash1) !== strlen($hash2)) return 999;
        $distance = 0;
        for ($i = 0; $i < strlen($hash1); $i++) {
            if ($hash1[$i] !== $hash2[$i]) $distance++;
        }
        return $distance;
    }
}

if (!function_exists('isGrassOrWeedImage')) {
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
        $total = 0;
        $greenCount = 0;
        $brownCount = 0;
        
        $stepX = max(1, (int)($w / 40));
        $stepY = max(1, (int)($h / 40));
        
        for ($x = 0; $x < $w; $x += $stepX) {
            for ($y = 0; $y < $h; $y += $stepY) {
                $total++;
                $rgb = @imagecolorat($img, $x, $y);
                if ($rgb === false) continue;
                $r = ($rgb >> 16) & 0xFF;
                $g = ($rgb >> 8) & 0xFF;
                $b = $rgb & 0xFF;
                
                if ($g > $r && $g > $b && ($g - $r) > 10 && ($g - $b) > 10) {
                    $greenCount++;
                }
                if ($r > 80 && $g > 60 && $b < 80 && $r > $g && $r > $b) {
                    $brownCount++;
                }
            }
        }
        @imagedestroy($img);
        
        if ($total === 0) return false;
        $greenRatio = $greenCount / $total;
        $brownRatio = $brownCount / $total;
        
        return ($greenRatio > 0.40 && $brownRatio < 0.15);
    }
}

if (!function_exists('detectDamagedAreas')) {
    /**
     * Deteksi MULTI-AREA terdampak hama pada gambar sawah berdasarkan analisis piksel.
     * Menggunakan spatial clustering (grid-based flood-fill) untuk mengelompokkan
     * piksel terdampak (Wereng Coklat, Penggerek Batang, hopperburn, beluk, sundep).
     *
     * @param string $imagePath Path ke file gambar
     * @return array Array of bounding boxes normalized 0-1
     */
    function detectDamagedAreas($imagePath) {
        if (!file_exists($imagePath)) return [];
        $info = @getimagesize($imagePath);
        if (!$info) return [];

        $mime = $info['mime'];
        if ($mime == 'image/jpeg' || $mime == 'image/jpg') {
            $img = @imagecreatefromjpeg($imagePath);
        } elseif ($mime == 'image/png') {
            $img = @imagecreatefrompng($imagePath);
        } elseif ($mime == 'image/webp') {
            $img = @imagecreatefromwebp($imagePath);
        } else {
            return [];
        }
        if (!$img) return [];

        $w = imagesx($img);
        $h = imagesy($img);

        // Grid sampling: 60x60 titik sampel
        $gridX = 60;
        $gridY = 60;
        $stepX = max(1, (int)($w / $gridX));
        $stepY = max(1, (int)($h / $gridY));

        $grid = [];
        $totalSamples = 0;
        $totalDamaged = 0;

        for ($gx = 0; $gx < $gridX; $gx++) {
            for ($gy = 0; $gy < $gridY; $gy++) {
                $grid[$gx][$gy] = false;
            }
        }

        for ($gx = 0; $gx < $gridX; $gx++) {
            $px = min($w - 1, $gx * $stepX);
            for ($gy = 0; $gy < $gridY; $gy++) {
                $py = min($h - 1, $gy * $stepY);
                $totalSamples++;

                $rgb = @imagecolorat($img, (int)$px, (int)$py);
                if ($rgb === false) continue;
                $r = ($rgb >> 16) & 0xFF;
                $g = ($rgb >> 8) & 0xFF;
                $b = $rgb & 0xFF;

                $saturation = max($r, $g, $b) - min($r, $g, $b);
                $isDamaged = false;

                // 1. Gejala Wereng Coklat: Putih / Kuning Pucat (hopperburn — daun memutih/menguning)
                if ($r > 165 && $g > 150 && $b > 120 && ($r - $b) > 10) {
                    $isDamaged = true;
                }
                // 2. Gejala Wereng Coklat: Coklat Muda / Daun Mengering
                if (!$isDamaged && $r > 130 && $g > 80 && $b < 105 && $r > $b) {
                    $isDamaged = true;
                }
                // 3. Gejala Wereng Coklat / Penggerek Batang: Coklat Tua / Batang Layu (Sundep/Mati)
                if (!$isDamaged && $r > 75 && $g > 40 && $b < 80 && $r > $g && $g > $b) {
                    $isDamaged = true;
                }
                // 4. Gejala Penggerek Batang: Beluk / Malai Putih / Gabah Hampa Pucat
                if (!$isDamaged && $r > 150 && $g > 140 && $b > 100 && abs($r - $g) < 35) {
                    $isDamaged = true;
                }
                // 5. Daun Kering / Tanaman Mati
                if (!$isDamaged && $r > 140 && $g > 110 && $b < 110 && ($r - $b) > 30) {
                    $isDamaged = true;
                }

                // Exclude piksel hijau segar yang dominan
                if ($isDamaged && $g > $r && $g > $b + 20 && ($g - $r) > 18) {
                    $isDamaged = false;
                }

                if ($isDamaged) {
                    $grid[$gx][$gy] = true;
                    $totalDamaged++;
                }
            }
        }
        @imagedestroy($img);

        // Minimal 1% area terpengaruh gejala
        if ($totalDamaged < ($totalSamples * 0.01)) {
            return [];
        }

        // FLOOD-FILL CLUSTERING
        $visited = [];
        for ($gx = 0; $gx < $gridX; $gx++) {
            for ($gy = 0; $gy < $gridY; $gy++) {
                $visited[$gx][$gy] = false;
            }
        }

        $clusters = [];

        for ($gx = 0; $gx < $gridX; $gx++) {
            for ($gy = 0; $gy < $gridY; $gy++) {
                if ($grid[$gx][$gy] && !$visited[$gx][$gy]) {
                    $cluster = [];
                    $queue = [[$gx, $gy]];
                    $visited[$gx][$gy] = true;

                    while (!empty($queue)) {
                        list($cx, $cy) = array_shift($queue);
                        $cluster[] = ['gx' => $cx, 'gy' => $cy];

                        for ($dx = -2; $dx <= 2; $dx++) {
                            for ($dy = -2; $dy <= 2; $dy++) {
                                if ($dx === 0 && $dy === 0) continue;
                                $nx = $cx + $dx;
                                $ny = $cy + $dy;
                                if ($nx >= 0 && $nx < $gridX && $ny >= 0 && $ny < $gridY
                                    && $grid[$nx][$ny] && !$visited[$nx][$ny]) {
                                    $visited[$nx][$ny] = true;
                                    $queue[] = [$nx, $ny];
                                }
                            }
                        }
                    }

                    // Minimal 4 sel grid (~1% area gambar)
                    if (count($cluster) >= 4) {
                        $clusters[] = $cluster;
                    }
                }
            }
        }

        if (empty($clusters)) {
            return [];
        }

        $result = [];
        foreach ($clusters as $cluster) {
            $cMinX = $gridX; $cMinY = $gridY;
            $cMaxX = 0;     $cMaxY = 0;

            foreach ($cluster as $cell) {
                if ($cell['gx'] < $cMinX) $cMinX = $cell['gx'];
                if ($cell['gy'] < $cMinY) $cMinY = $cell['gy'];
                if ($cell['gx'] > $cMaxX) $cMaxX = $cell['gx'];
                if ($cell['gy'] > $cMaxY) $cMaxY = $cell['gy'];
            }

            // Batasi koordinat agar selalu DI DALAM bounding box kematangan (0.08 - 0.92)
            $nxMin = max(0.08, ($cMinX * $stepX / $w) - 0.01);
            $nyMin = max(0.08, ($cMinY * $stepY / $h) - 0.01);
            $nxMax = min(0.92, (($cMaxX + 1) * $stepX / $w) + 0.01);
            $nyMax = min(0.92, (($cMaxY + 1) * $stepY / $h) + 0.01);

            $bboxW = $nxMax - $nxMin;
            $bboxH = $nyMax - $nyMin;
            $area = $bboxW * $bboxH;

            // Batasi luas maksimal box hama hingga 45% area agar tidak raksasa
            if ($area >= 0.015 && $area <= 0.55) {
                $result[] = [
                    'xMin' => round($nxMin, 4),
                    'yMin' => round($nyMin, 4),
                    'xMax' => round($nxMax, 4),
                    'yMax' => round($nyMax, 4),
                    'cellCount' => count($cluster),
                    'area' => $area
                ];
            }
        }

        usort($result, function ($a, $b) {
            return $b['cellCount'] - $a['cellCount'];
        });

        return array_slice($result, 0, 3);
    }
}

if (!function_exists('detectDamagedArea')) {
    function detectDamagedArea($imagePath) {
        $areas = detectDamagedAreas($imagePath);
        return !empty($areas) ? $areas[0] : null;
    }
}

if (!function_exists('cleanNmsBoxes')) {
    /**
     * Non-Maximum Suppression (NMS) & Filtering untuk Bounding Box Hama:
     * - Memastikan box hama tidak pernah keluar dari batas kematangan (0.08 - 0.92)
     * - Luas maksimal box hama dipatok 45% dari area gambar
     */
    function cleanNmsBoxes($boxes, $iouThreshold = 0.35, $minArea = 0.015, $maxBoxes = 3) {
        if (empty($boxes)) return [];

        $filtered = [];
        foreach ($boxes as $b) {
            // Cap koordinat agar selalu di dalam box kematangan
            $xMin = max(0.08, $b['xMin']);
            $yMin = max(0.08, $b['yMin']);
            $xMax = min(0.92, $b['xMax']);
            $yMax = min(0.92, $b['yMax']);

            $w = $xMax - $xMin;
            $h = $yMax - $yMin;
            $area = $w * $h;

            if ($area >= $minArea) {
                $b['xMin'] = round($xMin, 4);
                $b['yMin'] = round($yMin, 4);
                $b['xMax'] = round($xMax, 4);
                $b['yMax'] = round($yMax, 4);
                $b['area'] = $area;
                $filtered[] = $b;
            }
        }

        if (empty($filtered)) return [];

        usort($filtered, function ($a, $b) {
            return $b['area'] <=> $a['area'];
        });

        $merged = [];
        foreach ($filtered as $box) {
            $hasMerged = false;
            foreach ($merged as &$m) {
                $interXmin = max($box['xMin'], $m['xMin']);
                $interYmin = max($box['yMin'], $m['yMin']);
                $interXmax = min($box['xMax'], $m['xMax']);
                $interYmax = min($box['yMax'], $m['yMax']);

                $interW = max(0.0, $interXmax - $interXmin);
                $interH = max(0.0, $interYmax - $interYmin);
                $interArea = $interW * $interH;

                $unionArea = $box['area'] + $m['area'] - $interArea;
                $iou = ($unionArea > 0) ? ($interArea / $unionArea) : 0.0;
                $overlapMin = ($interArea > 0) ? ($interArea / min($box['area'], $m['area'])) : 0.0;

                // Cek calon box gabungan
                $newXmin = min($m['xMin'], $box['xMin']);
                $newYmin = min($m['yMin'], $box['yMin']);
                $newXmax = max($m['xMax'], $box['xMax']);
                $newYmax = max($m['yMax'], $box['yMax']);
                $newArea = ($newXmax - $newXmin) * ($newYmax - $newYmin);

                // Hanya gabungkan jika luas gabungan tidak melebihi 45% gambar
                if (($iou >= $iouThreshold || $overlapMin >= 0.50) && $newArea <= 0.45) {
                    $m['xMin'] = $newXmin;
                    $m['yMin'] = $newYmin;
                    $m['xMax'] = $newXmax;
                    $m['yMax'] = $newYmax;
                    $m['area'] = $newArea;
                    $hasMerged = true;
                    break;
                }
            }
            if (!$hasMerged) {
                $merged[] = $box;
            }
        }

        return array_slice($merged, 0, $maxBoxes);
    }
}


