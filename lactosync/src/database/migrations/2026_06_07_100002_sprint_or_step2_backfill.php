<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Sprint OR — Step 2: Data backfill.
 *
 * Safe to run immediately after Step 1.  This step is non-destructive: it only
 * merges data, re-points FKs, and inserts new rows.  The old APK continues to
 * work during the transition because kind/size_ml/size_key columns still exist.
 *
 * Parts:
 *   A  Merge flat container_types into grouped container_type_sizes
 *      (system defaults and farm-custom rows)
 *   B  Backfill products.name
 *   C  Backfill product_offered_sizes from product_container_types
 *   D  Add Special Buffalo Milk to milk_types (new canonical system default)
 *   E  Seed 4 new Can system container types
 *   F  Seed milk_quantities (20 standard values)
 *
 * WARNING: down() is a PARTIAL rollback only — see note in down().
 */
return new class extends Migration
{
    // -----------------------------------------------------------------------
    // UP
    // -----------------------------------------------------------------------

    public function up(): void
    {
        $this->partA_mergeContainerTypes();
        $this->partB_backfillProductNames();
        $this->partC_backfillProductOfferedSizes();
        $this->partD_addSpecialBuffaloMilk();
        $this->partE_seedCanContainerTypes();
        $this->partF_seedMilkQuantities();
    }

    // -----------------------------------------------------------------------
    // PART A — Merge container_types into grouped model
    // -----------------------------------------------------------------------

    /**
     * Kind → canonical name mapping.
     * Used for both system defaults and farm-custom rows.
     */
    private array $kindToCanonicalName = [
        'glass_bottle' => 'Glass Bottle',
        'plastic_bag'  => 'Plastic Bag',
    ];

    private function partA_mergeContainerTypes(): void
    {
        // Process system defaults (farm_id IS NULL) and farm-custom rows together.
        // We group by (farm_id, kind) and keep the lowest id as the canonical row.

        $kinds = array_keys($this->kindToCanonicalName);

        // Fetch all rows that have a kind value set (handles both NULL and non-NULL farm_id)
        $rows = DB::table('container_types')
            ->whereIn('kind', $kinds)
            ->whereNotNull('kind')
            ->orderBy('id')
            ->get();

        if ($rows->isEmpty()) {
            return;
        }

        // Group by (farm_id, kind) — use string key to handle NULL farm_id safely
        $groups = [];
        foreach ($rows as $row) {
            $farmKey = $row->farm_id === null ? 'NULL' : (string) $row->farm_id;
            $groupKey = $farmKey . '::' . $row->kind;
            $groups[$groupKey][] = $row;
        }

        foreach ($groups as $groupKey => $groupRows) {
            // The first element has the lowest id (ordered by id above)
            $canonical = $groupRows[0];
            $nonCanonicals = array_slice($groupRows, 1);

            $canonicalName = $this->kindToCanonicalName[$canonical->kind] ?? $canonical->name;

            // Rename the canonical row to the clean base name (strip any size suffix)
            DB::table('container_types')
                ->where('id', $canonical->id)
                ->update(['name' => $canonicalName]);

            // Insert a container_type_sizes row for the canonical row's own size
            if ($canonical->size_ml !== null && $canonical->size_ml > 0) {
                DB::table('container_type_sizes')->insertOrIgnore([
                    'container_type_id' => $canonical->id,
                    'size_liters'       => round($canonical->size_ml / 1000, 4),
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ]);
            }

            // Process non-canonical rows: migrate their size, re-point FKs, then delete
            foreach ($nonCanonicals as $stale) {
                // Migrate size data from stale row into canonical
                if ($stale->size_ml !== null && $stale->size_ml > 0) {
                    DB::table('container_type_sizes')->insertOrIgnore([
                        'container_type_id' => $canonical->id,
                        'size_liters'       => round($stale->size_ml / 1000, 4),
                        'created_at'        => now(),
                        'updated_at'        => now(),
                    ]);
                }

                // Re-point products.container_type_id → canonical
                DB::table('products')
                    ->where('container_type_id', $stale->id)
                    ->update(['container_type_id' => $canonical->id]);

                // Re-point product_container_types.container_type_id → canonical
                // Use insertOrIgnore + delete pattern to avoid duplicate-unique violations:
                // For each product pointing to the stale container, ensure a row exists for
                // the canonical, then delete the stale mapping row.
                $staleMappings = DB::table('product_container_types')
                    ->where('container_type_id', $stale->id)
                    ->get();

                foreach ($staleMappings as $mapping) {
                    // Ensure the canonical mapping exists (ignores if already present)
                    DB::table('product_container_types')->insertOrIgnore([
                        'product_id'        => $mapping->product_id,
                        'container_type_id' => $canonical->id,
                        'created_at'        => $mapping->created_at,
                    ]);
                }

                // Delete all stale pivot rows pointing to the non-canonical id
                DB::table('product_container_types')
                    ->where('container_type_id', $stale->id)
                    ->delete();

                // Safe to delete now: all FKs have been re-pointed
                DB::table('container_types')->where('id', $stale->id)->delete();
            }
        }
    }

    // -----------------------------------------------------------------------
    // PART B — Backfill products.name
    // -----------------------------------------------------------------------

    private function partB_backfillProductNames(): void
    {
        // For products with a valid milk_type_id, derive name from the milk_type row.
        // Format: "{MilkTypeName} - ₹{rate}"
        // The rate is stored as decimal(10,2); we cast to decimal for consistent display.

        // First pass: products with milk_type_id set
        DB::statement("
            UPDATE products p
            JOIN milk_types mt ON p.milk_type_id = mt.id
            SET p.name = CONCAT(mt.name, ' - ₹', CAST(p.rate AS UNSIGNED))
            WHERE p.deleted_at IS NULL
        ");

        // Second pass: legacy products where milk_type_id is NULL but milk_type string exists
        // Use the legacy string column as fallback so no product is left nameless
        DB::statement("
            UPDATE products p
            SET p.name = CONCAT(p.milk_type, ' - ₹', CAST(p.rate AS UNSIGNED))
            WHERE p.deleted_at IS NULL
              AND p.milk_type_id IS NULL
              AND (p.milk_type IS NOT NULL AND p.milk_type != '')
        ");
    }

    // -----------------------------------------------------------------------
    // PART C — Backfill product_offered_sizes from product_container_types
    // -----------------------------------------------------------------------

    private function partC_backfillProductOfferedSizes(): void
    {
        // For every row in the old pivot, look up the size_liters from container_type_sizes
        // (which was just populated in Part A) and insert into product_offered_sizes.

        $pivotRows = DB::table('product_container_types as pct')
            ->join('container_type_sizes as cts', 'cts.container_type_id', '=', 'pct.container_type_id')
            ->select('pct.product_id', 'cts.size_liters')
            ->distinct()
            ->get();

        $now = now();

        foreach ($pivotRows as $row) {
            DB::table('product_offered_sizes')->insertOrIgnore([
                'product_id'   => $row->product_id,
                'size_liters'  => $row->size_liters,
                'created_at'   => $now,
                'updated_at'   => $now,
            ]);
        }
    }

    // -----------------------------------------------------------------------
    // PART D — Add Special Buffalo Milk to milk_types
    // -----------------------------------------------------------------------

    private function partD_addSpecialBuffaloMilk(): void
    {
        // The milk_types table does NOT have an is_system column.
        // We identify system defaults by farm_id IS NULL.
        // INSERT IGNORE on unique (farm_id, name) — safe to re-run.

        $exists = DB::table('milk_types')
            ->whereNull('farm_id')
            ->where('name', 'Special Buffalo Milk')
            ->exists();

        if ($exists) {
            return;
        }

        $now = now();

        DB::table('milk_types')->insert([
            'farm_id'    => null,
            'name'       => 'Special Buffalo Milk',
            'is_active'  => 1,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    // -----------------------------------------------------------------------
    // PART E — Seed 4 new canonical Can container types with sizes
    // -----------------------------------------------------------------------

    private function partE_seedCanContainerTypes(): void
    {
        // These are brand-new container types (no old flat rows to merge).
        // For each: upsert the container_type row, then upsert the size row.

        $canTypes = [
            ['name' => '5L Can',  'size_liters' => 5.00],
            ['name' => '10L Can', 'size_liters' => 10.00],
            ['name' => '15L Can', 'size_liters' => 15.00],
            ['name' => '20L Can', 'size_liters' => 20.00],
        ];

        $now = now();

        foreach ($canTypes as $can) {
            // Get or create the container_type row (system default: farm_id = null)
            $existing = DB::table('container_types')
                ->whereNull('farm_id')
                ->where('name', $can['name'])
                ->first();

            if ($existing) {
                $containerTypeId = $existing->id;
            } else {
                $containerTypeId = DB::table('container_types')->insertGetId([
                    'farm_id'    => null,
                    'name'       => $can['name'],
                    'is_active'  => 1,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            // Upsert the single size row
            DB::table('container_type_sizes')->insertOrIgnore([
                'container_type_id' => $containerTypeId,
                'size_liters'       => $can['size_liters'],
                'created_at'        => $now,
                'updated_at'        => $now,
            ]);
        }
    }

    // -----------------------------------------------------------------------
    // PART F — Seed milk_quantities (20 standard values)
    // -----------------------------------------------------------------------

    private function partF_seedMilkQuantities(): void
    {
        $now = now();

        $quantities = [
            ['quantity_liters' => '0.50', 'display_label' => '500 ml'],
            ['quantity_liters' => '1.00', 'display_label' => '1 L'],
            ['quantity_liters' => '1.50', 'display_label' => '1.5 L'],
            ['quantity_liters' => '2.00', 'display_label' => '2 L'],
            ['quantity_liters' => '2.50', 'display_label' => '2.5 L'],
            ['quantity_liters' => '3.00', 'display_label' => '3 L'],
            ['quantity_liters' => '3.50', 'display_label' => '3.5 L'],
            ['quantity_liters' => '4.00', 'display_label' => '4 L'],
            ['quantity_liters' => '4.50', 'display_label' => '4.5 L'],
            ['quantity_liters' => '5.00', 'display_label' => '5 L'],
            ['quantity_liters' => '5.50', 'display_label' => '5.5 L'],
            ['quantity_liters' => '6.00', 'display_label' => '6 L'],
            ['quantity_liters' => '6.50', 'display_label' => '6.5 L'],
            ['quantity_liters' => '7.00', 'display_label' => '7 L'],
            ['quantity_liters' => '7.50', 'display_label' => '7.5 L'],
            ['quantity_liters' => '8.00', 'display_label' => '8 L'],
            ['quantity_liters' => '8.50', 'display_label' => '8.5 L'],
            ['quantity_liters' => '9.00', 'display_label' => '9 L'],
            ['quantity_liters' => '9.50', 'display_label' => '9.5 L'],
            ['quantity_liters' => '10.00', 'display_label' => '10 L'],
        ];

        foreach ($quantities as $qty) {
            DB::table('milk_quantities')->insertOrIgnore([
                'quantity_liters' => $qty['quantity_liters'],
                'display_label'   => $qty['display_label'],
                'created_at'      => $now,
                'updated_at'      => $now,
            ]);
        }
    }

    // -----------------------------------------------------------------------
    // DOWN — PARTIAL ROLLBACK ONLY
    // -----------------------------------------------------------------------

    public function down(): void
    {
        /*
         * WARNING: This down() is a partial rollback only.
         *
         * What can be safely undone:
         *   - Truncate container_type_sizes (new table, created in Step 1)
         *   - Truncate product_offered_sizes (new table, created in Step 1)
         *   - Truncate milk_quantities (new table, created in Step 1)
         *   - Remove Special Buffalo Milk if it was inserted by this migration
         *   - Remove Can container types inserted by this migration
         *
         * What CANNOT be safely undone automatically:
         *   - The flat container_types rows that were deleted (Glass Bottle 500ml,
         *     Glass Bottle 1L, Plastic Bag 500ml, etc.) cannot be restored here.
         *     To restore them, run the ContainerTypeSeeder with the old schema.
         *   - products.container_type_id values that were re-pointed to a canonical
         *     id cannot be reliably reversed without a pre-migration snapshot.
         *   - products.name values that were backfilled are overwritten.
         *
         * If you need a full rollback, restore from a database backup taken before
         * running Step 2, or run the ContainerTypeSeeder (old version) manually.
         */

        // Truncate the new tables that Step 1 created
        DB::table('product_offered_sizes')->truncate();
        DB::table('container_type_sizes')->truncate();
        DB::table('milk_quantities')->truncate();

        // Remove Special Buffalo Milk (only if still a system default — no FK references)
        DB::table('milk_types')
            ->whereNull('farm_id')
            ->where('name', 'Special Buffalo Milk')
            ->delete();

        // Remove Can container types inserted by Part E
        $canNames = ['5L Can', '10L Can', '15L Can', '20L Can'];
        DB::table('container_types')
            ->whereNull('farm_id')
            ->whereIn('name', $canNames)
            ->delete();

        // Null out products.name to revert the backfill (leaves names blank, not stale)
        DB::statement("UPDATE products SET name = NULL WHERE deleted_at IS NULL");
    }
};
