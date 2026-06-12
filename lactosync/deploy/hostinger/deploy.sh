#!/usr/bin/env bash
# Sync LactoSync backend to Hostinger and (re)start production stack.
# Run from repo root: bash lactosync/deploy/hostinger/deploy.sh

set -euo pipefail

HOST="${LACTOSYNC_DEPLOY_HOST:-hostinger-vps}"
REMOTE_ROOT="/var/www/lactosync_flutter_app"
LOCAL_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "==> Syncing backend to ${HOST}:${REMOTE_ROOT}/repo"
ssh "$HOST" "mkdir -p ${REMOTE_ROOT}/repo"
rsync -az --delete \
  --exclude 'src/vendor' \
  --exclude 'src/node_modules' \
  --exclude 'src/.env' \
  --exclude 'src/storage/logs' \
  --exclude 'src/bootstrap/cache' \
  --exclude '.git' \
  "$LOCAL_ROOT/" "$HOST:${REMOTE_ROOT}/repo/"

echo "==> Building and starting containers"
ssh "$HOST" "cd ${REMOTE_ROOT}/repo/deploy/hostinger && docker compose -f docker-compose.prod.yml up -d --build"

echo "==> Restoring Blazor nginx routes (api + app.lactosync.com)"
ssh "$HOST" "cp ${REMOTE_ROOT}/repo/deploy/hostinger/nginx-proxy/lactosync.conf /var/www/nginx-proxy/conf.d/lactosync.conf"

echo "==> Installing Flutter API nginx route (flutterapi.lactosync.com)"
ssh "$HOST" "cp ${REMOTE_ROOT}/repo/deploy/hostinger/nginx-proxy/lactosync-flutter.conf /var/www/nginx-proxy/conf.d/lactosync-flutter.conf"

echo "==> Restarting original Blazor stack"
ssh "$HOST" "cd /opt/lactosync/compose && docker compose up -d"

echo "==> Building and starting Flutter backend containers"
ssh "$HOST" "cd ${REMOTE_ROOT}/repo/deploy/hostinger && docker compose -f docker-compose.prod.yml up -d --build"

echo "==> Reloading nginx-proxy"
ssh "$HOST" "docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload"

echo "==> Health check (Flutter API)"
ssh "$HOST" "curl -sf https://flutterapi.lactosync.com/api/v1/health | head -c 200 || echo 'SSL/DNS pending — add A record flutterapi.lactosync.com -> VPS IP'"

echo "Done. Blazor: https://api.lactosync.com | Flutter: https://flutterapi.lactosync.com/api/v1"
