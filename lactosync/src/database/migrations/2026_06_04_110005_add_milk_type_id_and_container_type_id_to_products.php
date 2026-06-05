<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ─── Step 1: Inline seed system defaults so data migration can reference them ───
        // These inserts are idempotent (insertOrIgnore). The standalone MilkTypeSeeder
        // and ContainerTypeSeeder call the same data — running them afterwards is safe.

        $now = now();

        DB::table('milk_types')->insertOrIgnore([
            ['farm_id' => null, 'name' => 'Gir Cow',           'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Cow',               'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Buffalo',           'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Kankrej Cow',       'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Mehoni Buffalo',    'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Jafrabadi Buffalo', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ]);

        DB::table('container_types')->insertOrIgnore([
            ['farm_id' => null, 'name' => 'Plastic Bag 500ml',  'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Plastic Bag 1L',     'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Plastic Bag 1.5L',   'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Plastic Bag 2L',     'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Glass Bottle 500ml', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Glass Bottle 1L',    'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ]);

        // ─── Step 2: Add FK columns to products ──────────────────────────────────────

        Schema::table('products', function (Blueprint $table) {
            // Make existing VARCHAR columns nullable (keep for rollback safety)
            $table->string('milk_type')->nullable()->change();
            $table->string('container_type')->nullable()->change();

            // New FK columns — nullable during migration; set NOT NULL in a future sprint
            $table->unsignedBigInteger('milk_type_id')->nullable()->after('milk_type');
            $table->unsignedBigInteger('container_type_id')->nullable()->after('container_type');

            $table->foreign('milk_type_id', 'fk_products_milk_type_id')
                  ->references('id')->on('milk_types')->restrictOnDelete();

            $table->foreign('container_type_id', 'fk_products_container_type_id')
                  ->references('id')->on('container_types')->restrictOnDelete();

            // Composite indexes for farm-filtered queries
            $table->index(['farm_id', 'milk_type_id'], 'idx_products_milk_type_id');
            $table->index(['farm_id', 'container_type_id'], 'idx_products_container_type_id');
        });

        // ─── Step 3: Data migration — map old VARCHAR values → FK ids ──────────────
        // This is a lossy mapping by design (see schema spec). The old varchar columns
        // are retained so original values can be audited after migration.

        $milkTypeMap = [
            'gir_cow' => DB::table('milk_types')->where('farm_id', null)->where('name', 'Gir Cow')->value('id'),
            'cow'     => DB::table('milk_types')->where('farm_id', null)->where('name', 'Cow')->value('id'),
            'buffalo' => DB::table('milk_types')->where('farm_id', null)->where('name', 'Buffalo')->value('id'),
        ];

        $containerTypeMap = [
            'glass_bottle' => DB::table('container_types')->where('farm_id', null)->where('name', 'Glass Bottle 1L')->value('id'),
            'plastic_bag'  => DB::table('container_types')->where('farm_id', null)->where('name', 'Plastic Bag 1L')->value('id'),
        ];

        foreach ($milkTypeMap as $oldValue => $newId) {
            if ($newId) {
                DB::table('products')
                    ->whereNull('deleted_at')
                    ->where('milk_type', $oldValue)
                    ->update(['milk_type_id' => $newId]);
            }
        }

        foreach ($containerTypeMap as $oldValue => $newId) {
            if ($newId) {
                DB::table('products')
                    ->whereNull('deleted_at')
                    ->where('container_type', $oldValue)
                    ->update(['container_type_id' => $newId]);
            }
        }

        // Log unmapped rows so they can be reviewed before the old columns are dropped
        $unmappedMilk = DB::table('products')
            ->whereNull('deleted_at')
            ->whereNull('milk_type_id')
            ->whereNotNull('milk_type')
            ->count();

        $unmappedContainer = DB::table('products')
            ->whereNull('deleted_at')
            ->whereNull('container_type_id')
            ->whereNotNull('container_type')
            ->count();

        if ($unmappedMilk > 0) {
            echo "WARNING: {$unmappedMilk} product row(s) have unmapped milk_type values — milk_type_id left NULL.\n";
        }

        if ($unmappedContainer > 0) {
            echo "WARNING: {$unmappedContainer} product row(s) have unmapped container_type values — container_type_id left NULL.\n";
        }
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign('fk_products_milk_type_id');
            $table->dropForeign('fk_products_container_type_id');
            $table->dropIndex('idx_products_milk_type_id');
            $table->dropIndex('idx_products_container_type_id');
            $table->dropColumn(['milk_type_id', 'container_type_id']);

            // Restore non-nullable (assumes original schema had NOT NULL)
            $table->string('milk_type')->nullable(false)->change();
            $table->string('container_type')->nullable(false)->change();
        });
    }
};
