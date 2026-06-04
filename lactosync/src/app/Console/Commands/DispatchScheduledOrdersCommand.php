<?php

namespace App\Console\Commands;

use App\Enums\DeliveryShift;
use App\Jobs\Operations\CreateDailyOrderLogJob;
use App\Models\Farm;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;

class DispatchScheduledOrdersCommand extends Command
{
    protected $signature = 'orders:dispatch-scheduled';

    protected $description = 'Dispatch morning/evening order jobs when each farm schedule time matches';

    public function handle(): int
    {
        $timezone = config('lactosync.schedule.timezone', 'Asia/Kolkata');
        $now = Carbon::now($timezone);
        $current = $now->format('H:i');

        foreach (Farm::query()->cursor() as $farm) {
            if ($this->normalizeTime($farm->morning_order_time ?? '05:00') === $current) {
                $this->dispatchOnce($farm->id, 'morning', $now);
            }

            if ($this->normalizeTime($farm->evening_order_time ?? '15:00') === $current) {
                $this->dispatchOnce($farm->id, 'evening', $now);
            }
        }

        return self::SUCCESS;
    }

    private function dispatchOnce(int $farmId, string $slot, Carbon $now): void
    {
        $key = "lactosync:orders:{$farmId}:{$slot}:{$now->toDateString()}:{$now->format('H:i')}";

        if (! Cache::add($key, true, now()->addMinutes(2))) {
            return;
        }

        dispatch(new CreateDailyOrderLogJob($slot, $farmId));
    }

    private function normalizeTime(?string $time): string
    {
        if ($time === null || $time === '') {
            return '00:00';
        }

        [$hour, $minute] = array_pad(explode(':', $time), 2, '00');

        return sprintf('%02d:%02d', (int) $hour, (int) $minute);
    }
}
