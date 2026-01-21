#!/bin/bash
set -e

echo "Starting Discourse boot sequence..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h "${DISCOURSE_DB_HOST}" -p "${DISCOURSE_DB_PORT}" -U "${DISCOURSE_DB_USERNAME}" > /dev/null 2>&1; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "PostgreSQL is ready!"

# Wait for Redis to be ready
echo "Waiting for Redis to be ready..."
until redis-cli -h "${DISCOURSE_REDIS_HOST}" -p "${DISCOURSE_REDIS_PORT}" ping > /dev/null 2>&1; do
  echo "Redis is unavailable - sleeping"
  sleep 2
done
echo "Redis is ready!"

# Change to discourse directory
cd /var/www/discourse

# Run database migrations
echo "Running database migrations..."
bundle exec rake db:migrate

# Precompile assets if needed (can be disabled via env var)
if [ "${DISCOURSE_PRECOMPILE_ASSETS}" = "true" ]; then
  echo "Precompiling assets..."
  bundle exec rake assets:precompile
fi

echo "Boot sequence complete!"
