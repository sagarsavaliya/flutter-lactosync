<?php

namespace App\Console\Commands;

use App\Models\Customer;
use App\Services\WhatsApp\CustomerWhatsAppNotifier;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Daily scheduler command that clears vacation mode for every customer
 * whose vacation_end date equals today, then sends a "delivery resumes"
 * WhatsApp notification to each affected customer.
 *
 * Run via scheduler: customer:clear-ended-vacations (daily at 07:00)
 */
class ClearEndedVacations extends Command
{
    protected $signature = 'customer:clear-ended-vacations';

    protected $description = 'Clear vacation mode for customers whose vacation ended today and send resume notifications';

    public function handle(): int
    {
        $today = Carbon::today()->toDateString(); // YYYY-MM-DD

        $customers = Customer::query()
            ->whereNotNull('vacation_end')
            ->whereDate('vacation_end', $today)
            ->with('farm')
            ->get();

        foreach ($customers as $customer) {
            // Send WhatsApp notification — fire-and-forget; a failure must not
            // prevent the vacation fields from being cleared for this customer.
            try {
                // subscriptionResumed() guards whatsapp_enabled internally and
                // fires the lacto_sync_sub_resumed (vacation-ended) template.
                app(CustomerWhatsAppNotifier::class)->subscriptionResumed(
                    $customer,
                    Carbon::tomorrow()->toDateString(),
                    $customer->farm,
                );
            } catch (\Throwable $e) {
                Log::warning('customer:clear-ended-vacations WhatsApp failed', [
                    'customer_id' => $customer->id,
                    'error'       => $e->getMessage(),
                ]);
            }

            // Clear vacation fields regardless of notification outcome.
            $customer->update([
                'vacation_start' => null,
                'vacation_end'   => null,
            ]);
        }

        $this->info("Processed {$customers->count()} customer(s) with ended vacations.");

        return self::SUCCESS;
    }
}
