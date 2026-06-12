# VPS Rollout — Sprint OR (Owner Redesign)

> **This document is for human review and manual execution only.**
> No commands in this document should be run by any automated agent.
> Read every step carefully before executing. Follow the order exactly.

---

## Pre-flight Checks

Run these before touching any migrations or copying any files.

**1. SSH into VPS**
```bash
ssh root@<vps-ip>
```

**2. Check current migration status**
```bash
docker exec lactosync_flutter_app_api php artisan migrate:status
```
Verify that all previous Sprint CA migrations show `Ran`. If any Sprint CA migrations are still pending, run those first before proceeding with Sprint OR.

**3. Check existing container_types data**
```bash
docker exec lactosync_flutter_app_api php artisan tinker --execute="DB::table('container_types')->orderBy('id')->get()->each(fn(\$r) => print(\$r->id.' | farm:'.\$r->farm_id.' | '.\$r->name.' | kind:'.\$r->kind.' | size_ml:'.\$r->size_ml.PHP_EOL));"
```
Record the output. Typical live state: rows like "Glass Bottle 500ml", "Glass Bottle 1L", "Plastic Bag 500ml", "Plastic Bag 1L" with kind=glass_bottle or plastic_bag. Step 2 migration will merge these into grouped rows — the output above is your reference if you need to verify the merge was correct.

**4. Take a full DB backup before doing anything**
```bash
docker exec lactosync_flutter_app_api mysqldump -u root -p lactosync_db > /tmp/backup_before_sprint_or_$(date +%Y%m%d).sql
```
When prompted, enter the MySQL root password. Confirm the file exists and is non-zero:
```bash
ls -lh /tmp/backup_before_sprint_or_*.sql
```

---

## Sprint CA PHP Files — Copy First (if not already done)

If Sprint CA was not yet deployed to VPS, copy these files first.

```bash
docker cp lactosync/src/app/Http/Controllers/Api/Customer/V1/AuthController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/Customer/V1/AuthController.php

docker cp lactosync/src/app/Http/Controllers/Api/Customer/V1/DashboardController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/Customer/V1/DashboardController.php

docker cp lactosync/src/app/Http/Controllers/Api/Customer/V1/ProfileController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/Customer/V1/ProfileController.php

docker cp lactosync/src/app/Http/Controllers/Api/Customer/V1/VacationController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/Customer/V1/VacationController.php

docker cp lactosync/src/app/Http/Controllers/Api/Customer/V1/OrderController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/Customer/V1/OrderController.php

docker cp lactosync/src/app/Http/Controllers/Api/Customer/V1/BillingController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/Customer/V1/BillingController.php
```

> If Sprint CA was already deployed, skip this section.

---

## Sprint OR PHP Files — Copy to Container

Run all of these from the repo root on the VPS (or from wherever you cloned the repo).

### Migrations (3 files)
```bash
docker cp lactosync/src/database/migrations/2026_06_07_100001_sprint_or_step1_additive.php lactosync_flutter_app_api:/var/www/html/database/migrations/2026_06_07_100001_sprint_or_step1_additive.php

docker cp lactosync/src/database/migrations/2026_06_07_100002_sprint_or_step2_backfill.php lactosync_flutter_app_api:/var/www/html/database/migrations/2026_06_07_100002_sprint_or_step2_backfill.php

docker cp lactosync/src/database/migrations/2026_06_07_100003_sprint_or_step3_deferred_drop_columns.php lactosync_flutter_app_api:/var/www/html/database/migrations/2026_06_07_100003_sprint_or_step3_deferred_drop_columns.php
```

### Seeders
```bash
docker cp lactosync/src/database/seeders/ContainerTypeSeeder.php lactosync_flutter_app_api:/var/www/html/database/seeders/ContainerTypeSeeder.php

docker cp lactosync/src/database/seeders/MilkTypeSeeder.php lactosync_flutter_app_api:/var/www/html/database/seeders/MilkTypeSeeder.php

docker cp lactosync/src/database/seeders/DatabaseSeeder.php lactosync_flutter_app_api:/var/www/html/database/seeders/DatabaseSeeder.php
```

