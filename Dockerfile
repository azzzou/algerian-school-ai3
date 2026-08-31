FROM php:8.2-apache

# تثبيت الحزم المطلوبة وأداة فك الضغط ونظام Git
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl

# مسح الكاش
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# تثبيت إضافات PHP
RUN docker-php-ext-install pdo_mysql gd

# جلب Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# تحديد مجلد العمل
WORKDIR /var/www/html

# نسخ الملفات
COPY . /var/www/html/

# فك ضغط ملف azzou2.zip تلقائياً
RUN if [ -f azzou2.zip ]; then \
        unzip -o -q azzou2.zip -d /var/www/html/ && \
        rm azzou2.zip; \
    fi \
    && rm -f /var/www/html/index.php

# التأكد من وجود ملف .env وضبط إعدادات البيئة
RUN if [ ! -f .env ]; then \
        cp .env.example .env || echo "APP_NAME=Laravel" > .env; \
    fi \
    && sed -i 's|APP_URL=.*|APP_URL=https://algerian-school-ai3-2.onrender.com|g' .env \
    && sed -i 's|APP_ENV=.*|APP_ENV=production|g' .env \
    && sed -i 's|APP_DEBUG=.*|APP_DEBUG=true|g' .env

# تثبيت حزم لارافيل عبر Composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

# توليد المفتاح، ربط التخزين، وتنظيف الكاش بالكامل
RUN php artisan key:generate --force \
    && php artisan storage:link --force \
    && php artisan config:clear \
    && php artisan cache:clear \
    && php artisan view:clear \
    && php artisan route:clear

# إنشاء مجلدات التخزين وإعطاء الصلاحيات المطلقة
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache bootstrap/cache public \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 777 storage bootstrap/cache \
    && a2enmod rewrite

# توجيه الأباتشي إلى مجلد public الخاص بلارافيل
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EXPOSE 80
