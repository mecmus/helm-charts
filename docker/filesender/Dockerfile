# Utilisation de l'image officielle PHP 8.4 (Dernière stable) sur Debian Bookworm
FROM php:8.4-fpm-bookworm

# Installation de TOUTES les dépendances (Build + Runtime) en une seule fois
# On inclut libonig-dev (mbstring), libpng-dev (gd), libicu-dev (intl), libsqlite3-dev (pdo_sqlite)
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    unzip \
    libsqlite3-dev \
    libpng-dev \
    libicu-dev \
    libonig-dev \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP requises
RUN docker-php-ext-install pdo_sqlite mbstring gd intl

WORKDIR /var/www/html

ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.4.2

# Récupération de FileSender (Branche master3 pour la v3.x)
RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git .

# Récupération de SimpleSAMLphp (v2.4+ requis pour PHP 8.4)
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} /var/www/simplesaml

# Création des dossiers nécessaires et gestion des permissions
# Note: On utilise l'utilisateur www-data par défaut de l'image officielle
RUN mkdir -p tmp files log db \
    && chown -R www-data:www-data /var/www/html /var/www/simplesaml

# Configuration PHP-FPM pour écouter sur toutes les interfaces (Fix 502)
RUN sed -i 's/listen = 127.0.0.1:9000/listen = [::]:9000/g' /usr/local/etc/php-fpm.d/www.conf.default \
    && cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf

# FileSender v3 peut utiliser SQLite par défaut si configuré dans values.yaml
VOLUME ["/var/www/html/files", "/var/www/html/db"]

USER www-data
