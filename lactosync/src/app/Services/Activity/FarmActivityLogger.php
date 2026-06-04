<?php

namespace App\Services\Activity;

use App\Models\Customer;
use App\Models\FarmActivityLog;
use App\Models\FarmOwner;
use App\Models\Subscription;
use Illuminate\Support\Carbon;

class FarmActivityLogger
{
    public function logDeleted(FarmOwner $owner, string $entityType, int $entityId, string $label, array $meta = []): void
    {
        $this->write($owner, 'deleted', $entityType, $entityId, $label, $meta);
    }

    public function logRestored(FarmOwner $owner, string $entityType, int $entityId, string $label): void
    {
        $this->write($owner, 'restored', $entityType, $entityId, $label);
    }

    private function write(
        FarmOwner $owner,
        string $action,
        string $entityType,
        int $entityId,
        string $label,
        array $meta = [],
    ): void {
        FarmActivityLog::query()->create([
            'farm_id' => $owner->farm_id,
            'farm_owner_id' => $owner->id,
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'entity_label' => $label,
            'meta' => $meta === [] ? null : $meta,
            'created_at' => Carbon::now(),
        ]);
    }

    public function restore(FarmOwner $owner, FarmActivityLog $log): void
    {
        if ($log->farm_id !== $owner->farm_id || $log->action !== 'deleted') {
            throw new \RuntimeException('This item cannot be restored.');
        }

        match ($log->entity_type) {
            'customer' => $this->restoreCustomer($log),
            'subscription' => $this->restoreSubscription($log),
            default => throw new \RuntimeException('Restore is not supported for this item type.'),
        };

        $this->logRestored($owner, $log->entity_type, $log->entity_id, $log->entity_label);
    }

    private function restoreCustomer(FarmActivityLog $log): void
    {
        $customer = Customer::withTrashed()->whereKey($log->entity_id)->first();
        if ($customer === null) {
            throw new \RuntimeException('Customer record not found.');
        }

        $customer->restore();
    }

    private function restoreSubscription(FarmActivityLog $log): void
    {
        $subscription = Subscription::withTrashed()->whereKey($log->entity_id)->first();
        if ($subscription === null) {
            throw new \RuntimeException('Subscription record not found.');
        }

        $subscription->restore();
    }
}
