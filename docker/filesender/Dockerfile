# Image FileSender basée sur Docker Hardened Images (DHI)
# Utilisation de la version la plus récente de PHP-FPM disponible sur dhi.io
FROM dhi.io/php:8.5.0-fpm

# Passage en root pour l'installation des dépendances système
USER root

# Installation des paquets nécessaires pour FileSender (PostgreSQL, MySQL, GD, Zip)
RUN apt-get update && apt-get install -y \
    postgresql-client \
    libpq-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Définition de la version de FileSender
ARG FILESENDER_VERSION=3.3

# Installation de FileSender
WORKDIR /var/www/html
RUN curl -L https://github.com/filesender/filesender/archive/refs/tags/v${FILESENDER_VERSION}.tar.gz | tar xz --strip-components=1 \
    && chown -R www-data:www-data /var/www/html

# Conforme aux images DHI, on repasse sur l'utilisateur www-data
USER www-data

LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts"
LABEL org.opencontainers.image.description="FileSender v${FILESENDER_VERSION} based on DHI PHP 8.5.0-fpm"
LABEL org.opencontainers.image.version="${FILESENDER_VERSION}"
