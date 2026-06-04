<?php

namespace App\Console\Commands;

use App\Enums\DeliveryShift;
use App\Models\Farm;
use App\Services\Operations\DailyOrderLogGenerator;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class GenerateDailyOrdersCommand extends Command
{
    protected $signature = 'orders:generate-today
                            {--date= : YYYY-MM-DD (defaults to today)}
                            {--shift=all : morning, evening, or all}';

    protected $description = 'Generate pending daily order logs from active subscriptions (manual / testing).';

    public function handle(DailyOrderLogGenerator $generator): int
    {
        $date = Carbon::parse(
            $this->option('date') ?? Carbon::today(config('lactosync.schedule.timezone', 'Asia/Kolkata')),
        )->startOfDay();

        $shiftOption = (string) $this->option('shift');
        $shifts = match ($shiftOption) {
            'morning' => [DeliveryShift::Morning],
            'evening' => [DeliveryShift::Evening],
            default => [DeliveryShift::Morning, DeliveryShift::Evening],
        };

        $total = 0;

        foreach (Farm::query()->get() as $farm) {
            foreach ($shifts as $shift) {
                $count = $generator->generateForFarm($farm, $date, $shift);
                $total += $count;
                $this->line("Farm #{$farm->id} · {$shift->value} · {$date->toDateString()}: {$count} logs");
            }
        }

        $this->info("Created {$total} pending order log(s).");

        return self::SUCCESS;
    }
}
