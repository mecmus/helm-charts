# Stage 1: Builder - Préparation des fichiers de FileSender et SimpleSAMLphp
FROM php:8.3-fpm-bookworm AS builder

# Installation des dépendances pour extraire les sources
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Versions
ARG FILESENDER_VERSION=3.3
ARG SIMPLESAMLPHP_VERSION=2.2.3

WORKDIR /build

# Téléchargement et extraction de FileSender (Branche master3 pour v3.3)
RUN git clone --depth 1 --branch master3 https://github.com/filesender/filesender.git filesender

# Téléchargement et extraction de SimpleSAMLphp
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz | tar xz \
    && mv simplesamlphp-${SIMPLESAMLPHP_VERSION} simplesaml

# Création des dossiers de stockage et logs dans le builder (UID 1000 pour DHI)
RUN mkdir -p filesender/files filesender/tmp filesender/log \
    && chown -R 1000:1000 filesender simplesaml

# Stage 2: Runtime - Image sécurisée Docker Hardened
# Note: Les images runtime DHI n'ont pas de shell (/bin/sh). 
# Toutes les configurations de fichiers doivent être faites dans le stage builder.
FROM dhi.io/php:8.5.0-fpm

# Information sur la version
ARG FILESENDER_VERSION=3.3

# Metadata
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts"
LABEL org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} (branch 3.3) with SimpleSAMLphp based on DHI PHP"
LABEL org.opencontainers.image.version="${FILESENDER_VERSION}"

# Copie des fichiers préparés (permissions préservées par chown dans builder)
# DHI PHP-FPM utilise /var/www/html comme WORKDIR par défaut.
COPY --from=builder --chown=1000:1000 /build/filesender /var/www/html
COPY --from=builder --chown=1000:1000 /build/simplesaml /var/www/simplesaml

# L'utilisateur par défaut de DHI est conservé (non-root)
USER 1000
