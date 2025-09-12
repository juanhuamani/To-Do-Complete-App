FROM composer:2 AS composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader

FROM php:8.2-cli
WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev \
    && docker-php-ext-install pdo_mysql

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install --no-interaction --prefer-dist
RUN php artisan key:generate

EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
