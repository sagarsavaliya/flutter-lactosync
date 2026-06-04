<?php

namespace App\Services\Operations;

use App\Enums\DeliveryShift;
use App\Enums\OrderLogStatus;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\Farm;
use App\Models\SubscriptionLine;
use App\Services\Billing\MonthlyInvoiceGenerator;
use App\Support\DeliveryLogPresenter;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class DeliveryLogUpdateService
{
    public function __construct(
        private readonly MonthlyInvoiceGenerator $invoiceGenerator,
    ) {}

    /**
     * @param  list<array{date: string, morning?: ?float, evening?: ?float}>  $entries
     */
    public function updateLineLogs(
        Farm $farm,
        Customer $customer,
        SubscriptionLine $line,
        string $billingMonth,
        array $entries,
    ): void {
        $line->loadMissing(['product', 'subscription']);

        DB::transaction(function () use ($farm, $customer, $line, $billingMonth, $entries) {
            foreach ($entries as $entry) {
                $date = Carbon::parse($entry['date'])->startOfDay();
                if ($date->format('Y-m') !== $billingMonth) {
                    continue;
                }

                $this->upsertShiftLog(
                    $farm,
                    $customer,
                    $line,
                    $billingMonth,
                    $date,
                    DeliveryShift::Morning,
                    isset($entry['morning']) ? (float) $entry['morning'] : null,
                );

                $this->upsertShiftLog(
                    $farm,
                    $customer,
                    $line,
                    $billingMonth,
                    $date,
                    DeliveryShift::Evening,
                    isset($entry['evening']) ? (float) $entry['evening'] : null,
                );
            }

            $this->invoiceGenerator->regenerateForCustomer($farm, $customer->id, $billingMonth);
        });
    }

    private function upsertShiftLog(
        Farm $farm,
        Customer $customer,
        SubscriptionLine $line,
        string $billingMonth,
        Carbon $date,
        DeliveryShift $shift,
        ?float $quantity,
    ): void {
        $existing = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('subscription_line_id', $line->id)
            ->whereDate('delivery_date', $date)
            ->where('shift', $shift)
            ->first();

        $qty = $quantity ?? 0.0;
        if ($qty <= 0) {
            if ($existing !== null) {
                $existing->update([
                    'status' => OrderLogStatus::Skipped,
                    'quantity' => 0,
                    'line_total' => 0,
                ]);
            }

            return;
        }

        $unitRate = (float) $line->effective_rate;
        $payload = [
            'farm_id' => $farm->id,
            'customer_id' => $customer->id,
            'subscription_id' => $line->subscription_id,
            'subscription_line_id' => $line->id,
            'product_id' => $line->product_id,
            'product_name' => $line->product?->name ?? '',
            'quantity' => $qty,
            'unit_rate' => $unitRate,
            'line_total' => DailyOrderLog::computeLineTotal($qty, $unitRate),
            'shift' => $shift,
            'status' => OrderLogStatus::Delivered,
            'delivery_date' => $date->toDateString(),
            'billing_month' => $billingMonth,
        ];

        if ($existing !== null) {
            $existing->update($payload);

            return;
        }

        DailyOrderLog::query()->create($payload);
    }

    /**
     * @return list<array{date: string, morning: ?float, evening: ?float, has_delivery: bool, morning_log_id: ?int, evening_log_id: ?int}>
     */
    public function editableGrid(
        Customer $customer,
        SubscriptionLine $line,
        string $billingMonth,
    ): array {
        $logs = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('billing_month', $billingMonth)
            ->whereIn('status', DeliveryLogPresenter::billableStatuses())
            ->orderBy('delivery_date')
            ->get();

        $lineLogs = DeliveryLogPresenter::logsForSubscriptionLine($logs, $line);
        $rows = DeliveryLogPresenter::fullMonthDailyOrdersTable($lineLogs, $billingMonth, Carbon::today());

        $logIds = $lineLogs->groupBy(fn (DailyOrderLog $log) => $log->delivery_date->toDateString());

        return array_map(function (array $row) use ($logIds) {
            $dayLogs = $logIds->get($row['date'], collect());
            $morningLog = $dayLogs->first(fn (DailyOrderLog $log) => ($log->shift->value ?? $log->shift) === 'morning');
            $eveningLog = $dayLogs->first(fn (DailyOrderLog $log) => ($log->shift->value ?? $log->shift) === 'evening');

            return [
                ...$row,
                'morning_log_id' => $morningLog?->id,
                'evening_log_id' => $eveningLog?->id,
            ];
        }, $rows);
    }
}
