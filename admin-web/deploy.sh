#!/usr/bin/env bash
set -euo pipefail

# LactoSync Admin Panel — deploy to Hostinger VPS
# Usage: ./deploy.sh
# Prerequisites: ssh key auth to VPS, rsync installed locally

VPS_USER="${VPS_USER:-root}"
VPS_HOST="${VPS_HOST:-YOUR_VPS_IP}"
VPS_PATH="/var/www/lactosync-admin"

echo "==> Building admin panel..."
npm run build

echo "==> Uploading dist/ to ${VPS_USER}@${VPS_HOST}:${VPS_PATH}..."
rsync -avz --delete dist/ "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/dist/"

echo "==> Done. Visit https://superadmin.lactosync.com"
