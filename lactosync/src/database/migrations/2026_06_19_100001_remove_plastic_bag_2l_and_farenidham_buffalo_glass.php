<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * 1. Remove 2L from system Plastic Bag default sizes.
 * 2. Farenidham Gaushala: reassign buffalo glass-bottle subscriptions to buffalo plastic bag,
 *    remove duplicate glass product, hide Glass Bottle for that farm.
 */
return new class extends Migration
{
    public function up(): void
    {
        $this->removePlasticBagTwoLiterSize();
        $this->consolidateFarenidhamBuffaloProducts();
    }

    public function down(): void
    {
        // Data migration — no automatic rollback.
    }

    private function removePlasticBagTwoLiterSize(): void
    {
        $plasticBagId = DB::table('container_types')
            ->whereNull('farm_id')
            ->where('name', 'Plastic Bag')
            ->value('id');

        if ($plasticBagId === null) {
            return;
        }

        DB::table('container_type_sizes')
            ->where('container_type_id', $plasticBagId)
            ->where('size_liters', '2.00')
            ->delete();
    }

    private function consolidateFarenidhamBuffaloProducts(): void
    {
        $farmId = DB::table('farm_owners')
            ->where('mobile', '9998866008')
            ->value('farm_id');

        if ($farmId === null) {
            return;
        }

        $glassTypeId = DB::table('container_types')
            ->whereNull('farm_id')
            ->where('name', 'Glass Bottle')
            ->value('id');

        $plasticTypeId = DB::table('container_types')
            ->whereNull('farm_id')
            ->where('name', 'Plastic Bag')
            ->value('id');

        if ($glassTypeId === null || $plasticTypeId === null) {
            return;
        }

        $glassProductId = DB::table('products')
            ->where('farm_id', $farmId)
            ->where('container_type_id', $glassTypeId)
            ->whereRaw('LOWER(name) LIKE ?', ['%buffalo%'])
            ->value('id');

        $plasticProductId = DB::table('products')
            ->where('farm_id', $farmId)
            ->where('container_type_id', $plasticTypeId)
            ->whereRaw('LOWER(name) LIKE ?', ['%buffalo%'])
            ->value('id');

        if ($glassProductId === null || $plasticProductId === null || $glassProductId === $plasticProductId) {
            return;
        }

        DB::table('subscription_lines')
            ->where('product_id', $glassProductId)
            ->update(['product_id' => $plasticProductId]);

        $plasticProductName = DB::table('products')
            ->where('id', $plasticProductId)
            ->value('name');

        if ($plasticProductName !== null) {
            DB::table('daily_order_logs')
                ->where('product_id', $glassProductId)
                ->where('status', 'pending')
                ->update([
                    'product_id'   => $plasticProductId,
                    'product_name' => $plasticProductName,
                ]);
        }

        DB::table('products')->where('id', $glassProductId)->delete();

        DB::table('farm_container_type_visibility')->insertOrIgnore([
            'farm_id'           => $farmId,
            'container_type_id' => $glassTypeId,
            'created_at'        => now(),
        ]);
    }
};
