
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

# نسخ الملفات إلى الحاوية
COPY . /var/www/html/

# فك ضغط ملف azzou3.zip تلقائياً
RUN if [ -f azzou3.zip ]; then \
        unzip -o -q azzou3.zip -d /var/www/html/ && \
        rm azzou3.zip; \
    fi \
    && rm -f /var/www/html/index.php

# إذا فُك الضغط داخل مجلد فرعي، نقله إلى الجذر لتفادي مشاكل المسارات
RUN if [ -d /var/www/html/school_dashboard ]; then \
        cp -r /var/www/html/school_dashboard/* /var/www/html/ && \
        rm -rf /var/www/html/school_dashboard; \
    fi

# إنشاء ملف .env جاهز للإنتاج فوراً وبدون تعقيد
RUN echo "APP_NAME=Laravel" > .env \
    && echo "APP_ENV=production" >> .env \
    && echo "APP_DEBUG=false" >> .env \
    && echo "APP_URL=https://algerian-school-ai3-2.onrender.com" >> .env \
    && echo "LOG_CHANNEL=stack" >> .env \
    && echo "LOG_DEPRECATIONS_CHANNEL=null" >> .env \
    && echo "LOG_LEVEL=debug" >> .env \
    && echo "DB_CONNECTION=sqlite" >> .env \
    && echo "DB_DATABASE=/var/www/html/database/database.sqlite" >> .env \
    && echo "SESSION_DRIVER=cookie" >> .env \
    && echo "SESSION_LIFETIME=120" >> .env

# تثبيت حزم لارافيل عبر Composer بدون ملفات التطوير
RUN composer install --no-dev --optimize-autoloader --no-interaction

# توليد المفتاح، ربط التخزين، وتنظيف الكاش بالكامل أثناء البناء
RUN php artisan key:generate --force \
    && php artisan storage:link --force \
    && php artisan config:clear \
    && php artisan cache:clear \
    && php artisan view:clear \
    && php artisan route:clear

# إنشاء مجلدات التخزين وإعطاء الصلاحيات المطلقة
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache bootstrap/cache public database \
    && touch database/database.sqlite \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 777 storage bootstrap/cache database \
    && a2enmod rewrite

# توجيه الأباتشي إلى مجلد public الخاص بلارافيل
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EXPOSE 80

# تشغيل الـ Migrations تلقائياً عند بدء إقلاع الحاوية ثم تشغيل الأباتشي
CMD ["sh", "-c", "php artisan migrate --force && apache2-foreground"]
