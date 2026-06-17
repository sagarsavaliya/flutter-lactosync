<?php

namespace App\Console\Commands;

use App\Enums\DeliveryShift;
use App\Models\Customer;
use App\Services\Operations\DailyOrderLogGenerator;
use App\Services\WhatsApp\CustomerWhatsAppNotifier;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Daily scheduler command that clears vacation mode for every customer
 * whose vacation_end date is <= today, then generates today's orders and
 * sends a "delivery resumes" WhatsApp notification to each affected customer.
 *
 * Run via scheduler: customer:clear-ended-vacations (daily at 04:30 IST,
 * before morning order dispatch at farm's morning_order_time).
 */
class ClearEndedVacations extends Command
{
    protected $signature = 'customer:clear-ended-vacations';

    protected $description = 'Clear vacation mode for customers whose vacation ended today and send resume notifications';

    public function handle(DailyOrderLogGenerator $generator): int
    {
        $timezone = config('lactosync.schedule.timezone', 'Asia/Kolkata');
        $today    = Carbon::today($timezone);

        // Use <= so any missed days (e.g. scheduler downtime) are caught up.
        $customers = Customer::query()
            ->whereNotNull('vacation_end')
            ->whereDate('vacation_end', '<=', $today->toDateString())
            ->with('farm')
            ->get();

        foreach ($customers as $customer) {
            $resumeFrom = $customer->vacation_end->copy()->addDay()->toDateString();

            // Clear vacation first so generateForFarm treats this customer as active.
            $customer->update([
                'vacation_start' => null,
                'vacation_end'   => null,
            ]);

            // Regenerate today's orders immediately (idempotent — won't duplicate
            // existing logs). Handles the case where morning dispatch already ran
            // before vacation was cleared.
            if ($customer->farm !== null) {
                foreach ([DeliveryShift::Morning, DeliveryShift::Evening] as $shift) {
                    try {
                        $generator->generateForFarm($customer->farm, $today, $shift);
                    } catch (\Throwable $e) {
                        Log::warning('customer:clear-ended-vacations order-gen failed', [
                            'customer_id' => $customer->id,
                            'shift'       => $shift->value,
                            'error'       => $e->getMessage(),
                        ]);
                    }
                }
            }

            // Notify — fire-and-forget; failure must not block vacation clear.
            try {
                app(CustomerWhatsAppNotifier::class)->subscriptionResumed(
                    $customer,
                    $resumeFrom,
                    $customer->farm,
                );
            } catch (\Throwable $e) {
                Log::warning('customer:clear-ended-vacations WhatsApp failed', [
                    'customer_id' => $customer->id,
                    'error'       => $e->getMessage(),
                ]);
            }
        }

        $this->info("Processed {$customers->count()} customer(s) with ended vacations.");

        return self::SUCCESS;
    }
}
