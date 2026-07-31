<?php
// mailer.php - Lightweight SMTP Email Sender untuk PadiGuard
// Menggunakan Gmail SMTP dengan STARTTLS via PHP stream sockets (tanpa library eksternal)

function sendPadiGuardEmail($toEmail, $toName, $subject, $htmlBody) {
    // ====== KONFIGURASI SMTP (Baca dari env, fallback ke default) ====== 
    $smtpHost     = getEnvVar('MAIL_HOST',     'smtp.gmail.com');
    $smtpPort     = (int)(getEnvVar('MAIL_PORT', '587'));
    $smtpUser     = getEnvVar('MAIL_USERNAME', 'enaayyy@gmail.com');
    $smtpPass     = getEnvVar('MAIL_PASSWORD', 'hnsm vnel muxy doxd');
    $fromEmail    = getEnvVar('MAIL_FROM',     'enaayyy@gmail.com');
    $fromName     = getEnvVar('MAIL_FROM_NAME','PadiGuard');

    if (empty($smtpUser) || empty($smtpPass)) {
        error_log('[PadiGuard Mailer] MAIL_USERNAME atau MAIL_PASSWORD tidak dikonfigurasi.');
        return false;
    }

    // ====== BUKA KONEKSI TCP ke SMTP Server ======
    // Timeout 8 detik agar tidak melebihi Dio client timeout (15 detik)
    $errno  = 0;
    $errstr = '';
    $ctx    = stream_context_create([
        'ssl' => [
            'verify_peer'       => false,
            'verify_peer_name'  => false,
            'allow_self_signed' => true,
        ]
    ]);

    $socket = null;
    $useSSL = false;

    // Coba port 587 (STARTTLS) dulu
    $socket = @stream_socket_client(
        "tcp://{$smtpHost}:587",
        $errno, $errstr, 8,
        STREAM_CLIENT_CONNECT,
        $ctx
    );

    // Fallback: coba port 465 (SSL langsung) jika 587 gagal
    if (!$socket) {
        $socket = @stream_socket_client(
            "ssl://{$smtpHost}:465",
            $errno, $errstr, 8,
            STREAM_CLIENT_CONNECT,
            $ctx
        );
        $useSSL = true;
    }

    if (!$socket) {
        error_log("[PadiGuard Mailer] Gagal konek ke SMTP 587 dan 465: {$errstr} ({$errno})");
        return false;
    }

    stream_set_timeout($socket, 8);

    // Helper: baca respons SMTP (bisa multiline)
    $readResp = function() use ($socket) {
        $resp = '';
        while ($line = @fgets($socket, 1024)) {
            $resp .= $line;
            if (strlen($line) >= 4 && $line[3] === ' ') break;
            $info = stream_get_meta_data($socket);
            if ($info['timed_out']) break;
        }
        return $resp;
    };

    // Helper: kirim perintah SMTP dan baca respons
    $cmd = function($command) use ($socket, $readResp) {
        fwrite($socket, $command . "\r\n");
        return $readResp();
    };

    // ====== HANDSHAKE SMTP ======
    $resp = $readResp(); // 220 greeting
    if (strpos($resp, '220') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] SMTP greeting gagal: {$resp}");
        return false;
    }

    // EHLO
    $resp = $cmd("EHLO padiguard.app");
    if (strpos($resp, '250') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] EHLO gagal: {$resp}");
        return false;
    }

    // Jika port 587 (bukan SSL langsung), lakukan STARTTLS
    if (!$useSSL) {
        $resp = $cmd("STARTTLS");
        if (strpos($resp, '220') !== 0) {
            fclose($socket);
            error_log("[PadiGuard Mailer] STARTTLS gagal: {$resp}");
            return false;
        }

        // Upgrade stream ke TLS
        $tlsOk = @stream_socket_enable_crypto(
            $socket, true,
            STREAM_CRYPTO_METHOD_TLS_CLIENT
        );
        if (!$tlsOk) {
            fclose($socket);
            error_log("[PadiGuard Mailer] Upgrade TLS gagal.");
            return false;
        }

        // EHLO ulang setelah TLS
        $cmd("EHLO padiguard.app");
    }

    // AUTH LOGIN
    $resp = $cmd("AUTH LOGIN");
    if (strpos($resp, '334') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] AUTH LOGIN gagal: {$resp}");
        return false;
    }

    // Kirim username (base64)
    $resp = $cmd(base64_encode($smtpUser));
    if (strpos($resp, '334') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] Username SMTP ditolak.");
        return false;
    }

    // Kirim password (base64)
    $resp = $cmd(base64_encode($smtpPass));
    if (strpos($resp, '235') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] Password SMTP ditolak. Pastikan App Password benar.");
        return false;
    }

    // ====== KIRIM EMAIL ======
    // MAIL FROM
    $resp = $cmd("MAIL FROM: <{$fromEmail}>");
    if (strpos($resp, '250') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] MAIL FROM ditolak: {$resp}");
        return false;
    }

    // RCPT TO
    $resp = $cmd("RCPT TO: <{$toEmail}>");
    if (strpos($resp, '250') !== 0 && strpos($resp, '251') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] RCPT TO ditolak: {$resp}");
        return false;
    }

    // DATA
    $resp = $cmd("DATA");
    if (strpos($resp, '354') !== 0) {
        fclose($socket);
        error_log("[PadiGuard Mailer] DATA ditolak: {$resp}");
        return false;
    }

    // ====== SUSUN PESAN EMAIL ======
    $boundary  = 'padiguard_' . md5(microtime());
    $encodedFrom = '=?UTF-8?B?' . base64_encode($fromName) . '?=';
    $encodedTo   = '=?UTF-8?B?' . base64_encode($toName)   . '?=';
    $encodedSubj = '=?UTF-8?B?' . base64_encode($subject)  . '?=';

    // Text fallback (strip HTML tags)
    $textBody = strip_tags(str_replace(['<br>', '<br/>', '<br />', '</p>', '</div>'], "\n", $htmlBody));
    $textBody = preg_replace('/\n{3,}/', "\n\n", $textBody);

    $message  = "From: {$encodedFrom} <{$fromEmail}>\r\n";
    $message .= "To: {$encodedTo} <{$toEmail}>\r\n";
    $message .= "Subject: {$encodedSubj}\r\n";
    $message .= "Date: " . date('r') . "\r\n";
    $message .= "MIME-Version: 1.0\r\n";
    $message .= "Content-Type: multipart/alternative; boundary=\"{$boundary}\"\r\n";
    $message .= "X-Mailer: PadiGuard PHP Mailer\r\n";
    $message .= "\r\n";

    // Part 1: Plain Text
    $message .= "--{$boundary}\r\n";
    $message .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $message .= "Content-Transfer-Encoding: quoted-printable\r\n\r\n";
    $message .= quoted_printable_encode($textBody) . "\r\n";

    // Part 2: HTML
    $message .= "--{$boundary}\r\n";
    $message .= "Content-Type: text/html; charset=UTF-8\r\n";
    $message .= "Content-Transfer-Encoding: quoted-printable\r\n\r\n";
    $message .= quoted_printable_encode($htmlBody) . "\r\n";

    $message .= "--{$boundary}--\r\n";
    $message .= "\r\n.\r\n"; // End of DATA

    fwrite($socket, $message);
    $resp = $readResp();

    // QUIT
    $cmd("QUIT");
    fclose($socket);

    $success = (strpos($resp, '250') === 0);
    if (!$success) {
        error_log("[PadiGuard Mailer] DATA response: {$resp}");
    }
    return $success;
}

