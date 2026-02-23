# Multi-stage Dockerfile pour FileSender v3.3 avec Nginx intégré
# Base: php:8.2-fpm-alpine

FROM php:8.2-fpm-alpine AS builder

# Arguments de build
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.2.3

# Installation des dépendances de build
RUN apk add --no-cache --virtual .build-deps \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    libxml2-dev \
    oniguruma-dev \
    zlib-dev \
    git \
    curl \
    tar

# Installation des extensions PHP requises
# - pdo_pgsql & pgsql: Support PostgreSQL pour FileSender et sessions SimpleSAMLphp
# - mbstring: Manipulation de chaînes multi-octets
# - xml & dom: Traitement XML pour SAML
# - intl: Support internationalization
# - gd: Traitement d'images
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        pgsql \
        mbstring \
        xml \
        intl \
        gd

# Téléchargement de FileSender depuis master3
WORKDIR /build
RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender

# Téléchargement de SimpleSAMLphp
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml

# Image finale
FROM php:8.2-fpm-alpine

# Metadata
ARG FILESENDER_VERSION=3.3
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts" \
      org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} avec Nginx intégré" \
      org.opencontainers.image.version="${FILESENDER_VERSION}"

# Installation des dépendances runtime et Nginx
RUN apk add --no-cache \
    postgresql-libs \
    libpng \
    libjpeg-turbo \
    freetype \
    icu-libs \
    libxml2 \
    oniguruma \
    zlib \
    nginx \
    supervisor \
    zlib-dev \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    libxml2-dev \
    oniguruma-dev \
    # Installation des extensions PHP (nécessaires pour PostgreSQL et SAML)
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        pgsql \
        mbstring \
        xml \
        intl \
        gd \
    # Nettoyage des dépendances de build pour réduire la taille de l'image
    && apk del zlib-dev postgresql-dev libpng-dev libjpeg-turbo-dev \
        freetype-dev icu-dev libxml2-dev oniguruma-dev

# Création de la structure des répertoires
RUN mkdir -p \
    /opt/filesender/filesender \
    /opt/filesender/simplesaml \
    /var/www/files \
    /var/www/tmp \
    /var/www/log \
    /run/nginx \
    /var/log/nginx \
    && chown -R www-data:www-data \
        /opt/filesender \
        /var/www/files \
        /var/www/tmp \
        /var/www/log \
        /run/nginx \
        /var/log/nginx

# Copie de FileSender et SimpleSAMLphp depuis le builder
COPY --from=builder --chown=www-data:www-data /build/filesender /opt/filesender/filesender
COPY --from=builder --chown=www-data:www-data /build/simplesaml /opt/filesender/simplesaml

# Configuration PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf \
    && echo "php_admin_value[error_log] = /proc/self/fd/2" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "php_admin_flag[display_errors] = off" >> /usr/local/etc/php-fpm.d/www.conf

# php.ini personnalisé - CRITIQUE pour éviter "headers already sent"
COPY php.ini /usr/local/etc/php/php.ini

# Assurer la writabilité du répertoire de sessions
RUN chown -R www-data:www-data /var/www/tmp

# Logs Nginx → stdout/stderr pour Loki/Kubernetes
RUN ln -sf /dev/stdout /var/log/nginx/filesender-access.log \
    && ln -sf /dev/stderr /var/log/nginx/filesender-error.log

# Configuration Nginx (sera remplacée par ConfigMap en production)
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/http.d/default.conf

# Configuration Supervisor pour gérer PHP-FPM et Nginx
COPY supervisord.conf /etc/supervisord.conf

# Exposition des ports
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Démarrage via Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
