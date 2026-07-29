FROM php:8.3-cli

# Install dependensi & extension GD + PDO MySQL
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    zip \
    unzip \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql

WORKDIR /app

# Copy seluruh source code
COPY . /app

# Beri izin eksekusi script entrypoint
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

# Gunakan ENTRYPOINT agar selalu menjalankan entrypoint.sh bahkan jika startCommand di-override
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
