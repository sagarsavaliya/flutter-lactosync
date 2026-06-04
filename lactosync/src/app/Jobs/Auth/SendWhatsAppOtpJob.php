<?php

namespace App\Jobs\Auth;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

/**
 * Sends OTP via WhatsApp Cloud API (lacto_sync_otp template).
 */
class SendWhatsAppOtpJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public string $mobileE164,
        public string $otp,
    ) {}

    public function handle(): void
    {
        Log::info('SendWhatsAppOtpJob dispatched', ['mobile' => $this->mobileE164]);
        // TODO: call Meta Graph API; never log OTP value in production.
    }
}
