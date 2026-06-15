<?php

namespace App\Services\Billing;

use App\Models\DailyOrderLog;
use Illuminate\Support\Collection;

/**
 * Rolls up daily order logs (pending + delivered) into consumption rows.
 *
 * Groups by subscription line (preferred) or product + rate so renamed
 * product labels on historical logs do not split one subscription into
 * multiple consumption lines.
 */
class ConsumptionAggregator
{
    /**
     * @param  Collection<int, DailyOrderLog>  $deliveredLogs
     * @return Collection<int, array{product_name: string, unit_rate: float, total_quantity: float, line_total: float}>
     */
    public function aggregate(Collection $deliveredLogs): Collection
    {
        if ($deliveredLogs->isNotEmpty()) {
            $deliveredLogs->loadMissing(['product', 'subscriptionLine.product']);
        }

        return $deliveredLogs
            ->groupBy(fn (DailyOrderLog $log) => $this->groupKey($log))
            ->map(function (Collection $group) {
                /** @var DailyOrderLog $first */
                $first = $group->first();

                return [
                    'product_name' => $this->displayName($group, $first),
                    'unit_rate' => (float) $first->unit_rate,
                    'total_quantity' => round((float) $group->sum('quantity'), 2),
                    'line_total' => round((float) $group->sum('line_total'), 2),
                ];
            })
            ->values();
    }

    private function groupKey(DailyOrderLog $log): string
    {
        if ($log->subscription_line_id) {
            return 'line:'.$log->subscription_line_id;
        }

        if ($log->product_id) {
            return 'product:'.$log->product_id.'|'.number_format((float) $log->unit_rate, 2, '.', '');
        }

        return 'legacy:'.mb_strtolower(trim((string) $log->product_name)).'|'
            .number_format((float) $log->unit_rate, 2, '.', '');
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $group
     */
    private function displayName(Collection $group, DailyOrderLog $first): string
    {
        $lineProduct = $first->subscriptionLine?->product?->name;
        if ($lineProduct !== null && $lineProduct !== '') {
            return $lineProduct;
        }

        $catalogProduct = $first->product?->name;
        if ($catalogProduct !== null && $catalogProduct !== '') {
            return $catalogProduct;
        }

        /** @var string $mostCommon */
        $mostCommon = $group
            ->groupBy(fn (DailyOrderLog $log) => trim((string) $log->product_name))
            ->sortByDesc(fn (Collection $names) => $names->count())
            ->keys()
            ->first() ?? '';

        return $mostCommon;
    }
}
