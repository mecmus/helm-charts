ARG DISCOURSE_BASE_VERSION=2.0.20250114-0429
ARG DISCOURSE_VERSION=v3.4.0

FROM discourse/base:${DISCOURSE_BASE_VERSION}

# Set environment variables
ENV RAILS_ENV=production \
    DISCOURSE_DB_SOCKET="" \
    DISCOURSE_DB_HOST="" \
    DISCOURSE_DB_PORT=5432

# Install git if not present
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# Clone Discourse
WORKDIR /var/www
RUN git clone --depth 1 --branch ${DISCOURSE_VERSION} https://github.com/discourse/discourse.git discourse && \
    cd discourse && \
    bundle config set --local deployment 'true' && \
    bundle config set --local without 'test development' && \
    bundle install --jobs 4

# Set up shared directory for uploads, backups, logs
RUN mkdir -p /shared && \
    chown -R discourse:discourse /shared && \
    ln -s /shared /var/www/discourse/public/uploads && \
    ln -s /shared/log /var/www/discourse/log

WORKDIR /var/www/discourse

# Copy boot script
COPY boot_extras.sh /usr/local/bin/boot_extras.sh
RUN chmod +x /usr/local/bin/boot_extras.sh

# Expose Discourse port
EXPOSE 3000

# Use discourse user
USER discourse

# Volume for shared data
VOLUME ["/shared"]

# Run boot script and start Discourse
CMD ["/bin/bash", "-c", "/usr/local/bin/boot_extras.sh && bundle exec rails server -b 0.0.0.0 -p 3000"]
