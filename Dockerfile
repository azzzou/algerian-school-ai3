
FROM php:8.2-apache

# تثبيت الحزم الأساسية وأدوات النظام
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# تثبيت إضافات PHP
RUN docker-php-ext-install pdo_mysql gd

# جلب Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# تحديد مجلد العمل
WORKDIR /var/www/html

# نسخ المشروع كامل
COPY . /var/www/html/

# إنشاء ملف البيئة SQLite جاهز فوراً
RUN echo "APP_NAME=Laravel" > .env \
    && echo "APP_ENV=production" >> .env \
    && echo "APP_DEBUG=false" >> .env \
    && echo "APP_URL=https://algerian-school-ai3-2.onrender.com" >> .env \
    && echo "DB_CONNECTION=sqlite" >> .env \
    && echo "DB_DATABASE=/var/www/html/database/database.sqlite" >> .env \
    && echo "SESSION_DRIVER=cookie" >> .env \
    && echo "SESSION_LIFETIME=120" >> .env

# تجهيز مجلدات التخزين وقاعدة البيانات وإعطاء الصلاحيات المطلقة لكي لا تتوقف أي صلاحية
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache bootstrap/cache public database \
    && touch database/database.sqlite \
    && chmod -R 777 storage bootstrap/cache database .env \
    && chown -R www-data:www-data /var/www/html

# تثبيت حزم الكومپوزر مع تخطي النصوص البرمجية التي تسبب المشاكل أثناء البناء
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# تشغيل الأرتيزان يدوياً وآمناً بعد اكتمال التثبيت
RUN COMPOSER_ALLOW_SUPERUSER=1 php artisan key:generate --force \
    && COMPOSER_ALLOW_SUPERUSER=1 php artisan storage:link --force \
    && COMPOSER_ALLOW_SUPERUSER=1 php artisan config:clear \
    && COMPOSER_ALLOW_SUPERUSER=1 php artisan cache:clear

# تفعيل الـ Apache Rewrite
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN a2enmod rewrite

EXPOSE 80

# التشغيل النهائي: تنفيذ المايغريشن عند الإقلاع ثم فتح الأباتشي
CMD ["sh", "-c", "php artisan migrate --force && apache2-foreground"]
