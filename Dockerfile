FROM php:8.1.4-alpine as runtime

ARG UID=1000
ARG GID=1000

ENV COMPOSER_HOME="/tmp/composer"
ENV PHPREDIS_VERSION="5.3.7"
ENV SWOOLE_VERSION="v4.8.8"

RUN set -x \
    && apk add --no-cache \
        curl \
        npm \
        postgresql-libs \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
        postgresql-dev \
        curl-dev \
        openssl-dev \
        pcre-dev \
        pcre2-dev \
        zlib-dev \
        autoconf \
        make \
    && docker-php-source extract \
    && docker-php-ext-install -j$(nproc) \
            pdo_pgsql \
            sockets \
            opcache \
            pcntl \
            intl \
            exif \
            1>/dev/null \
    && mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/redis/ --strip 1 \
    && docker-php-ext-install -j$(nproc) redis \
    && mkdir /usr/src/php/ext/swoole \
        && curl -sfL https://github.com/swoole/swoole-src/archive/$SWOOLE_VERSION.tar.gz -o swoole.tar.gz \
        && tar xfz swoole.tar.gz --strip-components=1 -C /usr/src/php/ext/swoole \
        && cd /usr/src/php/ext/swoole \
        && phpize \
        && ./configure --enable-openssl --enable-swoole-curl --enable-http2 \
        && make && make install \
        && docker-php-ext-install -j$(nproc) swoole \
        && rm -f swoole.tar.gz $HOME/.composer/*-old.phar \
    && docker-php-source delete \
    && apk del .build-deps

COPY --from=composer:2.3.4 /usr/bin/composer /usr/bin/composer

COPY php.ini /usr/local/etc/php/conf.d/

RUN addgroup -S php -g $GID \
    && adduser -u $UID -S -G php php \
    && mkdir /app \
    && chown php:php /app

# use an unprivileged user by default
USER php:php

# use directory with application sources by default
WORKDIR /app
