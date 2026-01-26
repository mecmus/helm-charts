# Stage 1: Builder - Compilation et collecte des dépendances
FROM dhi.io/php:8.5.0-dev AS builder

USER root

# Installation des dépendances de build
RUN apt-get update && apt-get install -y \
    curl tar git unzip \
    libpq-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libicu-dev libzip-dev libonig-dev libxml2-dev libpcre2-dev \
    libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Compilation des extensions PHP requises par FileSender
RUN cd $PHP_SRC_DIR/ext/pdo_mysql && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/pdo_pgsql && phpize && ./configure && make -j$(nproc) && make install \
    && cd $PHP_SRC_DIR/ext/pdo_sqlite && phpize && ./configure && make -j$(nproc) && make install \
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
RUN for so in /build/php-extensions/*.so; do \
      ldd "$so" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -vL '{}' /build/lib/; \
    done || true

# Génération des fichiers de configuration .ini
RUN for ext in pdo_mysql pdo_pgsql pdo_sqlite gd zip soap bcmath exif; do \
       echo "extension=${ext}.so" > /build/php-conf/${ext}.ini; \
    done

# Create PHP-FPM config: listen on all interfaces and run in foreground (required for Docker/Kubernetes)
RUN mkdir -p /build/php-fpm.d && \
    echo '[global]' > /build/php-fpm.d/zz-docker.conf && \
    echo 'daemonize = no' >> /build/php-fpm.d/zz-docker.conf && \
    echo '' >> /build/php-fpm.d/zz-docker.conf && \
    echo '[www]' >> /build/php-fpm.d/zz-docker.conf && \
    echo 'listen = [::]:9000' >> /build/php-fpm.d/zz-docker.conf

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

# Information sur la version
ARG FILESENDER_VERSION=3.3

# Metadata
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts" \
      org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} Hardened Production Image" \
      org.opencontainers.image.version="${FILESENDER_VERSION}"

# 1. Copie des librairies système vers le chemin standard
COPY --from=builder /build/lib/ /usr/lib/x86_64-linux-gnu/

# 2. Copie des extensions PHP vers le chemin attendu par PHP 8.5 dans DHI
COPY --from=builder /build/php-extensions/ /opt/php-8.5/lib/php/extensions/no-debug-non-zts-20250925/

# 3. Copie de la configuration PHP
COPY --from=builder /build/php-conf/ /opt/php-8.5/etc/php/conf.d/

# 4. Copie des fichiers applicatifs (matching official FileSender documentation paths)
COPY --from=builder --chown=1000:1000 /build/app/filesender /opt/filesender/filesender
COPY --from=builder --chown=1000:1000 /build/app/simplesaml /opt/filesender/simplesaml

# 5. Copy PHP-FPM config to listen on all interfaces (required for Kubernetes networking)
COPY --from=builder /build/php-fpm.d/zz-docker.conf /opt/php-8.5/etc/php-fpm.d/zz-docker.conf

# Port PHP-FPM
EXPOSE 9000

USER 1000
