FROM php:8.2-apache

# Install system dependencies & PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install pdo_mysql zip bcmath gd

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . /var/www/html

# Ensure public folder exists and has a fallback index.php if missing
RUN mkdir -p /var/www/html/public && \
    if [ ! -f /var/www/html/public/index.php ]; then \
        echo "<?php echo '<h1>Azzou School Laravel Project is Live! 🚀</h1>'; ?>" > /var/www/html/public/index.php; \
    fi

# Point Apache DocumentRoot directly to Laravel public folder
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -s 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -s 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# Set permissions for storage and public
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
