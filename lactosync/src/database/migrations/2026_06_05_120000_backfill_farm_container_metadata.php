<?php

use App\Support\ContainerTypeMetadata;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $rows = DB::table('container_types')
            ->whereNotNull('farm_id')
            ->where(function ($query) {
                $query->whereNull('kind')
                    ->orWhereNull('size_ml')
                    ->orWhereNull('size_key');
            })
            ->get();

        foreach ($rows as $row) {
            try {
                $meta = ContainerTypeMetadata::resolve($row->name);
            } catch (\Throwable) {
                continue;
            }

            DB::table('container_types')->where('id', $row->id)->update([
                'kind' => $meta['kind'],
                'size_ml' => $meta['size_ml'],
                'size_key' => $meta['size_key'],
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        // Data repair — not reversible.
    }
};
