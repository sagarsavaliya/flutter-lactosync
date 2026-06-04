<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ContainerTypeSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        DB::table('container_types')->insertOrIgnore([
            ['farm_id' => null, 'name' => 'Plastic Bag 500ml',  'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Plastic Bag 1L',     'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Plastic Bag 1.5L',   'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Plastic Bag 2L',     'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Glass Bottle 500ml', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Glass Bottle 1L',    'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ]);
    }
}
