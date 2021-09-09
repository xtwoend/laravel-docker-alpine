FROM alpine:latest

# Setup document root
RUN mkdir -p /var/www/app
WORKDIR /var/www/app/

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip curl nginx supervisor busybox-suid

# Installing PHP
RUN apk add --no-cache php8 \
    php8-common \
    php8-fpm \
    php8-pdo \
    php8-opcache \
    php8-zip \
    php8-phar \
    php8-iconv \
    php8-cli \
    php8-curl \
    php8-openssl \
    php8-mbstring \
    php8-tokenizer \
    php8-fileinfo \
    php8-json \
    php8-xml \
    php8-xmlwriter \
    php8-simplexml \
    php8-dom \
    php8-pdo_mysql \
    php8-pdo_sqlite \
    php8-tokenizer \
    php8-pecl-redis \
    php8-pecl-mongodb

RUN ln -s /usr/bin/php8 /usr/bin/php

# Installing composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY ./deploy/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
# COPY ./deploy/supervisor/conf.d/worker.conf /etc/supervisor/conf.d/worker.conf

COPY ./deploy/php/www.conf /etc/php8/php-fpm.d/www.conf
COPY ./deploy/php/php.ini /etc/php8/conf.d/custom.ini

# Configure nginx
# RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY ./deploy/nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /run/nginx/
RUN touch /run/nginx/nginx.pid

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Run crondjob
RUN echo '*  *  *  *  * /usr/bin/php  /var/www/app/artisan schedule:run >> /dev/null 2>&1' > /var/spool/cron/crontabs/nobody

# Building process
COPY --chown=nobody . /var/www/app/
RUN composer install --no-dev

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/app && \
    chown -R nobody.nobody /run && \
    chown -R nobody.nobody /var/lib/nginx && \
    chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Configure Laravel logs
RUN ln -sf /dev/stdout /var/www/app/storage/laravel.log

RUN php /var/www/app/artisan storage:link

EXPOSE 8080

# Run app via supervisor
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
