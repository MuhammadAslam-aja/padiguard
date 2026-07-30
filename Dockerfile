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

# Naikkan limit upload PHP (50MB) & aktifkan output buffering (4096) agar respon JSON 100% murni tanpa warning PHP header
RUN echo "upload_max_filesize = 50M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "output_buffering = 4096" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "display_errors = Off" >> /usr/local/etc/php/conf.d/uploads.ini

WORKDIR /app

# Copy seluruh source code
COPY . /app

# Beri izin eksekusi script entrypoint
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
