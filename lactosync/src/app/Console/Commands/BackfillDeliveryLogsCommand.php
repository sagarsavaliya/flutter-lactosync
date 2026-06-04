<?php

namespace App\Console\Commands;

use App\Enums\DeliveryShift;
use App\Enums\OrderLogStatus;
use App\Models\DailyOrderLog;
use App\Models\Farm;
use App\Services\Operations\DailyOrderLogGenerator;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class BackfillDeliveryLogsCommand extends Command
{
    protected $signature = 'operations:backfill-delivery-logs
                            {--farm= : Farm ID (defaults to all farms)}
                            {--month= : Billing month YYYY-MM (defaults to current month)}
                            {--mark-delivered : Mark backfilled rows as delivered}';

    protected $description = 'Create missing daily delivery log rows from active subscriptions for a billing month';

    public function handle(DailyOrderLogGenerator $generator): int
    {
        $month = (string) ($this->option('month') ?: now(config('lactosync.schedule.timezone', 'Asia/Kolkata'))->format('Y-m'));
        $timezone = config('lactosync.schedule.timezone', 'Asia/Kolkata');

        $start = Carbon::createFromFormat('Y-m', $month, $timezone)->startOfMonth();
        $end = $start->copy()->endOfMonth();
        $today = Carbon::today($timezone);
        if ($end->gt($today)) {
            $end = $today;
        }

        $farmId = $this->option('farm');
        $farms = $farmId
            ? Farm::query()->whereKey($farmId)->get()
            : Farm::query()->get();

        if ($farms->isEmpty()) {
            $this->warn('No farms found.');

            return self::FAILURE;
        }

        $totalCreated = 0;

        foreach ($farms as $farm) {
            $created = 0;
            for ($date = $start->copy(); $date->lte($end); $date->addDay()) {
                foreach ([DeliveryShift::Morning, DeliveryShift::Evening] as $shift) {
                    $created += $generator->generateForFarm($farm, $date->copy(), $shift);
                }
            }

            if ($this->option('mark-delivered') && $created >= 0) {
                $marked = DailyOrderLog::query()
                    ->where('farm_id', $farm->id)
                    ->where('billing_month', $month)
                    ->where('status', OrderLogStatus::Pending)
                    ->update(['status' => OrderLogStatus::Delivered]);
                $this->info("Farm #{$farm->id} ({$farm->name}): created {$created}, marked {$marked} delivered.");
            } else {
                $this->info("Farm #{$farm->id} ({$farm->name}): created {$created} delivery rows.");
            }

            $totalCreated += $created;
        }

        $this->comment("Backfill complete for {$month}. Total new rows: {$totalCreated}.");

        return self::SUCCESS;
    }
}
