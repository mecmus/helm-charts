# Stage 1: Builder - Compilation des extensions et préparation des fichiers
FROM dhi.io/php:8.5.0-dev AS builder

USER root

# Installation des dépendances de build pour les extensions PHP requises par FileSender
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    unzip \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libpcre2-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Compilation des extensions PHP nécessaires
# DHI fournit les sources dans $PHP_SRC_DIR
RUN cd $PHP_SRC_DIR/ext/pdo_mysql && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/pdo_pgsql && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/gd && phpize && ./configure --with-freetype --with-jpeg && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/intl && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/mbstring && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/zip && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/soap && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/bcmath && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/exif && phpize && ./configure && make -j$(nproc) && make install

# Collecte des extensions dans un dossier plat et préparation des .ini
# On utilise des chemins absolus dans les .ini pour garantir le chargement dans l'image finale
RUN mkdir -p /build/php-extensions \
    && cp $(php-config --extension-dir)/*.so /build/php-extensions/ \
    && mkdir -p /build/php-conf \
    && for ext in pdo_mysql pdo_pgsql gd intl mbstring zip soap bcmath exif; do \
       echo "extension=/usr/local/lib/php/extensions/${ext}.so" > /build/php-conf/${ext}.ini; \
    done

# Versions
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.2.3

WORKDIR /build/app

# Téléchargement et extraction de FileSender (Branche master3 pour v3.3)
RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender

# Téléchargement et extraction de SimpleSAMLphp
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml

# Création des dossiers de stockage et logs (UID 1000 pour DHI)
RUN mkdir -p filesender/files filesender/tmp filesender/log \
    && chown -R 1000:1000 filesender simplesaml

# Stage 2: Runtime - Image sécurisée Docker Hardened
FROM dhi.io/php:8.5.0-fpm

# Information sur la version
ARG FILESENDER_VERSION=3.3

# Metadata
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts"
LABEL org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} (branch 3.3) with SimpleSAMLphp based on Hardened PHP"
LABEL org.opencontainers.image.version="${FILESENDER_VERSION}"

# Copie des extensions compilées vers un dossier fixe
COPY --from=builder /build/php-extensions /usr/local/lib/php/extensions
# Copie des configurations d'extensions préparées dans $PHP_INI_DIR/conf.d/
COPY --from=builder /build/php-conf/ $PHP_INI_DIR/conf.d/

# Copie des fichiers préparés
COPY --from=builder --chown=1000:1000 /build/app/filesender /var/www/html
COPY --from=builder --chown=1000:1000 /build/app/simplesaml /var/www/simplesaml

# L'utilisateur par défaut de DHI est conservé (non-root)
USER 1000
