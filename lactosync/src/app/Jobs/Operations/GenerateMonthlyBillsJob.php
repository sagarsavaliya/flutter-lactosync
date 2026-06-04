<?php

namespace App\Jobs\Operations;

use App\Models\Farm;
use App\Services\Billing\MonthlyInvoiceGenerator;
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

    public function handle(MonthlyInvoiceGenerator $generator): void
    {
        $farms = Farm::query()->with('owner')->get();

        foreach ($farms as $farm) {
            $generator->generateForFarm($farm, $this->billingPeriod);
        }

        Log::info('GenerateMonthlyBillsJob completed', [
            'period' => $this->billingPeriod,
            'farms' => $farms->count(),
        ]);
    }
}
