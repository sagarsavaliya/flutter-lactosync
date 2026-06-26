<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * ContainerTypeSeeder — 3 system defaults (Sprint 7+).
 *
 * Seeds system-default container types (farm_id = null) using the
 * container_type_sizes relationship.  One row per type; multiple size rows.
 *
 * Defaults:
 *   Glass Bottle   — 500ml, 1L
 *   Plastic Bag    — 500ml, 1L, 1.5L
 *   Bulk Container — 4L, 5L, 6L  (for walk-in / wholesale)
 *
 * Safe to re-run: uses updateOrCreate / insertOrIgnore patterns throughout.
 */
class ContainerTypeSeeder extends Seeder
{
    /**
     * System-default container types with their available sizes.
     *
     * @var array<array{name: string, sizes: float[]}>
     */
    private array $defaults = [
        [
            'name'  => 'Glass Bottle',
            'sizes' => [0.5, 1.0],
        ],
        [
            'name'  => 'Plastic Bag',
            'sizes' => [0.5, 1.0, 1.5],
        ],
        [
            'name'  => 'Bulk Container',
            'sizes' => [4.0, 5.0, 6.0],
        ],
    ];

    public function run(): void
    {
        $now = now();

        foreach ($this->defaults as $entry) {
            // Upsert the container_type row keyed on (farm_id=null, name)
            $existing = DB::table('container_types')
                ->whereNull('farm_id')
                ->where('name', $entry['name'])
                ->first();

            if ($existing) {
                // Ensure it is marked active (idempotent)
                DB::table('container_types')
                    ->where('id', $existing->id)
                    ->update(['is_active' => 1, 'updated_at' => $now]);

                $containerTypeId = $existing->id;
            } else {
                $containerTypeId = DB::table('container_types')->insertGetId([
                    'farm_id'    => null,
                    'name'       => $entry['name'],
                    'is_active'  => 1,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            // Sync container_type_sizes — insert any missing sizes, never delete existing ones
            foreach ($entry['sizes'] as $sizeLiters) {
                DB::table('container_type_sizes')->insertOrIgnore([
                    'container_type_id' => $containerTypeId,
                    'size_liters'       => $sizeLiters,
                    'created_at'        => $now,
                    'updated_at'        => $now,
                ]);
            }
        }
    }
}
