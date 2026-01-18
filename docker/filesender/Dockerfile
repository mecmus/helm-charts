# Stage 1: Builder - Préparation des fichiers et compilation
# On utilise une version proche du runtime pour la compatibilité des extensions
FROM php:8.4-fpm-bookworm AS builder

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    curl tar git unzip libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Compilation de pdo_sqlite
RUN docker-php-ext-install pdo_sqlite

# Préparation des sources
WORKDIR /build
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.2.3

RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml

# Préparation de l'arborescence et des configurations (Tout se fait en phase build)
RUN mkdir -p /prep/var/www/html/files \
    /prep/var/www/html/tmp \
    /prep/var/www/html/log \
    /prep/var/www/html/db \
    /prep/usr/local/etc/php-fpm.d \
    /prep/usr/local/etc/php/conf.d

# Modification de la configuration FPM pour écouter sur [::]:9000 (Fix 502)
RUN cp /usr/local/etc/php-fpm.d/www.conf.default /prep/usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/listen = 127.0.0.1:9000/listen = [::]:9000/g' /prep/usr/local/etc/php-fpm.d/www.conf

# Préparation du chargement de l'extension
RUN echo "extension=pdo_sqlite.so" > /prep/usr/local/etc/php/conf.d/docker-php-ext-pdo_sqlite.ini

# On identifie le répertoire des extensions pour la copie
RUN cp $(php-config --extension-dir)/pdo_sqlite.so /prep/pdo_sqlite.so

# On fixe les droits sur l'arborescence préparée pour l'utilisateur 1000 (DHI)
RUN chown -R 1000:1000 /prep/var/www/html

# Stage 2: Runtime - Image sécurisée Docker Hardened (SANS SHELL)
FROM dhi.io/php:8.5.0-fpm

# Information sur la version
ARG FILESENDER_VERSION=3.3

WORKDIR /var/www/html

# COPIES UNIQUEMENT - Aucune commande RUN ne doit s'exécuter ici
# On copie les sources
COPY --from=builder --chown=1000:1000 /build/filesender /var/www/html
COPY --from=builder --chown=1000:1000 /build/simplesaml /var/www/simplesaml

# On copie les répertoires de travail préparés avec les bons droits
COPY --from=builder --chown=1000:1000 /prep/var/www/html /var/www/html

# On copie les configurations
COPY --from=builder /prep/usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --from=builder /prep/usr/local/etc/php/conf.d/docker-php-ext-pdo_sqlite.ini /usr/local/etc/php/conf.d/docker-php-ext-pdo_sqlite.ini

# On injecte l'extension (Attention: le chemin doit correspondre à celui attendu par PHP 8.5)
# Comme on ne peut pas faire de RUN, on l'injecte dans le répertoire standard
# Note: Ce chemin est spécifique à l'API PHP, s'il change en 8.5, il faudra l'ajuster manuellement ici
COPY --from=builder /prep/pdo_sqlite.so /usr/local/lib/php/extensions/no-debug-non-zts-20240924/pdo_sqlite.so

# Metadata
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts"
LABEL org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} (branch 3.3) with SimpleSAMLphp based on DHI PHP"
LABEL org.opencontainers.image.version="${FILESENDER_VERSION}"

# L'utilisateur par défaut de DHI est conservé (non-root)
USER 1000
