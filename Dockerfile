FROM php:8.1.3-alpine as runtime

ARG UID=1000
ARG GID=1000

ENV COMPOSER_HOME="/tmp/composer"
ENV PHPREDIS_VERSION="5.3.7"
ENV SWOOLE_VERSION="v4.8.7"

RUN set -x \
    && apk add --no-cache \
        postgresql-libs \
        npm \
    && apk add --no-cache --virtual .build-deps \
        postgresql-dev \
        autoconf \
        openssl \
        curl-dev \
        make \
        g++ \
    # install phpredis extension \
    && docker-php-source extract \
    && mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/redis/ --strip 1 \
    && mkdir -p /usr/src/php/ext/swoole \
    && curl -L https://github.com/swoole/swoole-src/archive/$SWOOLE_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/swoole --strip 1 \
    && docker-php-ext-configure swoole --enable-swoole-curl \
    && CFLAGS="$CFLAGS -D_GNU_SOURCE" docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        sockets \
        redis \
        swoole \
        opcache \
        pcntl \
        intl \
        exif \
        1>/dev/null \
    # make clean up
    && docker-php-source delete \
    && apk del .build-deps

COPY --from=composer:2.2.6 /usr/bin/composer /usr/bin/composer

COPY php.ini /usr/local/etc/php/conf.d/

RUN addgroup -S php -g $GID \
    && adduser -u $UID -S -G php php \
    && mkdir /app \
    && chown php:php /app

# use an unprivileged user by default
USER php:php

# use directory with application sources by default
WORKDIR /app