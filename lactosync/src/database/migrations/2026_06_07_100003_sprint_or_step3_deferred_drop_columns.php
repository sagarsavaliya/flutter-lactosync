<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/*
 * DEFERRED MIGRATION — DO NOT RUN until:
 * 1. Sprint OR APK is built and installed on all live farm devices
 * 2. Human confirms all features are working correctly on live farm
 * 3. CEO or farm owner gives explicit approval to run this step
 *
 * This migration removes columns made redundant by Step 1 + Step 2.
 * Running it too early will break any running instance of the old APK
 * that still reads kind / size_ml / size_key from the container_types
 * endpoint, or reads milk_type / container_type / container_kind from
 * the products endpoint.
 *
 * Pre-requisites before running:
 *   - OwnerProductTypesController::containerTypePayload() no longer reads
 *     kind, size_ml, size_key, or size_label.
 *   - OwnerProductTypesController::indexContainerTypes() sort updated to
 *     orderBy('name') (kind/size_ml columns will not exist after this runs).
 *   - ContainerType::$fillable, scopeForKind(), and sizeLabel() removed.
 *   - Product::$fillable no longer lists milk_type, container_type,
 *     container_kind.
 *   - No code path reads Product::allowedContainers() or
 *     ContainerType::products() (both use the product_container_types pivot).
 *   - Grep confirms no remaining references to product_container_types.
 */
return new class extends Migration
{
    public function up(): void
    {
        // ----------------------------------------------------------------
        // 1. Drop legacy columns from container_types
        //    kind, size_ml, size_key are now modelled in container_type_sizes.
        // ----------------------------------------------------------------
        Schema::table('container_types', function (Blueprint $table) {
            // Drop the composite index before dropping its columns
            if ($this->indexExists('container_types', 'idx_container_types_kind_size')) {
                $table->dropIndex('idx_container_types_kind_size');
            }

            $toDrop = array_filter(
                ['kind', 'size_ml', 'size_key'],
                fn (string $col) => Schema::hasColumn('container_types', $col)
            );

            if (! empty($toDrop)) {
                $table->dropColumn(array_values($toDrop));
            }
        });

        // ----------------------------------------------------------------
        // 2. Drop legacy columns from products
        //    milk_type, container_type, container_kind are legacy string
        //    denormalisations superseded by FK columns and the new tables.
        // ----------------------------------------------------------------
        Schema::table('products', function (Blueprint $table) {
            $toDrop = array_filter(
                ['milk_type', 'container_type', 'container_kind'],
                fn (string $col) => Schema::hasColumn('products', $col)
            );

            if (! empty($toDrop)) {
                $table->dropColumn(array_values($toDrop));
            }
        });

        // ----------------------------------------------------------------
        // 3. Drop the old product_container_types pivot table
        //    All FK data has been migrated to product_offered_sizes (Step 2).
        //    Confirm via grep that no controller or model still reads this table
        //    before running this migration.
        // ----------------------------------------------------------------
        Schema::dropIfExists('product_container_types');
    }

    /**
     * Helper: check whether a named index exists on a table.
     * Uses information_schema to avoid throwing on missing index.
     */
    private function indexExists(string $table, string $indexName): bool
    {
        $dbName = \Illuminate\Support\Facades\DB::getDatabaseName();

        $count = \Illuminate\Support\Facades\DB::table('information_schema.statistics')
            ->where('table_schema', $dbName)
            ->where('table_name', $table)
            ->where('index_name', $indexName)
            ->count();

        return $count > 0;
    }

    public function down(): void
    {
        /*
         * DOWN IS NOT SAFELY REVERSIBLE.
         *
         * Dropped columns (kind, size_ml, size_key, milk_type, container_type,
         * container_kind) cannot be restored from this migration alone.
         * Their data would need to be reconstructed from container_type_sizes
         * and the current product FK values — which is a non-trivial operation.
         *
         * The dropped product_container_types table would need to be re-created
         * and re-populated from product_offered_sizes.
         *
         * If you need to roll back Step 3, restore from a database backup taken
         * immediately before running this migration.
         *
         * Do NOT implement an automated down() here — a false sense of
         * reversibility is more dangerous than an explicit "not implemented".
         */
        throw new \RuntimeException(
            'Sprint OR Step 3 down() is not safely reversible. ' .
            'Restore from a pre-migration database backup.'
        );
    }
};
