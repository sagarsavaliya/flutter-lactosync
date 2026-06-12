<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Sprint 7 — Container type cleanup + delivery_type.
 *
 * SAFETY: only touches rows WHERE farm_id IS NULL (system defaults).
 * Farm-specific custom types (e.g. Farm 3 Plastic Bag id=18) are NEVER modified.
 *
 * Parts:
 *   A  Remove unrealistic sizes from system Plastic Bag (2.5L, 5L, 10L)
 *   B  Remove unrealistic sizes from system Glass Bottle (5L, 10L)
 *   C  Delete 4 system Can types — confirmed 0 product references on live VPS
 *      (CASCADE handles container_type_sizes + farm_container_type_visibility)
 *   D  Insert Bulk Container system type with sizes 4L, 5L, 6L
 *   E  Add delivery_type ENUM to customers (default: home_delivery)
 */
return new class extends Migration
{
    private array $canNames = ['5L Can', '10L Can', '15L Can', '20L Can'];

    public function up(): void
    {
        $this->partA_cleanPlasticBagSizes();
        $this->partB_cleanGlassBottleSizes();
        $this->partC_deleteCanTypes();
        $this->partD_insertBulkContainer();
        $this->partE_addDeliveryType();
    }

    private function partA_cleanPlasticBagSizes(): void
    {
        $id = DB::table('container_types')
            ->whereNull('farm_id')
            ->where('name', 'Plastic Bag')
            ->value('id');

        if ($id === null) {
            return;
        }

        DB::table('container_type_sizes')
            ->where('container_type_id', $id)
            ->whereIn('size_liters', ['2.50', '5.00', '10.00'])
            ->delete();
    }

    private function partB_cleanGlassBottleSizes(): void
    {
        $id = DB::table('container_types')
            ->whereNull('farm_id')
            ->where('name', 'Glass Bottle')
            ->value('id');

        if ($id === null) {
            return;
        }

        DB::table('container_type_sizes')
            ->where('container_type_id', $id)
            ->whereIn('size_liters', ['5.00', '10.00'])
            ->delete();
    }

    private function partC_deleteCanTypes(): void
    {
        // CASCADE on container_type_sizes and farm_container_type_visibility
        // automatically cleans up related rows.
        DB::table('container_types')
            ->whereNull('farm_id')
            ->whereIn('name', $this->canNames)
            ->delete();
    }

    private function partD_insertBulkContainer(): void
    {
        $now = now();

        $existing = DB::table('container_types')
            ->whereNull('farm_id')
            ->where('name', 'Bulk Container')
            ->first();

        $id = $existing
            ? $existing->id
            : DB::table('container_types')->insertGetId([
                'farm_id'    => null,
                'name'       => 'Bulk Container',
                'is_active'  => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

        foreach (['4.00', '5.00', '6.00'] as $size) {
            DB::table('container_type_sizes')->insertOrIgnore([
                'container_type_id' => $id,
                'size_liters'       => $size,
                'created_at'        => $now,
                'updated_at'        => $now,
            ]);
        }
    }

    private function partE_addDeliveryType(): void
    {
        if (Schema::hasColumn('customers', 'delivery_type')) {
            return;
        }

        Schema::table('customers', function (Blueprint $table) {
            $table->enum('delivery_type', ['home_delivery', 'walk_in'])
                  ->default('home_delivery')
                  ->after('is_active');
        });
    }

    public function down(): void
    {
        if (Schema::hasColumn('customers', 'delivery_type')) {
            Schema::table('customers', function (Blueprint $table) {
                $table->dropColumn('delivery_type');
            });
        }

        // Remove Bulk Container (CASCADE handles its sizes)
        DB::table('container_types')
            ->whereNull('farm_id')
            ->where('name', 'Bulk Container')
            ->delete();

        // Note: Deleted Can types and removed sizes cannot be restored here.
        // Re-run ContainerTypeSeeder (original) or restore from backup if needed.
    }
};
