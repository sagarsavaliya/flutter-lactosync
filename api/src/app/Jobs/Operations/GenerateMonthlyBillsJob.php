<?php

namespace App\Jobs\Operations;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

/**
 * Generates monthly bills for all active customers (1st of month).
 */
class GenerateMonthlyBillsJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public string $billingPeriod, // YYYY-MM
    ) {}

    public function handle(): void
    {
        Log::info('GenerateMonthlyBillsJob dispatched', ['period' => $this->billingPeriod]);
        // TODO: create bill rows; dispatch PDF + WhatsApp per customer.
    }
}
