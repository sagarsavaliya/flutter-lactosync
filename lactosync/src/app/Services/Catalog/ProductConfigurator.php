<?php

namespace App\Services\Catalog;

use App\Models\ContainerType;
use App\Models\ContainerTypeSize;
use App\Models\MilkType;
use App\Models\Product;
use App\Support\ProductPayload;

class ProductConfigurator
{
    public function generateName(?MilkType $milkType, ?string $legacyMilkType, float $rate): string
    {
        $label = $milkType?->name ?? match ($legacyMilkType) {
            'gir_cow' => 'Gir Cow',
            'buffalo' => 'Buffalo',
            'cow' => 'Cow',
            default => 'Milk',
        };

        $rateLabel = fmod($rate, 1.0) === 0.0
            ? (string) (int) $rate
            : number_format($rate, 0);

        return "{$label} Milk - {$rateLabel}/-";
    }

    /**
     * @return array<string, int>  size_key => ml (largest first)
     *
     * Uses the container type's sizes from container_type_sizes.
     * Falls back to an empty array if the product has no container type or its
     * container type has no sizes configured.
     */
    public function allowedSizeMap(Product $product, int $farmId): array
    {
        $product->loadMissing('containerType.sizes');

        $ct = $product->containerType;
        if (! $ct) {
            return [];
        }

        return $ct->sizes
            ->sortByDesc('size_liters')
            ->mapWithKeys(fn (ContainerTypeSize $size) => [
                ProductPayload::formatSizeKey((float) $size->size_liters) => (int) round((float) $size->size_liters * 1000),
            ])
            ->all();
    }
}
