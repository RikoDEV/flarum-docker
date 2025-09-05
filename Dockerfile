# Stage 1: Build Flarum and dependencies
FROM alpine:3.22 AS builder

# Define build argument
ARG VERSION=v1.8.1

# Install Composer and build dependencies
RUN apk add --no-cache --no-progress \
    curl \
    php84 \
    php84-phar \
    php84-iconv \
    php84-mbstring \
    php84-openssl && \
    ln -sf /usr/bin/php84 /usr/bin/php && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    chmod +x /usr/local/bin/composer

# Set up Flarum
WORKDIR /flarum/app
RUN mkdir -p /flarum/app && \
    COMPOSER_CACHE_DIR="/tmp" composer create-project flarum/flarum:${VERSION} . && \
    composer clear-cache && \
    rm -rf /flarum/.composer /tmp/*

# Stage 2: Final runtime image
FROM alpine:3.22

# Metadata labels
LABEL description="Simple forum software for building great communities"
LABEL maintainer="riko.dev <kontakt@riko.dev>"

# Set environment variables
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

# Install runtime dependencies
RUN apk add --no-cache --no-progress \
    curl \
    git \
    icu-data-full \
    libcap \
    nginx \
    php84 \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-exif \
    php84-fileinfo \
    php84-fpm \
    php84-gd \
    php84-gmp \
    php84-iconv \
    php84-intl \
    php84-mbstring \
    php84-mysqlnd \
    php84-opcache \
    php84-pecl-apcu \
    php84-openssl \
    php84-pdo \
    php84-pdo_mysql \
    php84-phar \
    php84-session \
    php84-tokenizer \
    php84-xmlwriter \
    php84-zip \
    php84-zlib \
    su-exec \
    s6 && \
    ln -sf /usr/bin/php84 /usr/bin/php && \
    setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/nginx

# Configure PHP
RUN sed -i "s/memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/" /etc/php84/php.ini

# Copy Composer from builder stage
COPY --from=builder /usr/local/bin/composer /usr/local/bin/composer

# Copy Flarum from builder stage
COPY --from=builder /flarum/app /flarum/app

# Create runtime directories
RUN mkdir -p /run/php

# Copy configuration files
COPY rootfs /
RUN chmod +x /usr/local/bin/* /etc/s6.d/*/run /etc/s6.d/.s6-svscan/*

# Define volumes
VOLUME ["/etc/nginx/flarum", "/flarum/app/extensions", "/flarum/app/public/assets", "/flarum/app/storage/logs"]

# Expose port
EXPOSE ${FLARUM_PORT}

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/startup"]