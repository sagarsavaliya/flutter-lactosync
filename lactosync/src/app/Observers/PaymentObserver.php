<?php

namespace App\Observers;

use App\Models\FarmOwner;
use App\Models\Payment;
use App\Services\Notifications\OwnerNotificationService;

class PaymentObserver
{
    public function __construct(
        private readonly OwnerNotificationService $notifications,
    ) {}

    public function created(Payment $payment): void
    {
        $payment->loadMissing('farm.owner');
        $owner = $payment->farm?->owner;

        if ($owner instanceof FarmOwner) {
            $this->notifications->paymentReceived($owner, $payment);
        }
    }
}
