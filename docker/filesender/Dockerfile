# Stage 1: Builder - Préparation des fichiers de FileSender
FROM php:8.3-fpm-bookworm AS builder

# Installation des dépendances pour extraire FileSender
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Version de FileSender
ARG FILESENDER_VERSION=3.3

WORKDIR /build

# Téléchargement et extraction de FileSender
RUN curl -L https://github.com/filesender/filesender/archive/refs/tags/v${FILESENDER_VERSION}.tar.gz | tar xz --strip-components=1

# Stage 2: Runtime - Image sécurisée Docker Hardened
FROM dhi.io/php:8.5.0-fpm

# Information sur la version pour le label
ARG FILESENDER_VERSION=3.3

# Copie des fichiers depuis le builder
# On utilise --chown=1000:1000 car les images DHI utilisent généralement l'UID 1000
COPY --from=builder --chown=1000:1000 /build /var/www/html

# L'utilisateur est déjà défini par l'image DHI (non-root)
# On s'assure d'être dans le bon dossier
WORKDIR /var/www/html

# Metadata
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts"
LABEL org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} based on DHI PHP 8.5.0-fpm (Multi-stage build)"
LABEL org.opencontainers.image.version="${FILESENDER_VERSION}"
