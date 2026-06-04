<?php

namespace App\Services\Operations;

use App\Enums\DeliveryShift;
use App\Enums\OrderLogStatus;
use App\Models\DailyOrderLog;
use App\Models\Farm;
use App\Models\Subscription;
use Illuminate\Support\Carbon;

class DailyOrderLogGenerator
{
    public function generateForFarm(Farm $farm, Carbon $date, DeliveryShift $shift): int
    {
        $created = 0;

        $subscriptions = Subscription::query()
            ->where('farm_id', $farm->id)
            ->where('status', 'active')
            ->with(['customer', 'lines.product'])
            ->get();

        foreach ($subscriptions as $subscription) {
            $customer = $subscription->customer;
            if ($customer === null || ! $customer->is_active || $customer->isOnVacation()) {
                continue;
            }

            foreach ($subscription->lines as $line) {
                $lineShift = $line->shift instanceof DeliveryShift
                    ? $line->shift
                    : DeliveryShift::from((string) $line->shift);

                if ($lineShift !== $shift) {
                    continue;
                }

                $product = $line->product;
                if ($product === null) {
                    continue;
                }

                $exists = DailyOrderLog::query()
                    ->withTrashed()
                    ->where('farm_id', $farm->id)
                    ->where('customer_id', $customer->id)
                    ->where('subscription_id', $subscription->id)
                    ->where('product_id', $product->id)
                    ->where('shift', $shift)
                    ->whereDate('delivery_date', $date)
                    ->exists();

                if ($exists) {
                    continue;
                }

                $qty = (float) $line->quantity;

                DailyOrderLog::query()->create([
                    'farm_id' => $farm->id,
                    'customer_id' => $customer->id,
                    'subscription_id' => $subscription->id,
                    'subscription_line_id' => $line->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'quantity' => $qty,
                    'unit_rate' => $line->effective_rate,
                    'line_total' => DailyOrderLog::computeLineTotal($qty, (float) $line->effective_rate),
                    'shift' => $shift,
                    // Assumed delivered per subscription; owner only edits exceptions (skip/qty change).
                    'status' => OrderLogStatus::Delivered,
                    'delivery_date' => $date->toDateString(),
                    'billing_month' => DailyOrderLog::billingMonthFor($date),
                ]);

                $created++;
            }
        }

        return $created;
    }
}
