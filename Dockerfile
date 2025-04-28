

FROM php:8.1-fpm 

RUN apt-get update && apt-get install -y \ 
       git unzip libzip-dev zip \ 
       && docker-php-ext-install zip pdo pdo_mysql

WORKDIR /var/www/html 

COPY ./app /var/www/html/ 

RUN chown -R www-data:www-data /var/www/html 

CMD ["php-fpm"]
