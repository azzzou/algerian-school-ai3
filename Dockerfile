FROM php:8.2-apache

# تثبيت الحزم المطلوبة وأداة فك الضغط
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

# نسخ جميع الملفات
COPY . /var/www/html/

# السحر هنا: -o لفك الضغط والموافقة التلقائية على الاستبدال
RUN if [ -f composer.zip ]; then \
        unzip -o -q composer.zip -d /var/www/html/ && \
        rm composer.zip; \
    fi

# إنشاء مجلدات التخزين والكاش وإعطاء الصلاحيات الكاملة
RUN mkdir -p storage bootstrap/cache public \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 777 storage bootstrap/cache \
    && a2enmod rewrite

EXPOSE 80
