# Stage 1: Builder - Préparation des fichiers et compilation
FROM php:8.4-fpm-bookworm AS builder

# Installation des dépendances système nécessaires à la compilation des extensions
RUN apt-get update && apt-get install -y \
    curl tar git unzip libsqlite3-dev libpng-dev libicu-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP requises par FileSender v3
RUN docker-php-ext-install pdo_sqlite mbstring gd intl

WORKDIR /build
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.4.2

# Récupération de FileSender
RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender

# Récupération de SimpleSAMLphp (v2.4+ requis pour PHP 8.4)
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml

# Préparation de l'arborescence
RUN mkdir -p /prep/var/www/html/files \
    /prep/var/www/html/tmp \
    /prep/var/www/html/log \
    /prep/var/www/html/db \
    /prep/usr/local/etc/php-fpm.d \
    /prep/usr/local/etc/php/conf.d

# Configuration FPM (Fix 502) : On écoute sur toutes les interfaces sur le port 9000
RUN cp /usr/local/etc/php-fpm.d/www.conf.default /prep/usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/listen = 127.0.0.1:9000/listen = [::]:9000/g' /prep/usr/local/etc/php-fpm.d/www.conf

# Script de détection dynamique et copie des extensions pour le runtime
# Ce script crée une liste de commandes COPY pour le stage final (simulation via un répertoire tempo)
RUN EXT_DIR=$(php-config --extension-dir) \
    && mkdir -p /prep/extensions \
    && cp $EXT_DIR/pdo_sqlite.so /prep/extensions/ \
    && cp $EXT_DIR/mbstring.so /prep/extensions/ \
    && cp $EXT_DIR/gd.so /prep/extensions/ \
    && cp $EXT_DIR/intl.so /prep/extensions/ \
    && echo $EXT_DIR > /prep/ext_dir_path

# Fixer les droits pour l'utilisateur 1000 (standard non-root)
RUN chown -R 1000:1000 /prep/var/www/html

# Stage 2: Runtime - Passage sur l'image sécurisée DHI
# On utilise la version 8.5 car c'est celle de ton dernier test, 
# mais avec une logique de copie de répertoire d'extension dynamique
FROM dhi.io/php:8.5.0-fpm

WORKDIR /var/www/html

# On récupère le chemin dynamique du répertoire d'extensions du Builder
# Note: On doit s'assurer que l'image DHI utilise une structure compatible
# Si DHI utilise /opt/php-8.5, on doit viser ce dossier.
# Le log indiquait: /opt/php-8.5/lib/php/extensions/no-debug-non-zts-20250925/

COPY --from=builder --chown=1000:1000 /build/filesender /var/www/html
COPY --from=builder --chown=1000:1000 /build/simplesaml /var/www/simplesaml
COPY --from=builder --chown=1000:1000 /prep/var/www/html /var/www/html

# Injection des configurations
COPY --from=builder /prep/usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

# Injection des extensions dans le BON répertoire (détecté via le log utilisateur)
# IMPORTANT: Le chemin 20250925 correspond à l'erreur vue dans les logs du pod
COPY --from=builder /prep/extensions/*.so /opt/php-8.5/lib/php/extensions/no-debug-non-zts-20250925/

# Activation des extensions via le dossier conf.d de PHP
RUN echo "extension=pdo_sqlite.so" > /usr/local/etc/php/conf.d/docker-php-ext-pdo_sqlite.ini \
    && echo "extension=mbstring.so" >> /usr/local/etc/php/conf.d/docker-php-ext-mbstring.ini \
    && echo "extension=gd.so" >> /usr/local/etc/php/conf.d/docker-php-ext-gd.ini \
    && echo "extension=intl.so" >> /usr/local/etc/php/conf.d/docker-php-ext-intl.ini

USER 1000
