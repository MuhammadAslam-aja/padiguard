#!/bin/sh
# Tangkap PORT dari Railway environment variable, default ke 8080 jika tidak ada
PORT_NUM="${PORT:-8080}"

# Pastikan PORT_NUM hanya berisi angka
if ! echo "$PORT_NUM" | grep -qE '^[0-9]+$'; then
    PORT_NUM=8080
fi

# Aktifkan multi-worker (4 proses) pada PHP built-in server.
# Ini mencegah PHP server macet/blocking saat menangani multiple request / health check Railway!
export PHP_CLI_SERVER_WORKERS=4

echo "Starting PHP multi-worker server (4 workers) on 0.0.0.0:${PORT_NUM} with backend/index.php..."
exec php -S "0.0.0.0:${PORT_NUM}" -t backend backend/index.php

