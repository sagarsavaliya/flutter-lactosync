<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MilkTypeSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        DB::table('milk_types')->insertOrIgnore([
            ['farm_id' => null, 'name' => 'Gir Cow',           'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Cow',               'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Buffalo',           'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Kankrej Cow',       'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Mehoni Buffalo',    'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['farm_id' => null, 'name' => 'Jafrabadi Buffalo', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ]);
    }
}
