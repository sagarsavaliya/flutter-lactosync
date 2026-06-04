<?php

namespace App\Services\Operations;

use App\Enums\ContainerType;

/**
 * Splits subscription/order litres into container counts for daily prep.
 *
 * Glass bottles: 1 L and 500 ml only (greedy largest first).
 * Plastic bags: 2 L, 1.5 L, 1 L, 500 ml (greedy largest first).
 */
class MilkPreparationCalculator
{
    /** @var array<string, int> ml keyed by size key */
    private const GLASS_SIZES = [
        '1L' => 1000,
        '500ml' => 500,
    ];

    /** @var array<string, int> ml keyed by size key */
    private const PLASTIC_SIZES = [
        '2L' => 2000,
        '1.5L' => 1500,
        '1L' => 1000,
        '500ml' => 500,
    ];

    /**
     * @return array<string, int> size key => count
     */
    public function pack(float $litres, ContainerType $containerType): array
    {
        $sizes = $containerType === ContainerType::GlassBottle
            ? self::GLASS_SIZES
            : self::PLASTIC_SIZES;

        $remainingMl = (int) round($litres * 1000);
        if ($remainingMl <= 0) {
            return $this->emptyCounts($sizes);
        }

        $counts = $this->emptyCounts($sizes);

        foreach ($sizes as $key => $ml) {
            if ($ml <= 0) {
                continue;
            }
            $count = intdiv($remainingMl, $ml);
            $counts[$key] = $count;
            $remainingMl -= $count * $ml;
        }

        if ($remainingMl > 0) {
            $smallestKey = array_key_last($sizes);
            $counts[$smallestKey] += 1;
        }

        return $counts;
    }

    /**
     * @param  array<string, int>  $a
     * @param  array<string, int>  $b
     * @return array<string, int>
     */
    public function mergeCounts(array $a, array $b): array
    {
        $merged = $a;
        foreach ($b as $key => $value) {
            $merged[$key] = ($merged[$key] ?? 0) + $value;
        }

        return $merged;
    }

    /**
     * @return list<array{key: string, label: string}>
     */
    public function sizeColumns(ContainerType $containerType): array
    {
        $sizes = $containerType === ContainerType::GlassBottle
            ? self::GLASS_SIZES
            : self::PLASTIC_SIZES;

        $columns = array_map(
            fn (string $key, int $ml) => [
                'key' => $key,
                'label' => $this->sizeLabel($ml),
                'ml' => $ml,
            ],
            array_keys($sizes),
            array_values($sizes),
        );

        usort($columns, fn (array $a, array $b) => $a['ml'] <=> $b['ml']);

        return array_map(
            fn (array $column) => [
                'key' => $column['key'],
                'label' => $column['label'],
            ],
            $columns,
        );
    }

    public function containerLabel(ContainerType $containerType): string
    {
        return match ($containerType) {
            ContainerType::GlassBottle => 'Glass Bottles',
            ContainerType::PlasticBag => 'Plastic Bags',
        };
    }

    /**
     * @param  array<string, int>  $counts
     */
    public function litresFromCounts(array $counts, ContainerType $containerType): float
    {
        $sizes = $containerType === ContainerType::GlassBottle
            ? self::GLASS_SIZES
            : self::PLASTIC_SIZES;

        $ml = 0;
        foreach ($sizes as $key => $sizeMl) {
            $ml += ($counts[$key] ?? 0) * $sizeMl;
        }

        return round($ml / 1000, 2);
    }

    private function sizeLabel(int $ml): string
    {
        if ($ml >= 1000 && $ml % 1000 === 0) {
            $litres = $ml / 1000;

            return fmod($litres, 1.0) === 0.0
                ? ((int) $litres).' L'
                : $litres.' L';
        }

        return $ml >= 1000
            ? ($ml / 1000).' L'
            : $ml.' ml';
    }

    /**
     * @param  array<string, int>  $sizes
     * @return array<string, int>
     */
    private function emptyCounts(array $sizes): array
    {
        $counts = [];
        foreach (array_keys($sizes) as $key) {
            $counts[$key] = 0;
        }

        return $counts;
    }
}