### Models
```bash
docker cp lactosync/src/app/Models/ContainerType.php lactosync_flutter_app_api:/var/www/html/app/Models/ContainerType.php

docker cp lactosync/src/app/Models/ContainerTypeSize.php lactosync_flutter_app_api:/var/www/html/app/Models/ContainerTypeSize.php

docker cp lactosync/src/app/Models/Product.php lactosync_flutter_app_api:/var/www/html/app/Models/Product.php

docker cp lactosync/src/app/Models/Farm.php lactosync_flutter_app_api:/var/www/html/app/Models/Farm.php
```

### Requests
```bash
docker cp lactosync/src/app/Http/Requests/Owner/StoreContainerTypeRequest.php lactosync_flutter_app_api:/var/www/html/app/Http/Requests/Owner/StoreContainerTypeRequest.php

docker cp lactosync/src/app/Http/Requests/Owner/StoreOwnerProductRequest.php lactosync_flutter_app_api:/var/www/html/app/Http/Requests/Owner/StoreOwnerProductRequest.php

docker cp lactosync/src/app/Http/Requests/Owner/UpdateOwnerProductRequest.php lactosync_flutter_app_api:/var/www/html/app/Http/Requests/Owner/UpdateOwnerProductRequest.php

docker cp lactosync/src/app/Http/Requests/Owner/UpdateOwnerSettingsRequest.php lactosync_flutter_app_api:/var/www/html/app/Http/Requests/Owner/UpdateOwnerSettingsRequest.php
```

### Controllers
```bash
docker cp lactosync/src/app/Http/Controllers/Api/V1/OwnerProductTypesController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/V1/OwnerProductTypesController.php

docker cp lactosync/src/app/Http/Controllers/Api/V1/OwnerSettingsController.php lactosync_flutter_app_api:/var/www/html/app/Http/Controllers/Api/V1/OwnerSettingsController.php
```

### Routes (if modified)
```bash
docker cp lactosync/src/routes/api.php lactosync_flutter_app_api:/var/www/html/routes/api.php
```

### Clear config/route cache after copying
```bash
docker exec lactosync_flutter_app_api php artisan config:clear
docker exec lactosync_flutter_app_api php artisan route:clear
docker exec lactosync_flutter_app_api php artisan cache:clear
```

---

## Step 1 Migration — Safe to Run (Additive Only)

This migration only creates new tables and adds nullable columns. The running APK (v4.8.7+13) will not be affected — it ignores the new tables.

```bash
docker exec lactosync_flutter_app_api php artisan migrate --path=database/migrations/2026_06_07_100001_sprint_or_step1_additive.php
```

**Verify Step 1:**
```bash
docker exec lactosync_flutter_app_api php artisan tinker --execute="print(Schema::hasTable('container_type_sizes') ? 'OK: container_type_sizes exists' : 'FAIL: table missing').PHP_EOL; print(Schema::hasColumn('farms','prefill_customer_address') ? 'OK: prefill_customer_address column exists' : 'FAIL: column missing').PHP_EOL;"
```
Expected output:
```
OK: container_type_sizes exists
OK: prefill_customer_address column exists
```

---

## Step 2 Migration — Safe to Run (Backfill Only)

This migration merges the old flat container_types rows (e.g. "Glass Bottle 500ml", "Glass Bottle 1L") into grouped rows with sizes in `container_type_sizes`. It also backfills `products.name`, adds Special Buffalo Milk to milk_types, seeds Can container types, and seeds `milk_quantities`. No columns are dropped.

```bash
docker exec lactosync_flutter_app_api php artisan migrate --path=database/migrations/2026_06_07_100002_sprint_or_step2_backfill.php
```

**Verify Step 2 — container_type_sizes has rows:**
```bash
docker exec lactosync_flutter_app_api php artisan tinker --execute="print('container_type_sizes rows: '.DB::table('container_type_sizes')->count().PHP_EOL);"
```
Expected: at least 6 rows (Glass Bottle + Plastic Bag existing sizes + 4 Can sizes).

