FROM php:8.2-apache

# تثبيت الحزم المطلوبة وأداة فك الضغط unzip
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

# نسخ ملفات المشروع بالكامل (بما فيها الملف المضغوط الموجود في غيتهاب)
COPY . /var/www/html/

# السحر هنا: إذا وجدنا أي ملف zip في المجلد، سنقوم بفك ضخمه تلقائياً وترتيب الملفات
RUN if ls *.zip 1> /dev/null 2>&1; then \
        unzip -q *.zip -d temp_extracted && \
        cp -r temp_extracted/* . && \
        rm -rf temp_extracted *.zip; \
    fi

# إنشاء المجلدات الضرورية وإعطاؤها الصلاحيات الكاملة
RUN mkdir -p storage bootstrap/cache public \
    && chmod -R 777 storage bootstrap/cache

# تفعيل الـ rewrite
RUN a2enmod rewrite

# توجيه مسار الأباتشي إلى مجلد public بشكل نهائي
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EXPOSE 80
