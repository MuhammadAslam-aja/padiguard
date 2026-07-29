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

# Expose port (Railway akan memberikan variabel $PORT dinamis)
EXPOSE 8080

# Gunakan shell form agar variabel $PORT dari Railway terekspansi dengan benar
CMD ["sh", "-c", "php -S 0.0.0.0:${PORT:-8080} -t backend"]
