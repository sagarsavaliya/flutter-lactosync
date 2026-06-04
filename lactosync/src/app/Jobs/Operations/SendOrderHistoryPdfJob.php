<?php

namespace App\Jobs\Operations;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

/**
 * Builds order-history PDF and sends it to the customer via WhatsApp.
 */
class SendOrderHistoryPdfJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public int $customerId,
        public string $period,
    ) {}

    public function handle(): void
    {
        Log::info('SendOrderHistoryPdfJob dispatched', [
            'customer_id' => $this->customerId,
            'period' => $this->period,
        ]);
        // TODO: render PDF (dompdf/snappy), upload storage, WhatsApp document template.
    }
}
