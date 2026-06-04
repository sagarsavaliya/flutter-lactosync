<?php

namespace App\Jobs\Operations;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

/**
 * Resumes subscriptions when vacation end date is reached.
 */
class ExpireVacationSubscriptionsJob implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        Log::info('ExpireVacationSubscriptionsJob dispatched');
        // TODO: set status active where vacation_end = yesterday (farm timezone).
    }
}
