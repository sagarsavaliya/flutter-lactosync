<?php

namespace App\Console\Commands;

use App\Enums\OnboardingStep;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\Farm;
use App\Models\Invoice;
use App\Models\InvoiceLine;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Subscription;
use App\Models\SubscriptionLine;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ClearFarmDemoDataCommand extends Command
{
    protected $signature = 'farm:clear-demo-data
                            {--farm= : Farm ID to reset (defaults to all farms)}
                            {--keep-products : Keep product catalog}
                            {--force : Skip confirmation}';

    protected $description = 'Remove demo customers, subscriptions, orders, bills and payments. Keeps farm owner login.';

    public function handle(): int
    {
        $farmId = $this->option('farm');
        $farms = $farmId
            ? Farm::query()->whereKey($farmId)->get()
            : Farm::query()->get();

        if ($farms->isEmpty()) {
            $this->warn('No farms found.');

            return self::FAILURE;
        }

        if (! $this->option('force') && ! $this->confirm(
            'This deletes all customers, subscriptions, delivery logs, invoices and payments. Continue?',
        )) {
            $this->info('Cancelled.');

            return self::SUCCESS;
        }

        $keepProducts = (bool) $this->option('keep-products');

        foreach ($farms as $farm) {
            DB::transaction(function () use ($farm, $keepProducts): void {
                $this->purgeFarmData($farm->id, $keepProducts);

                if ($farm->owner) {
                    $farm->owner->update([
                        'onboarding_step' => $keepProducts
                            ? OnboardingStep::FirstCustomer
                            : OnboardingStep::ProductsSetup,
                    ]);
                }
            });

            $this->info("Farm #{$farm->id}: demo data cleared.".($keepProducts ? ' Products kept.' : ''));
        }

        $this->newLine();
        $this->comment('Next: update farm name in Settings, add products/customers/subscriptions in the app.');

        return self::SUCCESS;
    }

    private function purgeFarmData(int $farmId, bool $keepProducts): void
    {
        if (Schema::hasTable('owner_notifications')) {
            $ownerId = DB::table('farm_owners')->where('farm_id', $farmId)->value('id');
            if ($ownerId) {
                DB::table('owner_notifications')->where('farm_owner_id', $ownerId)->delete();
                DB::table('owner_device_tokens')->where('farm_owner_id', $ownerId)->delete();
            }
        }

        Payment::query()->where('farm_id', $farmId)->delete();

        $invoiceIds = Invoice::query()->where('farm_id', $farmId)->pluck('id');
        InvoiceLine::query()->whereIn('invoice_id', $invoiceIds)->delete();
        Invoice::query()->where('farm_id', $farmId)->delete();

        DailyOrderLog::query()->where('farm_id', $farmId)->forceDelete();

        $subscriptionIds = Subscription::query()->where('farm_id', $farmId)->pluck('id');
        SubscriptionLine::query()->whereIn('subscription_id', $subscriptionIds)->delete();
        Subscription::query()->where('farm_id', $farmId)->forceDelete();

        Customer::query()->where('farm_id', $farmId)->forceDelete();

        if (! $keepProducts) {
            Product::query()->where('farm_id', $farmId)->delete();
        }
    }
}
