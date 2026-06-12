<?php

namespace App\Support;

use App\Models\ContainerTypeSize;
use App\Models\Product;

class ProductPayload
{
    public static function make(Product $product): array
    {
        $product->loadMissing(['milkType', 'containerType.sizes']);

        $ct = $product->containerType;

        $containerKind = $ct ? self::kindFromName($ct->name) : null;

        $containerSizes = [];
        if ($ct && $ct->relationLoaded('sizes')) {
            foreach ($ct->sizes->sortBy('size_liters') as $size) {
                $liters = (float) $size->size_liters;
                $containerSizes[] = [
                    'id'         => $size->id,
                    'size_key'   => self::formatSizeKey($liters),
                    'size_label' => self::formatSizeLabel($liters),
                ];
            }
        }

        $containerTypeObject = $ct ? [
            'id'        => $ct->id,
            'name'      => $ct->name,
            'is_system' => $ct->farm_id === null,
            'is_active' => $ct->is_active,
            'sizes'     => $ct->relationLoaded('sizes')
                ? $ct->sizes->map(fn ($s) => (float) $s->size_liters)->values()->all()
                : [],
        ] : null;

        return [
            'id'                   => $product->id,
            'name'                 => $product->name,
            'milk_type_id'         => $product->milk_type_id,
            'milk_type'            => null,
            'milk_type_label'      => $product->milkType?->name ?? '',
            'rate'                 => (float) $product->rate,
            'unit'                 => $product->unit,
            'container_kind'       => $containerKind,
            'container_type_ids'   => [],
            'container_sizes'      => $containerSizes,
            'container_type_id'    => $product->container_type_id,
            'container_type'       => null,
            'container_type_object' => $containerTypeObject,
            'container_type_label' => $containerKind === 'glass_bottle'
                ? 'Glass Bottle'
                : ($containerKind === 'plastic_bag' ? 'Plastic Bag' : ($ct?->name ?? '')),
        ];
    }

    public static function kindFromName(?string $name): ?string
    {
        if ($name === null) {
            return null;
        }
        $lower = strtolower($name);
        if (str_contains($lower, 'bottle') || str_contains($lower, 'glass')) {
            return 'glass_bottle';
        }
        if (str_contains($lower, 'bag') || str_contains($lower, 'plastic')) {
            return 'plastic_bag';
        }
        return null;
    }

    public static function formatSizeLabel(float $liters): string
    {
        if ($liters < 1.0) {
            $ml = (int) round($liters * 1000);

            return "{$ml} ml";
        }
        if (fmod($liters, 1.0) === 0.0) {
            return ((int) $liters).' L';
        }

        return "{$liters} L";
    }

    public static function formatSizeKey(float $liters): string
    {
        if ($liters < 1.0) {
            $ml = (int) round($liters * 1000);

            return "{$ml}ml";
        }
        if (fmod($liters, 1.0) === 0.0) {
            return ((int) $liters).'L';
        }

        return "{$liters}L";
    }
}
