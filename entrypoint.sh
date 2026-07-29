#!/bin/sh
# Tangkap PORT dari Railway environment variable, default ke 8080 jika tidak ada
PORT_NUM="${PORT:-8080}"

# Pastikan PORT_NUM hanya berisi angka (jika Railway passing $PORT mentah)
if ! echo "$PORT_NUM" | grep -qE '^[0-9]+$'; then
    PORT_NUM=8080
fi

echo "Starting PHP server on 0.0.0.0:${PORT_NUM}..."
exec php -S "0.0.0.0:${PORT_NUM}" -t backend
