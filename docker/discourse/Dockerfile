FROM discourse/base:2.0.20250114-0429

# Metadata
ARG DISCOURSE_VERSION=v3.4.3
ARG DISCOURSE_BASE_VERSION=2.0.20250114-0429
LABEL org.opencontainers.image.source="https://github.com/mecmus/helm-charts" \
      org.opencontainers.image.description="Discourse v${DISCOURSE_VERSION} for Kubernetes" \
      org.opencontainers.image.version="${DISCOURSE_VERSION}"

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client \
    redis-tools \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Clone Discourse
WORKDIR /var/www/discourse
RUN git clone --depth 1 --branch ${DISCOURSE_VERSION} https://github.com/discourse/discourse.git . && \
    chown -R discourse:discourse /var/www/discourse

# Switch to discourse user
USER discourse

# Install Ruby dependencies
RUN bundle config --global silence_root_warning 1 && \
    bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4

# Copy boot extras script
COPY --chown=discourse:discourse boot_extras.sh /usr/local/bin/boot_extras.sh
RUN chmod +x /usr/local/bin/boot_extras.sh

# Expose port
EXPOSE 3000

# Volume for shared data
VOLUME /shared

# Default command
CMD ["/usr/local/bin/boot_extras.sh"]
