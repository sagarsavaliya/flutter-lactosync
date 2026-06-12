<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Migration + manual seed both inserted system defaults (farm_id NULL).
 * MySQL unique(farm_id, name) does not dedupe multiple NULL farm_id rows.
 */
return new class extends Migration
{
    public function up(): void
    {
        $this->dedupeTable(
            table: 'milk_types',
            fkColumn: 'milk_type_id',
            visibilityTable: 'farm_milk_type_visibility',
            visibilityFkColumn: 'milk_type_id',
        );

        $this->dedupeTable(
            table: 'container_types',
            fkColumn: 'container_type_id',
            visibilityTable: 'farm_container_type_visibility',
            visibilityFkColumn: 'container_type_id',
        );
    }

    private function dedupeTable(
        string $table,
        string $fkColumn,
        string $visibilityTable,
        string $visibilityFkColumn,
    ): void {
        $duplicateNames = DB::table($table)
            ->whereNull('farm_id')
            ->select('name')
            ->groupBy('name')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('name');

        foreach ($duplicateNames as $name) {
            $ids = DB::table($table)
                ->whereNull('farm_id')
                ->where('name', $name)
                ->orderBy('id')
                ->pluck('id')
                ->all();

            if (count($ids) < 2) {
                continue;
            }

            $keepId = array_shift($ids);

            foreach ($ids as $dupId) {
                DB::table('products')->where($fkColumn, $dupId)->update([$fkColumn => $keepId]);

                $visibilityRows = DB::table($visibilityTable)
                    ->where($visibilityFkColumn, $dupId)
                    ->get();

                foreach ($visibilityRows as $row) {
                    $exists = DB::table($visibilityTable)
                        ->where('farm_id', $row->farm_id)
                        ->where($visibilityFkColumn, $keepId)
                        ->exists();

                    if ($exists) {
                        DB::table($visibilityTable)->where('id', $row->id)->delete();
                    } else {
                        DB::table($visibilityTable)
                            ->where('id', $row->id)
                            ->update([$visibilityFkColumn => $keepId]);
                    }
                }

                DB::table($table)->where('id', $dupId)->delete();
            }
        }
    }

    public function down(): void
    {
        // Data repair — not reversible.
    }
};
