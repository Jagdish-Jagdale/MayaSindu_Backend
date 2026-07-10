FROM php:8.2-apache

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    unzip \
    pkg-config \
    zlib1g-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo \
        pdo_mysql \
        mysqli \
        zip \
        gd \
        mbstring \
        xml \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite
RUN a2enmod rewrite

WORKDIR /var/www/html

# Install Composer from the official Composer image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Copy Composer files first for Docker cache
COPY composer.json composer.lock* ./

# Install dependencies
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-dev \
    --no-scripts

# Copy application files
COPY . .

# Run Composer scripts after application files exist
RUN composer run-script post-install-cmd --no-interaction || true

# Use public/ as Apache DocumentRoot if it exists
RUN if [ -d "/var/www/html/public" ]; then \
    sed -ri 's!/var/www/html!/var/www/html/public!g' \
    /etc/apache2/sites-available/000-default.conf; \
    fi

# Allow .htaccess rules
RUN printf '<Directory /var/www/html/>\nAllowOverride All\nRequire all granted\n</Directory>\n' \
    > /etc/apache2/conf-available/app.conf \
    && a2enconf app

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]