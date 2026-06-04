#!/usr/bin/env bash
# Export customers + subscriptions from legacy LactoSync SQL Server (DugdhSetuDB).
# Run on VPS where lactosync-sql container is reachable.
#
# Usage:
#   ./export-legacy-dugdhsetu.sh <MasterId> [output.json]
#
# Example (Shreeji Gir Gaushala):
#   ./export-legacy-dugdhsetu.sh 8B31D463-47F3-4741-ACB1-65B9E2F3122A /tmp/shreeji-import.json

set -euo pipefail

MASTER_ID="${1:?MasterId GUID required}"
OUTPUT="${2:-/tmp/dugdhsetu-import-${MASTER_ID}.json}"
SQL_CONTAINER="${SQL_CONTAINER:-lactosync-sql}"
DB="${LEGACY_DB_NAME:-DugdhSetuDB}"

if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
  MSSQL_SA_PASSWORD="$(docker inspect "$SQL_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^SA_PASSWORD=//p')"
fi

SQLCMD=(docker exec "$SQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -d "$DB" -h -1 -W)

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_query() {
  local file="$1"
  local query="$2"
  "${SQLCMD[@]}" -Q "SET NOCOUNT ON; $query" -s '|' -W > "$file"
}

run_query "$tmp_dir/farm.txt" \
  "SELECT Name, MasterId FROM DairyFarms WHERE MasterId = '$MASTER_ID'"

if [[ ! -s "$tmp_dir/farm.txt" ]]; then
  echo "Farm not found for MasterId: $MASTER_ID" >&2
  exit 1
fi

IFS='|' read -r FARM_NAME FARM_MASTER <<< "$(tr -d '\r' < "$tmp_dir/farm.txt" | head -1)"

run_query "$tmp_dir/products.txt" \
  "SELECT DISTINCT p.ProductId, p.Name, p.Rate, CAST(p.IsActive AS int)
   FROM Products p
   INNER JOIN Subscriptions s ON s.ProductId = p.ProductId
   WHERE s.MasterId = '$MASTER_ID'
   ORDER BY p.ProductId"

run_query "$tmp_dir/customers.txt" \
  "SELECT c.CustomerId, c.FirstName, ISNULL(c.LastName,''), c.Contact,
          ISNULL(c.SecondaryContact,''), ISNULL(c.Address,''), ISNULL(c.Location,''),
          ISNULL(c.Landmark,''), ISNULL(c.City,''), ISNULL(c.State,''), ISNULL(c.ZipCode,''),
          CAST(c.IsActive AS int), CAST(c.IsOnVacation AS int)
   FROM Customers c
   WHERE c.MasterId = '$MASTER_ID'
   ORDER BY c.CustomerId"

run_query "$tmp_dir/subscriptions.txt" \
  "SELECT s.SubscriptionId, s.CustomerId, s.ProductId, s.Qty, s.Shift,
          s.DiscountAmount, CAST(s.IsActive AS int), s.Status, p.Rate
   FROM Subscriptions s
   INNER JOIN Products p ON p.ProductId = s.ProductId
   WHERE s.MasterId = '$MASTER_ID'
   ORDER BY s.CustomerId, s.SubscriptionId"

python3 - "$OUTPUT" "$FARM_NAME" "$FARM_MASTER" "$tmp_dir" <<'PY'
import json, sys

output, farm_name, farm_master, tmp_dir = sys.argv[1:5]

def read_rows(filename, fields):
    path = f"{tmp_dir}/{filename}"
    rows = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            parts = [p.strip() for p in line.split("|")]
            if len(parts) < len(fields):
                continue
            row = {}
            for key, value in zip(fields, parts):
                if key in {"ProductId", "CustomerId", "SubscriptionId", "Shift", "Status", "IsActive", "IsOnVacation"}:
                    row[key] = int(float(value or 0))
                elif key in {"Rate", "Qty", "DiscountAmount"}:
                    row[key] = float(value or 0)
                else:
                    row[key] = value
            rows.append(row)
    return rows

payload = {
    "farm": {"Name": farm_name, "MasterId": farm_master},
    "products": read_rows("products.txt", ["ProductId", "Name", "Rate", "IsActive"]),
    "customers": read_rows("customers.txt", [
        "CustomerId", "FirstName", "LastName", "Contact", "SecondaryContact",
        "Address", "Location", "Landmark", "City", "State", "ZipCode",
        "IsActive", "IsOnVacation",
    ]),
    "subscriptions": read_rows("subscriptions.txt", [
        "SubscriptionId", "CustomerId", "ProductId", "Qty", "Shift",
        "DiscountAmount", "IsActive", "Status", "Rate",
    ]),
}

with open(output, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)

print(f"Exported {len(payload['customers'])} customers, "
      f"{len(payload['subscriptions'])} subscription rows, "
      f"{len(payload['products'])} products -> {output}")
PY
