FROM php:8.4-fpm-bookworm

LABEL maintainer="FileSender Helm Chart"
LABEL description="FileSender 3.3 with PHP-FPM and SimpleSAMLphp"
LABEL version="3.3"

# FileSender and SimpleSAMLphp versions
ARG FILESENDER_VERSION=3.3
ARG SSP_VERSION=2.4.2

ENV FILESENDER_VERSION=${FILESENDER_VERSION} \
    SSP_VERSION=${SSP_VERSION} \
    DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        git \
        unzip \
        libpq-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libzip-dev \
        libicu-dev \
        libxml2-dev \
        libonig-dev \
        supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_pgsql \
        pgsql \
        pdo_mysql \
        mysqli \
        gd \
        zip \
        intl \
        xml \
        mbstring \
        opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create directory structure
RUN mkdir -p /opt/filesender

# Install FileSender
WORKDIR /opt/filesender
RUN curl -L https://github.com/filesender/filesender/archive/refs/tags/${FILESENDER_VERSION}.tar.gz | tar xz && \
    mv filesender-${FILESENDER_VERSION} filesender && \
    cd filesender && \
    composer install --no-dev --optimize-autoloader

# Install SimpleSAMLphp
WORKDIR /opt/filesender
RUN curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SSP_VERSION}/simplesamlphp-${SSP_VERSION}-full.tar.gz | tar xz && \
    mv simplesamlphp-${SSP_VERSION} simplesamlphp

# Setup FileSender directories and permissions
WORKDIR /opt/filesender/filesender
RUN cp config/config_sample.php config/config.php && \
    mkdir -p tmp files log && \
    chmod 755 tmp files log && \
    chmod 644 config/config.php

# Setup SimpleSAMLphp configuration
WORKDIR /opt/filesender/simplesamlphp
RUN cp config/acl.php.dist config/acl.php && \
    cp config/authsources.php.dist config/authsources.php && \
    cp config/config.php.dist config/config.php && \
    cp metadata/saml20-idp-hosted.php.dist metadata/saml20-idp-hosted.php && \
    cp metadata/saml20-idp-remote.php.dist metadata/saml20-idp-remote.php && \
    cp metadata/saml20-sp-remote.php.dist metadata/saml20-sp-remote.php

# Create configuration directories for volume mounts
RUN mkdir -p /config/filesender /config/simplesamlphp/config /config/simplesamlphp/metadata /config/php

# Create www-data user home and set permissions
RUN chown -R www-data:www-data /opt/filesender && \
    chmod -R 755 /opt/filesender

# PHP configuration
RUN { \
        echo 'log_errors = On'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo 'session.cookie_secure = On'; \
        echo 'session.cookie_httponly = On'; \
        echo 'session.cookie_samesite = Strict'; \
        echo 'upload_max_filesize = 2G'; \
        echo 'post_max_size = 2G'; \
        echo 'max_execution_time = 300'; \
        echo 'max_input_time = 300'; \
        echo 'memory_limit = 512M'; \
    } > /usr/local/etc/php/conf.d/filesender.ini

# PHP-FPM configuration
RUN { \
        echo '[www]'; \
        echo 'listen = 9000'; \
        echo 'pm = dynamic'; \
        echo 'pm.max_children = 50'; \
        echo 'pm.start_servers = 5'; \
        echo 'pm.min_spare_servers = 5'; \
        echo 'pm.max_spare_servers = 35'; \
        echo 'catch_workers_output = yes'; \
        echo 'access.log = /proc/self/fd/2'; \
    } > /usr/local/etc/php-fpm.d/www.conf

# Add healthcheck script
RUN { \
        echo '#!/bin/sh'; \
        echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1'; \
    } > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

VOLUME ["/opt/filesender/filesender/files", "/opt/filesender/filesender/log", "/opt/filesender/filesender/tmp"]

EXPOSE 9000

WORKDIR /opt/filesender/filesender

USER www-data

CMD ["php-fpm"]
