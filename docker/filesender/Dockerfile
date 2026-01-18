# Stage 1: Builder - Préparation des fichiers et compilation
FROM php:8.4-fpm-bookworm AS builder

RUN apt-get update && apt-get install -y \
    curl tar git unzip libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_sqlite

WORKDIR /build
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.2.3

RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml

RUN mkdir -p /prep/var/www/html/files \
    /prep/var/www/html/tmp \
    /prep/var/www/html/log \
    /prep/var/www/html/db \
    /prep/usr/local/etc/php-fpm.d \
    /prep/usr/local/etc/php/conf.d

RUN cp /usr/local/etc/php-fpm.d/www.conf.default /prep/usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/listen = 127.0.0.1:9000/listen = [::]:9000/g' /prep/usr/local/etc/php-fpm.d/www.conf

RUN echo "extension=pdo_sqlite.so" > /prep/usr/local/etc/php/conf.d/docker-php-ext-pdo_sqlite.ini
RUN cp $(php-config --extension-dir)/pdo_sqlite.so /prep/pdo_sqlite.so
RUN chown -R 1000:1000 /prep/var/www/html

# Stage 2: Runtime - Image sécurisée Docker Hardened
FROM dhi.io/php:8.5.0-fpm
ARG FILESENDER_VERSION=3.3
WORKDIR /var/www/html

COPY --from=builder --chown=1000:1000 /build/filesender /var/www/html
COPY --from=builder --chown=1000:1000 /build/simplesaml /var/www/simplesaml
COPY --from=builder --chown=1000:1000 /prep/var/www/html /var/www/html
COPY --from=builder /prep/usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --from=builder /prep/usr/local/etc/php/conf.d/docker-php-ext-pdo_sqlite.ini /usr/local/etc/php/conf.d/docker-php-ext-pdo_sqlite.ini
COPY --from=builder /prep/pdo_sqlite.so /usr/local/lib/php/extensions/no-debug-non-zts-20240924/pdo_sqlite.so

USER 1000
