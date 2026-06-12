<?php

namespace App\Services\Operations;

/**
 * Greedy bin-pack: splits subscription/order litres into container counts.
 *
 * All public methods work with dynamic sizes derived from container_type_sizes
 * rows — no hardcoded glass/plastic constants.
 */
class MilkPreparationCalculator
{
    /**
     * Convert size_liters float values from container_type_sizes into the
     * string-keyed ml map required by packWithSizes().
     *
     * @param  float[]  $sizeLiters  e.g. [2.0, 1.5, 1.0, 0.5]
     * @return array<string, int>    e.g. ['2L' => 2000, '1.5L' => 1500, ...]
     */
    public function sizesMapFromLiters(array $sizeLiters): array
    {
        $map = [];
        foreach ($sizeLiters as $liters) {
            $ml = (int) round((float) $liters * 1000);
            $map[$this->sizeKey($ml)] = $ml;
        }

        return $map;
    }

    /**
     * Greedy bin-pack: fill largest container first, round remainder up into
     * the smallest container so milk is never lost.
     *
     * @param  array<string, int>  $sizes  size_key => ml (any order)
     * @return array<string, int>          size_key => count
     */
    public function packWithSizes(float $litres, array $sizes): array
    {
        $ordered = $this->orderSizesDesc($sizes);

        $remainingMl = (int) round($litres * 1000);
        if ($remainingMl <= 0 || $ordered === []) {
            return $this->emptyCounts($ordered);
        }

        $counts = $this->emptyCounts($ordered);

        foreach ($ordered as $key => $ml) {
            if ($ml <= 0) {
                continue;
            }
            $count = intdiv($remainingMl, $ml);
            $counts[$key] = $count;
            $remainingMl -= $count * $ml;
        }

        if ($remainingMl > 0) {
            $smallestKey = array_key_last($ordered);
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
     * @param  array<string, int>  $sizes
     * @return list<array{key: string, label: string}>
     */
    public function sizeColumnsFromSizes(array $sizes): array
    {
        $ordered = $this->orderSizesAsc($sizes);

        return array_values(array_map(
            fn (string $key, int $ml) => [
                'key' => $key,
                'label' => $this->sizeLabel($ml),
            ],
            array_keys($ordered),
            array_values($ordered),
        ));
    }

    /**
     * @param  array<string, int>  $counts
     * @param  array<string, int>  $sizes
     */
    public function litresFromCountsWithSizes(array $counts, array $sizes): float
    {
        $ml = 0;
        foreach ($sizes as $key => $sizeMl) {
            $ml += ($counts[$key] ?? 0) * $sizeMl;
        }

        return round($ml / 1000, 2);
    }

    private function sizeKey(int $ml): string
    {
        if ($ml >= 1000 && $ml % 1000 === 0) {
            $litres = $ml / 1000;

            return fmod((float) $litres, 1.0) === 0.0
                ? ((int) $litres).'L'
                : $litres.'L';
        }

        return $ml.'ml';
    }

    private function sizeLabel(int $ml): string
    {
        if ($ml >= 1000 && $ml % 1000 === 0) {
            $litres = $ml / 1000;

            return fmod((float) $litres, 1.0) === 0.0
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
    private function orderSizesDesc(array $sizes): array
    {
        $ordered = $sizes;
        uasort($ordered, fn (int $a, int $b) => $b <=> $a);

        return $ordered;
    }

    /**
     * @param  array<string, int>  $sizes
     * @return array<string, int>
     */
    private function orderSizesAsc(array $sizes): array
    {
        $ordered = $sizes;
        uasort($ordered, fn (int $a, int $b) => $a <=> $b);

        return $ordered;
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
