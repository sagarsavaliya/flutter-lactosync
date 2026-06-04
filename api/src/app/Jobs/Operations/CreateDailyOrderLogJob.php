<?php

namespace App\Jobs\Operations;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

/**
 * Creates delivery line items in the daily order log (morning or evening run).
 */
class CreateDailyOrderLogJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public string $slot, // morning | evening
    ) {}

    public function handle(): void
    {
        Log::info('CreateDailyOrderLogJob dispatched', ['slot' => $this->slot]);
        // TODO: idempotent per farm + date + slot; skip vacation subscriptions.
    }
}
