<?php

namespace App\Services\Notifications;

use App\Models\Customer;
use App\Models\FarmOwner;
use App\Models\SubscriptionLine;
use App\Services\WhatsApp\OwnerWhatsAppNotifier;
use Carbon\Carbon;

/**
 * Notifies the farm owner (in-app + WhatsApp) when a customer changes something
 * from the customer app.
 */
class CustomerAppOwnerAlertService
{
    public function __construct(
        private readonly OwnerNotificationService $inApp,
        private readonly OwnerWhatsAppNotifier $whatsApp,
    ) {}

    public function vacationSet(Customer $customer, string $vacationStart, string $vacationEnd): void
    {
        $owner = $this->resolveOwner($customer);
        if ($owner === null) {
            return;
        }

        $customer->loadMissing('farm');
        $resumeLabel = Carbon::parse($vacationEnd)->addDay()->format('d M Y');

        $this->inApp->customerVacationSet($owner, $customer, $vacationStart, $vacationEnd, $resumeLabel);
        $this->whatsApp->vacationSet($owner, $customer, $vacationStart, $vacationEnd, $customer->farm);
    }

    public function vacationCleared(Customer $customer): void
    {
        $owner = $this->resolveOwner($customer);
        if ($owner === null) {
            return;
        }

        $customer->loadMissing('farm');
        $this->inApp->customerVacationCleared($owner, $customer);
        $this->whatsApp->vacationCleared($owner, $customer, $customer->farm);
    }

    public function qtyChanged(
        Customer $customer,
        string $deliveryDate,
        SubscriptionLine $line,
        int $qty,
    ): void {
        $owner = $this->resolveOwner($customer);
        if ($owner === null) {
            return;
        }

        $customer->loadMissing('farm');
        $line->loadMissing('product');

        $this->inApp->customerQtyChanged($owner, $customer, $deliveryDate, $line, $qty);
        $this->whatsApp->qtyChanged($owner, $customer, $deliveryDate, $line, $qty, $customer->farm);
    }

    public function daySkipped(Customer $customer, string $deliveryDate): void
    {
        $owner = $this->resolveOwner($customer);
        if ($owner === null) {
            return;
        }

        $customer->loadMissing('farm');
        $this->inApp->customerDaySkipped($owner, $customer, $deliveryDate);
        $this->whatsApp->daySkipped($owner, $customer, $deliveryDate, $customer->farm);
    }

    public function addressUpdated(Customer $customer, string $addressSummary): void
    {
        $owner = $this->resolveOwner($customer);
        if ($owner === null) {
            return;
        }

        $customer->loadMissing('farm');
        $this->inApp->customerAddressUpdated($owner, $customer, $addressSummary);
        $this->whatsApp->addressUpdated($owner, $customer, $addressSummary, $customer->farm);
    }

    private function resolveOwner(Customer $customer): ?FarmOwner
    {
        return FarmOwner::query()
            ->where('farm_id', $customer->farm_id)
            ->first();
    }
}
