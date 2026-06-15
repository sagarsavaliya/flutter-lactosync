<?php

namespace App\Console\Commands;

use App\Enums\OrderLogStatus;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\Farm;
use App\Services\Billing\ConsumptionAggregator;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class AuditConsumptionRowsCommand extends Command
{
    protected $signature = 'lactosync:audit-consumption
                            {--farm= : Farm ID (defaults to all farms)}
                            {--month= : Billing month YYYY-MM (defaults to current)}';

    protected $description = 'List customers whose consumption rows were split by legacy product-name grouping';

    public function handle(ConsumptionAggregator $aggregator): int
    {
        $month = (string) ($this->option('month') ?: Carbon::now()->format('Y-m'));
        $farmId = $this->option('farm');

        $farms = $farmId
            ? Farm::query()->whereKey($farmId)->get()
            : Farm::query()->get();

        if ($farms->isEmpty()) {
            $this->error('No farms found.');

            return self::FAILURE;
        }

        $issues = [];

        foreach ($farms as $farm) {
            $customers = Customer::query()
                ->where('farm_id', $farm->id)
                ->orderBy('first_name')
                ->get();

            foreach ($customers as $customer) {
                $logs = DailyOrderLog::query()
                    ->where('customer_id', $customer->id)
                    ->where('billing_month', $month)
                    ->where('status', OrderLogStatus::Delivered)
                    ->get();

                if ($logs->isEmpty()) {
                    continue;
                }

                $legacyCount = $logs
                    ->groupBy(fn (DailyOrderLog $log) => $log->product_name.'|'.$log->unit_rate)
                    ->count();

                $fixedCount = $aggregator->aggregate($logs)->count();

                if ($legacyCount > $fixedCount) {
                    $issues[] = [
                        'farm' => $farm->name,
                        'customer' => $customer->fullName(),
                        'mobile' => $customer->contact,
                        'legacy_rows' => $legacyCount,
                        'correct_rows' => $fixedCount,
                    ];
                }
            }
        }

        if ($issues === []) {
            $this->info("No split-consumption issues for {$month}.");

            return self::SUCCESS;
        }

        $this->table(
            ['Farm', 'Customer', 'Mobile', 'Legacy rows', 'Correct rows'],
            array_map(
                fn (array $row) => [
                    $row['farm'],
                    $row['customer'],
                    $row['mobile'],
                    $row['legacy_rows'],
                    $row['correct_rows'],
                ],
                $issues,
            ),
        );

        $this->warn(count($issues).' customer(s) had duplicate consumption lines for '.$month.'.');

        return self::SUCCESS;
    }
}
