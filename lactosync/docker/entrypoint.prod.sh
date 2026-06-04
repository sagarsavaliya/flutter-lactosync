#!/bin/sh
set -e

cd /var/www/html

php artisan storage:link 2>/dev/null || true

if [ "${MIGRATE_ON_START:-0}" = "1" ]; then
    php artisan migrate --force
fi

if [ "${OPTIMIZE_ON_START:-0}" = "1" ]; then
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

exec "$@"
