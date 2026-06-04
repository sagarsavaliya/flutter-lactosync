#!/usr/bin/env bash
# Export all legacy farms and import into the Flutter/Laravel app (live).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMPORT_DIR="${IMPORT_DIR:-/tmp/legacy-import-live}"
SQL_CONTAINER="${SQL_CONTAINER:-lactosync-sql}"

mkdir -p "$IMPORT_DIR"

FARMS=(
  "8B31D463-47F3-4741-ACB1-65B9E2F3122A"
  "62E02C07-442F-4280-9EFD-3653F15B143E"
  "12345678-1234-1234-1234-123456789012"
)

echo "==> Exporting ${#FARMS[@]} legacy farms to ${IMPORT_DIR}"
for id in "${FARMS[@]}"; do
  bash "$SCRIPT_DIR/export-legacy-dugdhsetu.sh" "$id" "$IMPORT_DIR/${id}.json"
done

echo "==> Running live import into Flutter API"
docker cp "$IMPORT_DIR" lactosync_flutter_app_api:/tmp/legacy-import-live
docker exec lactosync_flutter_app_api php artisan legacy:import-all-dugdhsetu --dir=/tmp/legacy-import-live

echo "==> Done. Verify in app: Customers tab for each farm login."
