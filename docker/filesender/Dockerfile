# Stage 1: Builder - Préparation des fichiers et compilation
# Utilisation de PHP 8.4 pour avoir les versions récentes de librairies
FROM php:8.4-fpm-bookworm AS builder

# Installation des dépendances système
# libsqlite3-dev et pkg-config sont critiques pour pdo_sqlite
RUN apt-get update && apt-get install -y \
    curl tar git unzip libsqlite3-dev libpng-dev libicu-dev libonig-dev pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP
RUN docker-php-ext-install mbstring gd intl pdo pdo_sqlite

WORKDIR /build
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.4.2

# Récupération de FileSender
RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender

# Récupération de SimpleSAMLphp
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml

# Préparation de l'arborescence et configuration FPM
RUN mkdir -p /prep/var/www/html/files \
    /prep/var/www/html/tmp \
    /prep/var/www/html/log \
    /prep/var/www/html/db \
    && cp /usr/local/etc/php-fpm.d/www.conf.default /prep/www.conf \
    && sed -i 's/listen = 127.0.0.1:9000/listen = [::]:9000/g' /prep/www.conf \
    && chown -R 1000:1000 /prep/var/www/html

# Stage 2: Runtime - Passage sur une image stable avec Shell
FROM php:8.4-fpm-bookworm

# Réinstallation des dépendances runtime
RUN apt-get update && apt-get install -y \
    libsqlite3-0 libpng16-16 libicu72 pkg-config libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Installation des extensions dans le runtime également pour garantir la cohérence
RUN docker-php-ext-install pdo_sqlite mbstring gd intl

# Copie des fichiers depuis le builder
COPY --from=builder --chown=www-data:www-data /build/filesender /var/www/html
COPY --from=builder --chown=www-data:www-data /build/simplesaml /var/www/simplesaml
COPY --from=builder --chown=www-data:www-data /prep/var/www/html /var/www/html

# Injection de la configuration FPM
COPY --from=builder /prep/www.conf /usr/local/etc/php-fpm.d/www.conf

# FileSender v3 nécessite que certains dossiers soient accessibles en écriture
RUN chown -R www-data:www-data /var/www/html/tmp /var/www/html/log /var/www/html/files /var/www/html/db

USER www-data
