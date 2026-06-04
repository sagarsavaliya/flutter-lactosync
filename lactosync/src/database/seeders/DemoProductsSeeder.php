<?php

namespace Database\Seeders;

use App\Models\Farm;
use App\Models\Product;
use App\Models\SubscriptionLine;
use Illuminate\Database\Seeder;

class DemoProductsSeeder extends Seeder
{
    /** @var list<array{name: string, milk_type: string, rate: float, container_type: string}> */
    private const CATALOG = [
        ['name' => 'Buffalo Milk', 'milk_type' => 'buffalo', 'rate' => 80, 'container_type' => 'glass_bottle'],
        ['name' => 'Buffalo Milk', 'milk_type' => 'buffalo', 'rate' => 100, 'container_type' => 'glass_bottle'],
        ['name' => 'Cow Milk', 'milk_type' => 'cow', 'rate' => 80, 'container_type' => 'glass_bottle'],
        ['name' => 'Cow Milk', 'milk_type' => 'cow', 'rate' => 100, 'container_type' => 'glass_bottle'],
        ['name' => 'Buffalo Milk', 'milk_type' => 'buffalo', 'rate' => 65, 'container_type' => 'plastic_bag'],
        ['name' => 'Buffalo Milk', 'milk_type' => 'buffalo', 'rate' => 70, 'container_type' => 'plastic_bag'],
        ['name' => 'Cow Milk', 'milk_type' => 'cow', 'rate' => 67, 'container_type' => 'plastic_bag'],
        ['name' => 'Cow Milk', 'milk_type' => 'cow', 'rate' => 74, 'container_type' => 'plastic_bag'],
    ];

    public function run(): void
    {
        $farms = Farm::query()->get();

        if ($farms->isEmpty()) {
            $this->command?->warn('No farms found — register an owner first.');

            return;
        }

        foreach ($farms as $farm) {
            $created = 0;

            foreach (self::CATALOG as $item) {
                $product = Product::query()->updateOrCreate(
                    [
                        'farm_id' => $farm->id,
                        'milk_type' => $item['milk_type'],
                        'container_type' => $item['container_type'],
                        'rate' => $item['rate'],
                    ],
                    [
                        'name' => $item['name'],
                        'unit' => 'ltr',
                        'is_active' => true,
                    ],
                );

                if ($product->wasRecentlyCreated) {
                    $created++;
                }
            }

            $deactivated = $this->retireLegacyProducts($farm);

            $this->command?->info(
                "Farm #{$farm->id}: ensured milk prep catalog ({$created} new products, {$farm->products()->where('is_active', true)->count()} active, {$deactivated} legacy retired).",
            );
        }
    }

    private function retireLegacyProducts(Farm $farm): int
    {
        $catalogKeys = collect(self::CATALOG)
            ->map(fn (array $item): string => $this->catalogKey(
                $item['milk_type'],
                $item['container_type'],
                (float) $item['rate'],
            ))
            ->all();

        $legacyProducts = Product::query()
            ->where('farm_id', $farm->id)
            ->where('is_active', true)
            ->get()
            ->filter(function (Product $product) use ($catalogKeys): bool {
                $key = $this->catalogKey(
                    $product->milk_type->value,
                    $product->container_type->value,
                    (float) $product->rate,
                );

                return ! in_array($key, $catalogKeys, true);
            });

        $retired = 0;

        foreach ($legacyProducts as $legacy) {
            $replacement = Product::query()
                ->where('farm_id', $farm->id)
                ->where('is_active', true)
                ->where('container_type', $legacy->container_type)
                ->where('milk_type', $legacy->milk_type)
                ->orderBy('rate')
                ->first()
                ?? Product::query()
                    ->where('farm_id', $farm->id)
                    ->where('is_active', true)
                    ->where('container_type', $legacy->container_type)
                    ->orderBy('rate')
                    ->first();

            if ($replacement !== null && $replacement->id !== $legacy->id) {
                SubscriptionLine::query()
                    ->where('product_id', $legacy->id)
                    ->get()
                    ->each(function (SubscriptionLine $line) use ($replacement): void {
                        $line->update([
                            'product_id' => $replacement->id,
                            'unit_rate' => $replacement->rate,
                            'effective_rate' => SubscriptionLine::computeEffectiveRate(
                                (float) $replacement->rate,
                                (float) $line->coupon_amount,
                            ),
                        ]);
                    });
            }

            $legacy->update(['is_active' => false]);
            $retired++;
        }

        return $retired;
    }

    private function catalogKey(string $milkType, string $containerType, float $rate): string
    {
        return "{$milkType}|{$containerType}|{$rate}";
    }
}
