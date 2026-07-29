FROM php:8.3-cli

# Install sistem dependensi untuk GD (JPEG, PNG, WebP) & PDO MySQL
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

# Jalankan PHP Built-in Server mengarah ke folder backend
CMD php -S 0.0.0.0:${PORT:-8080} -t backend
