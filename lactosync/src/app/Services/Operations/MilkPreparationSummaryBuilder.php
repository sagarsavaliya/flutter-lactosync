<?php

namespace App\Services\Operations;

use App\Enums\DeliveryShift;
use App\Enums\OrderLogStatus;
use App\Models\DailyOrderLog;
use App\Models\Product;
use Illuminate\Support\Collection;

class MilkPreparationSummaryBuilder
{
    public function __construct(
        private readonly MilkPreparationCalculator $calculator,
    ) {}

    /**
     * @param  Collection<int, DailyOrderLog>  $orders
     * @param  Collection<int, Product>  $products  must be loaded with containerType.sizes
     */
    public function build(Collection $orders, Collection $products, string $date, int $farmId): array
    {
        $activeOrders = $orders->filter(
            fn (DailyOrderLog $log) => ! in_array($log->status, [OrderLogStatus::Skipped, OrderLogStatus::Cancelled], true)
        );

        return [
            'date' => $date,
            'morning' => $this->shiftCards($activeOrders, $products, DeliveryShift::Morning),
            'evening' => $this->shiftCards($activeOrders, $products, DeliveryShift::Evening),
        ];
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $orders
     * @param  Collection<int, Product>  $products
     * @return list<array<string, mixed>>
     */
    private function shiftCards(Collection $orders, Collection $products, DeliveryShift $shift): array
    {
        $shiftOrders = $orders->where('shift', $shift);

        // Group products by container_type_id; skip products without container type
        $byType = $products
            ->filter(fn (Product $p) => $p->relationLoaded('containerType') && $p->containerType !== null)
            ->groupBy(fn (Product $p) => $p->containerType->id);

        $cards = [];

        foreach ($byType as $containerTypeId => $typeProducts) {
            /** @var \App\Models\ContainerType $containerType */
            $containerType = $typeProducts->first()->containerType;

            // Get sizes from the loaded relationship, sorted descending for bin-pack
            $sizeLiters = $containerType->sizes
                ->pluck('size_liters')
                ->map(fn ($v) => (float) $v)
                ->sort()
                ->values()
                ->all();

            if (empty($sizeLiters)) {
                continue;
            }

            $sizesMap = $this->calculator->sizesMapFromLiters($sizeLiters);
            $sizeColumns = $this->calculator->sizeColumnsFromSizes($sizesMap);

            $productRows = [];
            $totalCounts = array_fill_keys(array_keys($sizesMap), 0);

            foreach ($typeProducts->sortBy('name') as $product) {
                $productOrders = $shiftOrders->where('product_id', $product->id);
                $counts = array_fill_keys(array_keys($sizesMap), 0);

                foreach ($productOrders as $order) {
                    $packed = $this->calculator->packWithSizes((float) $order->quantity, $sizesMap);
                    foreach ($packed as $key => $count) {
                        $counts[$key] = ($counts[$key] ?? 0) + $count;
                        $totalCounts[$key] = ($totalCounts[$key] ?? 0) + $count;
                    }
                }

                $productRows[] = [
                    'product_id' => $product->id,
                    'product_name' => $product->name ?? '',
                    'total_liters' => $this->calculator->litresFromCountsWithSizes($counts, $sizesMap),
                    'counts' => $counts,
                ];
            }

            $cards[] = [
                'container_type_id' => (int) $containerTypeId,
                'container_type_name' => $containerType->name,
                'total_liters' => $this->calculator->litresFromCountsWithSizes($totalCounts, $sizesMap),
                'sizes' => $sizeColumns,
                'products' => $productRows,
                'totals' => $totalCounts,
            ];
        }

        // Stable alphabetical sort so card order is consistent
        usort($cards, fn (array $a, array $b) => strcmp($a['container_type_name'], $b['container_type_name']));

        return $cards;
    }
}
