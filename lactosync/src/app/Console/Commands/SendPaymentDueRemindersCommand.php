<?php

namespace App\Console\Commands;

use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Models\OwnerNotification;
use App\Services\Notifications\OwnerNotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class SendPaymentDueRemindersCommand extends Command
{
    protected $signature = 'billing:payment-due-reminders';

    protected $description = 'Notify farm owners about unpaid bills 10 days after bill date';

    public function handle(OwnerNotificationService $notifications): int
    {
        $cutoff = now()->startOfDay()->subDays(10);

        $invoices = Invoice::query()
            ->where('balance_due', '>', 0)
            ->whereDate('issued_at', '<=', $cutoff)
            ->with(['customer', 'farm.owner'])
            ->get();

        $sent = 0;

        foreach ($invoices as $invoice) {
            $owner = $invoice->farm?->owner;
            if (! $owner instanceof FarmOwner) {
                continue;
            }

            $alreadySent = OwnerNotification::query()
                ->where('farm_owner_id', $owner->id)
                ->where('type', 'payment_due_reminder')
                ->where('meta->invoice_id', $invoice->id)
                ->exists();

            if ($alreadySent) {
                continue;
            }

            $notifications->paymentDueReminder($owner, $invoice);
            $sent++;
        }

        $this->info("Payment due reminders sent: {$sent}");

        return self::SUCCESS;
    }
}
