# Stage 1: Builder - Compilation et collecte des dépendances
FROM dhi.io/php:8.5.0-dev AS builder

USER root

# Installation des dépendances de build
RUN apt-get update && apt-get install -y \
    curl tar git unzip \
    libpq-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libicu-dev libzip-dev libonig-dev libxml2-dev libpcre2-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Compilation des extensions PHP requises par FileSender (non incluses nativement)
# Note: intl et mbstring sont déjà inclus dans l'image DHI de base
RUN cd $PHP_SRC_DIR/ext/pdo_mysql && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/pdo_pgsql && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/gd && phpize && ./configure --with-freetype --with-jpeg && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/zip && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/soap && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/bcmath && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/exif && phpize && ./configure && make -j$(nproc) && make install

# Préparation de la structure de collecte
RUN mkdir -p /build/php-extensions /build/lib /build/php-conf

# Collecte des extensions (.so)
RUN cp $(php-config --extension-dir)/*.so /build/php-extensions/

# Collecte des bibliothèques système partagées (.so) nécessaires
# Sans package manager au runtime, nous devons copier les libs système dépendantes
RUN for so in /build/php-extensions/*.so; do \
      ldd "$so" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -vL '{}' /build/lib/; \
    done || true

# Génération des fichiers de configuration .ini
RUN for ext in pdo_mysql pdo_pgsql gd zip soap bcmath exif; do \
       echo "extension=${ext}.so" > /build/php-conf/${ext}.ini; \
    done

# Préparation de l'application
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.2.3
WORKDIR /build/app
RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender && \
    curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz && \
    mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml && \
    mkdir -p filesender/files filesender/tmp filesender/log && \
    chown -R 1000:1000 filesender simplesaml

# Stage 2: Runtime - Image sécurisée Docker Hardened
FROM dhi.io/php:8.5.0-fpm

# Information sur la version (Utilisé par la CI)
ARG FILESENDER_VERSION=3.3

# Metadata
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts" \
      org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} Hardened Production Image" \
      org.opencontainers.image.version="${FILESENDER_VERSION}"

# 1. Copie des librairies système (car apt-get est absent)
COPY --from=builder /build/lib/ /usr/lib/

# 2. Copie des extensions PHP
COPY --from=builder /build/php-extensions/ /usr/local/lib/php/extensions/

# 3. Copie de la configuration PHP
COPY --from=builder /build/php-conf/ /opt/php-8.5/etc/php/conf.d/

# 4. Copie des fichiers applicatifs avec les bonnes permissions non-root
COPY --from=builder --chown=1000:1000 /build/app/filesender /var/www/html
COPY --from=builder --chown=1000:1000 /build/app/simplesaml /var/www/simplesaml

# Utilisation de l'utilisateur non-privilégié par défaut de DHI
USER 1000
