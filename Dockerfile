# ...existing code...
FROM php:8.2-apache

# System deps and PHP extensions commonly used with Composer + DB + Razorpay
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip libzip-dev zip libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql zip gd mbstring xml \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

WORKDIR /var/www/html

# Copy composer files first for caching
COPY composer.json composer.lock* /var/www/html/
# Install Composer and project dependencies
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');" \
    && composer install --no-interaction --prefer-dist --optimize-autoloader

# Copy application code (including vendor/)
COPY . /var/www/html

# If your app uses a public/ folder, point DocumentRoot there (optional)
RUN if [ -d /var/www/html/public ]; then \
      sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf || true; \
    fi

RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
# ...existing code...