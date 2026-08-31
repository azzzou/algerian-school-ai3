
FROM php:8.2-apache

# تثبيت الحزم المطلوبة، أداة فك الضغط، Git و Node.js
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    nodejs \
    npm

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

# فك ضغط المشروع وتفادي مشاكل الاستبدال
RUN if [ -f composer.zip ]; then \
        unzip -o -q composer.zip -d /var/www/html/ && \
        rm composer.zip; \
    fi \
    && rm -f /var/www/html/index.php

# التأكد من وجود ملف .env وإنشاؤه تلقائياً
RUN if [ ! -f .env ]; then \
        cp .env.example .env || echo "APP_NAME=Laravel" > .env; \
    fi \
    && sed -i 's|APP_URL=.*|APP_URL=https://algerian-school-ai3-2.onrender.com|g' .env \
    && sed -i 's|APP_ENV=.*|APP_ENV=production|g' .env \
    && sed -i 's|APP_DEBUG=.*|APP_DEBUG=true|g' .env

# تثبيت حزم لارافيل عبر Composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

# تثبيت حزم Node بشكل آمن يتجاوز مشاكل الصلاحيات الظاهرة في اللوغات
RUN if [ -f package.json ]; then \
        npm install --unsafe-perm && npm run build; \
    fi

# توليد المفتاح، ربط التخزين، وتنظيف الكاش بالكامل
RUN php artisan key:generate --force \
    && php artisan storage:link --force \
    && php artisan config:clear \
    && php artisan cache:clear \
    && php artisan view:clear \
    && php artisan route:clear

# إنشاء مجلدات التخزين وإعطاء الصلاحيات الكاملة
RUN mkdir -p storage bootstrap/cache public \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 777 storage bootstrap/cache \
    && a2enmod rewrite

# توجيه الأباتشي إلى مجلد public الخاص بلارافيل
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EXPOSE 80
