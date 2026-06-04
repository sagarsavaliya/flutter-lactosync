<?php

namespace App\Jobs\Operations;

use App\Enums\DeliveryShift;
use App\Models\Farm;
use App\Services\Operations\DailyOrderLogGenerator;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Creates pending delivery line items for active subscriptions (morning or evening run).
 */
class CreateDailyOrderLogJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public string $slot, // morning | evening
        public ?int $farmId = null,
    ) {}

    public function handle(DailyOrderLogGenerator $generator): void
    {
        $shift = DeliveryShift::from($this->slot);
        $date = Carbon::today(config('lactosync.schedule.timezone', 'Asia/Kolkata'));
        $total = 0;

        $farms = $this->farmId === null
            ? Farm::query()->get()
            : Farm::query()->whereKey($this->farmId)->get();

        foreach ($farms as $farm) {
            $total += $generator->generateForFarm($farm, $date, $shift);
        }

        Log::info('CreateDailyOrderLogJob completed', [
            'slot' => $this->slot,
            'date' => $date->toDateString(),
            'created' => $total,
        ]);
    }
}
