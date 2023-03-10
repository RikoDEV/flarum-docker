FROM alpine:3.17

LABEL description="Simple forum software for building great communities" \
      maintainer="riko.dev <kontakt@riko.dev>"

ARG VERSION=v1.7.0

ENV GID=991 \
    UID=991 \
    UPLOAD_MAX_SIZE=50M \
    PHP_MEMORY_LIMIT=128M \
    OPCACHE_MEMORY_LIMIT=128 \
    DB_HOST=mariadb \
    DB_USER=flarum \
    DB_NAME=flarum \
    DB_PORT=3306 \
    FLARUM_TITLE=Docker-Flarum \
    DEBUG=false \
    LOG_TO_STDOUT=false \
    GITHUB_TOKEN_AUTH=false \
    FLARUM_PORT=8888

RUN apk add --no-progress --no-cache \
    curl \
    git \
    icu-data-full \
    libcap \
    nginx \
    php81 \
    php81-ctype \
    php81-curl \
    php81-dom \
    php81-exif \
    php81-fileinfo \
    php81-fpm \
    php81-gd \
    php81-gmp \
    php81-iconv \
    php81-intl \
    php81-mbstring \
    php81-mysqlnd \
    php81-opcache \
    php81-pecl-apcu \
    php81-openssl \
    php81-pdo \
    php81-pdo_mysql \
    php81-phar \
    php81-session \
    php81-tokenizer \
    php81-xmlwriter \
    php81-zip \
    php81-zlib \
    su-exec \
    s6 \
    && ln -s /usr/bin/php81 /usr/bin/php

  RUN cd /tmp

  RUN curl --progress-bar http://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  
  RUN sed -i 's/memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/' /etc/php81/php.ini

  RUN chmod +x /usr/local/bin/composer

  RUN mkdir -p /run/php /flarum/app

  RUN COMPOSER_CACHE_DIR="/tmp" composer create-project flarum/flarum:$VERSION /flarum/app

  RUN composer clear-cache

  RUN rm -rf /flarum/.composer /tmp/*
  
  RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/nginx

COPY rootfs /
RUN chmod +x /usr/local/bin/* /etc/s6.d/*/run /etc/s6.d/.s6-svscan/*
VOLUME /etc/nginx/flarum /flarum/app/extensions /flarum/app/public/assets /flarum/app/storage/logs
CMD ["/usr/local/bin/startup"]
