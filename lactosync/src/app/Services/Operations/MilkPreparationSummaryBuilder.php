<?php

namespace App\Services\Operations;

use App\Enums\ContainerType;
use App\Enums\DeliveryShift;
use App\Enums\MilkType;
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
     * @param  Collection<int, Product>  $products
     */
    public function build(Collection $orders, Collection $products, string $date): array
    {
        $activeOrders = $orders->filter(
            fn (DailyOrderLog $log) => ! in_array($log->status, [OrderLogStatus::Skipped, OrderLogStatus::Cancelled], true)
        );

        return [
            'date' => $date,
            'morning' => $this->shiftSummary($activeOrders, $products, DeliveryShift::Morning),
            'evening' => $this->shiftSummary($activeOrders, $products, DeliveryShift::Evening),
        ];
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $orders
     * @param  Collection<int, Product>  $products
     */
    private function shiftSummary(Collection $orders, Collection $products, DeliveryShift $shift): array
    {
        $shiftOrders = $orders->where('shift', $shift);
        $glass = $this->containerSummary($shiftOrders, $products, ContainerType::GlassBottle);
        $plastic = $this->containerSummary($shiftOrders, $products, ContainerType::PlasticBag);

        return [
            'shift' => $shift->value,
            'shift_label' => $shift->label(),
            'total_litres' => round((float) $glass['total_litres'] + (float) $plastic['total_litres'], 2),
            'glass_bottle' => $glass,
            'plastic_bag' => $plastic,
        ];
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $orders
     * @param  Collection<int, Product>  $products
     */
    private function containerSummary(
        Collection $orders,
        Collection $products,
        ContainerType $containerType,
    ): array {
        $sizeColumns = $this->calculator->sizeColumns($containerType);
        $sizeKeys = array_column($sizeColumns, 'key');

        $productsForContainer = $products
            ->where('container_type', $containerType)
            ->where('is_active', true)
            ->sort(function (Product $left, Product $right): int {
                $byMilk = $this->milkTypeSortKey($left->milk_type) <=> $this->milkTypeSortKey($right->milk_type);
                if ($byMilk !== 0) {
                    return $byMilk;
                }

                $byRate = (float) $left->rate <=> (float) $right->rate;
                if ($byRate !== 0) {
                    return $byRate;
                }

                return strcmp($left->name, $right->name);
            })
            ->values();

        $productRows = [];
        $totals = array_fill_keys($sizeKeys, 0);

        foreach ($productsForContainer as $product) {
            $counts = array_fill_keys($sizeKeys, 0);
            $productOrders = $orders->where('product_id', $product->id);

            foreach ($productOrders as $order) {
                $packed = $this->calculator->pack((float) $order->quantity, $containerType);
                foreach ($packed as $key => $count) {
                    if (! array_key_exists($key, $counts)) {
                        continue;
                    }
                    $counts[$key] += $count;
                    $totals[$key] += $count;
                }
            }

            $totalLitres = $this->calculator->litresFromCounts($counts, $containerType);

            $productRows[] = [
                'product_id' => $product->id,
                'product_name' => $product->name,
                'milk_type' => $product->milk_type->value,
                'milk_type_label' => $product->milk_type->label(),
                'container_type' => $product->container_type->value,
                'rate' => (float) $product->rate,
                'display_label' => $this->displayLabel($product),
                'counts' => $counts,
                'total_litres' => $totalLitres,
            ];
        }

        return [
            'container_type' => $containerType->value,
            'container_label' => $this->calculator->containerLabel($containerType),
            'total_litres' => $this->calculator->litresFromCounts($totals, $containerType),
            'sizes' => $sizeColumns,
            'products' => $productRows,
            'totals' => $totals,
        ];
    }

    private function displayLabel(Product $product): string
    {
        $rate = (float) $product->rate;
        $rateLabel = fmod($rate, 1.0) === 0.0 ? (string) (int) $rate : number_format($rate, 0);

        return $product->milk_type->label().' Milk - '.$rateLabel.'/-';
    }

    private function milkTypeSortKey(MilkType $milkType): int
    {
        return match ($milkType) {
            MilkType::Buffalo => 0,
            MilkType::Cow => 1,
            MilkType::GirCow => 2,
        };
    }
}
