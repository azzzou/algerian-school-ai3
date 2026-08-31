
FROM php:8.2-apache

# تثبيت الحزم المطلوبة
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

# إعطاء صلاحيات كاملة لكل الملفات لكي لا يظهر خطأ 403 أبداً
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html \
    && a2enmod rewrite

# ملاحظة: أبقينا المسار الافتراضي /var/www/html بدون توجيه معقد لكي لا يحدث أي خطأ في الـ DocumentRoot

EXPOSE 80
