# Multi-stage Dockerfile pour FileSender v3.x - Image légère OIDC/Fake
FROM php:8.2-fpm-alpine AS builder

ARG FILESENDER_VERSION=master3

# Dépendances de build
RUN apk add --no-cache --virtual .build-deps \
    git \
    curl \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Téléchargement de FileSender
WORKDIR /build
RUN git clone --depth 1 --branch ${FILESENDER_VERSION} https://github.com/filesender/filesender.git filesender

# Installation de la dépendance OIDC (jumbojett/openid-connect-php)
WORKDIR /build/filesender/optional-dependencies/oidc
RUN composer install --no-dev --optimize-autoloader

# Image finale - SANS SimpleSAMLphp
FROM php:8.2-fpm-alpine

ARG FILESENDER_VERSION=3.3
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts" \
      org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} - Lightweight OIDC/Fake (no SimpleSAMLphp)" \
      org.opencontainers.image.version="${FILESENDER_VERSION}"

# Dépendances runtime
RUN apk add --no-cache \
    postgresql-libs \
    libpng \
    libjpeg-turbo \
    freetype \
    icu-libs \
    libxml2 \
    oniguruma \
    nginx \
    supervisor \
    curl

# Extensions PHP
RUN apk add --no-cache --virtual .build-deps \
    postgresql-dev libpng-dev libjpeg-turbo-dev freetype-dev \
    icu-dev libxml2-dev oniguruma-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo_pgsql pgsql mbstring xml intl gd \
    && apk del .build-deps

# Structure des répertoires FileSender et Nginx
RUN mkdir -p \
    /opt/filesender/filesender/files \
    /opt/filesender/filesender/tmp \
    /opt/filesender/filesender/log \
    /run/nginx \
    /var/lib/nginx/tmp/client_body \
    /var/lib/nginx/tmp/proxy \
    /var/lib/nginx/tmp/fastcgi \
    /var/lib/nginx/tmp/uwsgi \
    /var/lib/nginx/tmp/scgi \
    /var/log/nginx \
    && chown -R www-data:www-data /opt/filesender \
    && chown -R nginx:nginx /run/nginx /var/lib/nginx /var/log/nginx

# Copie de FileSender avec dépendances OIDC
COPY --from=builder --chown=www-data:www-data /build/filesender /opt/filesender/filesender

# PHP-FPM config
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf

# Nginx config
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/http.d/default.conf

# Supervisor config
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
