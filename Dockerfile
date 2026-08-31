
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

# فك ضغط المشروع الحقيقي
RUN if [ -f composer.zip ]; then \
        unzip -o -q composer.zip -d /var/www/html/ && \
        rm composer.zip; \
    fi \
    && rm -f /var/www/html/index.php

# تثبيت حزم لارافيل تلقائياً عبر Composer داخل السيرفر
RUN composer install --no-dev --optimize-autoloader --no-interaction

# إنشاء مجلدات التخزين وإعطاء الصلاحيات الكاملة
RUN mkdir -p storage bootstrap/cache public \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 777 storage bootstrap/cache \
    && a2enmod rewrite

# توجيه الأباتشي إلى مجلد public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EXPOSE 80