**Verify Step 2 — container_types merged correctly:**
```bash
docker exec lactosync_flutter_app_api php artisan tinker --execute="DB::table('container_types')->whereNull('farm_id')->orderBy('name')->get()->each(fn(\$r) => print(\$r->id.' | '.\$r->name.PHP_EOL));"
```
Expected system defaults after merge:
```
<id> | 5L Can
<id> | 10L Can
<id> | 15L Can
<id> | 20L Can
<id> | Glass Bottle
<id> | Plastic Bag
```
(Glass Bottle 500ml, Glass Bottle 1L, Plastic Bag 500ml, Plastic Bag 1L should no longer appear as separate rows.)

**Verify Step 2 — milk_quantities seeded:**
```bash
docker exec lactosync_flutter_app_api php artisan tinker --execute="print('milk_quantities rows: '.DB::table('milk_quantities')->count().PHP_EOL);"
```
Expected: 20 rows.

**Verify Step 2 — Special Buffalo Milk in milk_types:**
```bash
docker exec lactosync_flutter_app_api php artisan tinker --execute="print(DB::table('milk_types')->whereNull('farm_id')->where('name','Special Buffalo Milk')->exists() ? 'OK: Special Buffalo Milk present' : 'WARN: not found').PHP_EOL;"
```

---

## Seeder Run (Optional)

Only run if `container_type_sizes` is empty after Step 2, or if you suspect the backfill did not seed the Can types correctly.

```bash
docker exec lactosync_flutter_app_api php artisan db:seed --class=ContainerTypeSeeder
docker exec lactosync_flutter_app_api php artisan db:seed --class=MilkTypeSeeder
```

> WARNING: Only run these if explicitly needed. The seeders use `updateOrCreate` / `insertOrIgnore` semantics and are safe to re-run, but double-check the seeder code first to confirm it won't duplicate data on your live schema.

---

## Step 3 Migration — DEFERRED — DO NOT RUN YET

```
# !! STOP !! DO NOT RUN THIS NOW !!
#
# This migration drops legacy columns from container_types and products,
# and drops the product_container_types pivot table.
# Running it before the new APK (v4.9.0+14) is live will break the running app.
#
# Pre-conditions before running:
#   1. APK v4.9.0+14 is installed and tested on Farenidham Gaushala
#   2. Human confirms: container types, products, settings all working
#   3. Human confirms: all 3 live farm accounts on new APK
#   4. CEO or farm owner gives explicit approval
#
# When all conditions are met, run:
# docker exec lactosync_flutter_app_api php artisan migrate --path=database/migrations/2026_06_07_100003_sprint_or_step3_deferred_drop_columns.php
```

---

## Smoke Tests (Run After Step 1 + Step 2)

Use curl or Postman. Obtain an owner auth token first if needed.

**GET /api/v1/owner/container-types — verify grouped response with sizes**
```bash
curl -s -H "Authorization: Bearer <token>" https://api.lactosync.com/api/v1/owner/container-types | python3 -m json.tool
```
Expected: `container_types` array where each item has `id`, `name`, `is_system`, `is_active`, and `sizes` (array of floats, e.g. `[0.5, 1.0]`).

**GET /api/v1/owner/products — verify product list with container_type object**
```bash
curl -s -H "Authorization: Bearer <token>" https://api.lactosync.com/api/v1/owner/products | python3 -m json.tool
```
Expected: `products` array where each product has `container_type` object with `id`, `name`, and `sizes` array.

**GET /api/v1/owner/settings — verify prefill_customer_address field present**
```bash
curl -s -H "Authorization: Bearer <token>" https://api.lactosync.com/api/v1/owner/settings | python3 -m json.tool
```
Expected: response includes `prefill_customer_address` boolean field.

---

## Rollback Plan

If any step fails:

1. **Do not run any further migrations.**
2. Check Laravel logs: `docker exec lactosync_flutter_app_api tail -n 100 storage/logs/laravel.log`
3. If Step 1 or Step 2 produced a partial state, restore from the backup taken in Pre-flight Check step 4:
   ```bash
   docker exec -i lactosync_flutter_app_api mysql -u root -p lactosync_db < /tmp/backup_before_sprint_or_<date>.sql
   ```
4. Contact the DevOps Engineer with the full error output.

---

_Written by DevOps Engineer — 2026-06-07_
_For human review and execution only. Do not automate._
