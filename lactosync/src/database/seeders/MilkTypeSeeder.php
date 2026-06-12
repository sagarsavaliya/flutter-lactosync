<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * MilkTypeSeeder — Sprint OR update.
 *
 * Seeds the 4 canonical Sprint OR milk type names as system defaults.
 * The 3 legacy short-name rows (Gir Cow, Cow, Buffalo) and the 3 regional
 * variants (Kankrej Cow, Mehoni Buffalo, Jafrabadi Buffalo) are NOT touched:
 * they may be referenced by existing products.milk_type_id on live farms and
 * must not be deleted or deactivated here.
 *
 * Safe to re-run: skips rows that already exist.
 */
class MilkTypeSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        // Sprint OR canonical system defaults — insert only if not already present.
        // These are NEW rows with new names; they do not replace the old short-name rows.
        $newDefaults = [
            'Gir Cow Milk',
            'Cow Milk',
            'Buffalo Milk',
            'Special Buffalo Milk',
        ];

        foreach ($newDefaults as $name) {
            $exists = DB::table('milk_types')
                ->whereNull('farm_id')
                ->where('name', $name)
                ->exists();

            if ($exists) {
                continue;
            }

            DB::table('milk_types')->insert([
                'farm_id'    => null,
                'name'       => $name,
                'is_active'  => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        // Legacy rows deliberately NOT seeded on fresh installs (kept for FK safety on live data):
        //   Gir Cow, Cow, Buffalo, Kankrej Cow, Mehoni Buffalo, Jafrabadi Buffalo
        // If this is a fresh environment they will simply not exist, which is correct.
    }
}
