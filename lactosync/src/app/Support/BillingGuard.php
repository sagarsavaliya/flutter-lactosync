<?php

namespace App\Support;

use App\Models\Invoice;

final class BillingGuard
{
    public static function customerHasUnpaidInvoices(int $customerId): bool
    {
        return Invoice::query()
            ->where('customer_id', $customerId)
            ->where('balance_due', '>', 0)
            ->exists();
    }
}
