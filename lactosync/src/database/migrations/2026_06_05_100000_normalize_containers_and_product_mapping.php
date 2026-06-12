<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('container_types', function (Blueprint $table) {
            $table->string('kind', 20)->nullable()->after('name');
            $table->unsignedInteger('size_ml')->nullable()->after('kind');
            $table->string('size_key', 10)->nullable()->after('size_ml');

            $table->index(['kind', 'size_ml'], 'idx_container_types_kind_size');
        });

        $this->backfillContainerMetadata();

        Schema::create('product_container_types', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('container_type_id')->constrained('container_types')->restrictOnDelete();
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['product_id', 'container_type_id'], 'uniq_product_container_type');
            $table->index('container_type_id', 'idx_product_container_types_container');
        });

        Schema::table('products', function (Blueprint $table) {
            $table->string('container_kind', 20)->nullable()->after('container_type_id');
        });

        $this->backfillProductContainerMappings();
    }

    private function backfillContainerMetadata(): void
    {
        $rows = DB::table('container_types')->get();

        foreach ($rows as $row) {
            [$kind, $sizeMl, $sizeKey] = $this->parseContainerName($row->name);

            DB::table('container_types')->where('id', $row->id)->update([
                'kind' => $kind,
                'size_ml' => $sizeMl,
                'size_key' => $sizeKey,
            ]);
        }

        $now = now();
        $extraSizes = [
            ['kind' => 'plastic_bag', 'name' => 'Plastic Bag 5L', 'size_ml' => 5000, 'size_key' => '5L'],
            ['kind' => 'plastic_bag', 'name' => 'Plastic Bag 10L', 'size_ml' => 10000, 'size_key' => '10L'],
            ['kind' => 'glass_bottle', 'name' => 'Glass Bottle 5L', 'size_ml' => 5000, 'size_key' => '5L'],
            ['kind' => 'glass_bottle', 'name' => 'Glass Bottle 10L', 'size_ml' => 10000, 'size_key' => '10L'],
        ];

        foreach ($extraSizes as $size) {
            $exists = DB::table('container_types')
                ->whereNull('farm_id')
                ->where('name', $size['name'])
                ->exists();

            if ($exists) {
                continue;
            }

            DB::table('container_types')->insert([
                'farm_id' => null,
                'name' => $size['name'],
                'kind' => $size['kind'],
                'size_ml' => $size['size_ml'],
                'size_key' => $size['size_key'],
                'is_active' => 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    /**
     * @return array{0: string, 1: int, 2: string}
     */
    private function parseContainerName(string $name): array
    {
        $lower = strtolower($name);

        $kind = str_contains($lower, 'glass') ? 'glass_bottle' : 'plastic_bag';

        if (preg_match('/(\d+(?:\.\d+)?)\s*l\b/i', $name, $matches)) {
            $litres = (float) $matches[1];
            $sizeMl = (int) round($litres * 1000);
            $sizeKey = fmod($litres, 1.0) === 0.0
                ? ((int) $litres).'L'
                : $litres.'L';

            return [$kind, $sizeMl, $sizeKey];
        }

        if (preg_match('/(\d+)\s*ml\b/i', $name, $matches)) {
            $sizeMl = (int) $matches[1];

            return [$kind, $sizeMl, $sizeMl.'ml'];
        }

        return [$kind, 1000, '1L'];
    }

    private function backfillProductContainerMappings(): void
    {
        $containerByKind = DB::table('container_types')
            ->whereNull('farm_id')
            ->where('is_active', 1)
            ->whereNotNull('kind')
            ->orderByDesc('size_ml')
            ->get()
            ->groupBy('kind');

        $products = DB::table('products')->whereNull('deleted_at')->get();

        foreach ($products as $product) {
            $kind = $this->resolveProductKind($product);

            if ($kind === null) {
                continue;
            }

            DB::table('products')->where('id', $product->id)->update([
                'container_kind' => $kind,
            ]);

            $defaultSizes = match ($kind) {
                'glass_bottle' => ['1L', '500ml'],
                default => ['2L', '1.5L', '1L', '500ml'],
            };

            $containers = ($containerByKind[$kind] ?? collect())
                ->filter(fn ($row) => in_array($row->size_key, $defaultSizes, true))
                ->values();

            if ($containers->isEmpty()) {
                continue;
            }

            foreach ($containers as $container) {
                DB::table('product_container_types')->insertOrIgnore([
                    'product_id' => $product->id,
                    'container_type_id' => $container->id,
                    'created_at' => now(),
                ]);
            }
        }
    }

    private function resolveProductKind(object $product): ?string
    {
        if (! empty($product->container_kind)) {
            return $product->container_kind;
        }

        if (! empty($product->container_type_id)) {
            $kind = DB::table('container_types')
                ->where('id', $product->container_type_id)
                ->value('kind');

            if ($kind) {
                return $kind;
            }
        }

        return match ((string) ($product->container_type ?? '')) {
            'glass_bottle' => 'glass_bottle',
            'plastic_bag' => 'plastic_bag',
            default => null,
        };
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('container_kind');
        });

        Schema::dropIfExists('product_container_types');

        Schema::table('container_types', function (Blueprint $table) {
            $table->dropIndex('idx_container_types_kind_size');
            $table->dropColumn(['kind', 'size_ml', 'size_key']);
        });
    }
};
