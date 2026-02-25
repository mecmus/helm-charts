#!/bin/bash
set -e

echo "Starting Discourse boot process..."

# Create necessary directories in /shared
echo "Creating shared directories..."
mkdir -p /shared/log /shared/uploads /shared/backups
chmod -R 755 /shared

# Wait for PostgreSQL
echo "Waiting for PostgreSQL at ${DISCOURSE_DB_HOST}:${DISCOURSE_DB_PORT}..."
until PGPASSWORD="${DISCOURSE_DB_PASSWORD}" psql -h "${DISCOURSE_DB_HOST}" -p "${DISCOURSE_DB_PORT}" -U "${DISCOURSE_DB_USERNAME}" -d "${DISCOURSE_DB_NAME}" -c '\q' 2>/dev/null; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "PostgreSQL is up!"

# Wait for Redis
echo "Waiting for Redis at ${DISCOURSE_REDIS_HOST}:${DISCOURSE_REDIS_PORT}..."
if [ -n "${DISCOURSE_REDIS_PASSWORD}" ]; then
  export REDISCLI_AUTH="${DISCOURSE_REDIS_PASSWORD}"
  until redis-cli -h "${DISCOURSE_REDIS_HOST}" -p "${DISCOURSE_REDIS_PORT}" ping 2>/dev/null | grep -q PONG; do
    echo "Redis is unavailable - sleeping"
    sleep 2
  done
  unset REDISCLI_AUTH
else
  until redis-cli -h "${DISCOURSE_REDIS_HOST}" -p "${DISCOURSE_REDIS_PORT}" ping 2>/dev/null | grep -q PONG; do
    echo "Redis is unavailable - sleeping"
    sleep 2
  done
fi
echo "Redis is up!"

# Set working directory
cd /var/www/discourse

# Run database migrations
echo "Running database migrations..."
RAILS_ENV=production bundle exec rake db:migrate

# Precompile assets if needed (optional, can be time-consuming)
if [ "${DISCOURSE_PRECOMPILE_ASSETS}" = "true" ]; then
  echo "Precompiling assets..."
  RAILS_ENV=production bundle exec rake assets:precompile
fi

# Start Discourse
echo "Starting Discourse..."
exec bundle exec rails server -b 0.0.0.0 -p 3000 -e production