// ============================================================
// Template Email OTP Reset Password (HTML Premium)
// ============================================================
function buildOtpEmailHtml($userName, $otp, $expiryMinutes = 15) {
    $year = date('Y');
    return <<<HTML
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Reset Password PadiGuard</title>
</head>
<body style="margin:0;padding:0;background:#0f172a;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0f172a;padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="520" cellpadding="0" cellspacing="0" style="background:#1e293b;border-radius:20px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,0.5);">
          
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#166534 0%,#15803d 50%,#22c55e 100%);padding:36px 40px;text-align:center;">
              <div style="display:inline-block;background:rgba(255,255,255,0.15);border-radius:50%;width:64px;height:64px;line-height:64px;margin-bottom:16px;font-size:32px;">🌾</div>
              <h1 style="color:#ffffff;font-size:26px;font-weight:700;margin:0 0 6px;">PadiGuard</h1>
              <p style="color:rgba(255,255,255,0.8);font-size:13px;margin:0;">Sistem Deteksi Hama & Kematangan Padi</p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:40px 40px 32px;">
              <h2 style="color:#f1f5f9;font-size:20px;font-weight:600;margin:0 0 12px;">Reset Password Akun Anda</h2>
              <p style="color:#94a3b8;font-size:14px;line-height:1.6;margin:0 0 28px;">
                Halo <strong style="color:#e2e8f0;">{$userName}</strong>, kami menerima permintaan reset password untuk akun PadiGuard Anda.
                Gunakan kode OTP berikut untuk membuat password baru.
              </p>

              <!-- OTP Box -->
              <div style="background:#0f172a;border:2px solid #22c55e;border-radius:16px;padding:28px;text-align:center;margin-bottom:28px;">
                <p style="color:#64748b;font-size:12px;text-transform:uppercase;letter-spacing:2px;margin:0 0 12px;">Kode OTP Anda</p>
                <div style="font-size:42px;font-weight:700;letter-spacing:12px;color:#22c55e;font-family:'Courier New',monospace;">{$otp}</div>
                <p style="color:#64748b;font-size:12px;margin:14px 0 0;">⏱️ Kode berlaku selama <strong style="color:#fbbf24;">{$expiryMinutes} menit</strong></p>
              </div>

              <!-- Warning -->
              <div style="background:rgba(251,191,36,0.08);border:1px solid rgba(251,191,36,0.3);border-radius:10px;padding:14px 16px;margin-bottom:24px;">
                <p style="color:#fbbf24;font-size:13px;margin:0;">
                  ⚠️ Jangan bagikan kode ini kepada siapapun. Tim PadiGuard tidak pernah meminta kode OTP Anda.
                </p>
              </div>

              <p style="color:#64748b;font-size:13px;line-height:1.6;margin:0;">
                Jika Anda tidak meminta reset password, abaikan email ini. Akun Anda tetap aman.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background:#0f172a;padding:20px 40px;text-align:center;border-top:1px solid #1e293b;">
              <p style="color:#475569;font-size:12px;margin:0;">
                © {$year} PadiGuard — Sistem Klasifikasi Hama & Kematangan Tanaman Padi<br>
                Email ini dikirim otomatis, harap tidak membalas.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
HTML;
}
