<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\Farm;
use App\Models\Product;
use App\Models\Subscription;
use App\Models\SubscriptionLine;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class DemoCustomersSeeder extends Seeder
{
    public function run(): void
    {
        $farms = Farm::query()->with(['products', 'customers'])->get();

        if ($farms->isEmpty()) {
            $this->command?->warn('No farms found — register an owner first, then re-run the seeder.');

            return;
        }

        foreach ($farms as $farm) {
            $this->seedFarm($farm);
            $this->backfillSubscriptions($farm);
            $this->diversifySubscriptionProducts($farm);
        }
    }

    /** @return Collection<int, Product> */
    private function activeProducts(Farm $farm): Collection
    {
        return $farm->products()
            ->where('is_active', true)
            ->orderBy('container_type')
            ->orderBy('milk_type')
            ->orderBy('rate')
            ->get();
    }

    private function diversifySubscriptionProducts(Farm $farm): void
    {
        $products = $this->activeProducts($farm);

        if ($products->count() < 2) {
            return;
        }

        $updated = 0;

        $subscriptions = Subscription::query()
            ->where('farm_id', $farm->id)
            ->where('status', 'active')
            ->with('lines')
            ->get();

        foreach ($subscriptions as $subscription) {
            foreach ($subscription->lines as $lineIndex => $line) {
                $product = $products[($subscription->customer_id + $lineIndex) % $products->count()];

                if ($line->product_id === $product->id) {
                    continue;
                }

                $line->update([
                    'product_id' => $product->id,
                    'unit_rate' => $product->rate,
                    'effective_rate' => SubscriptionLine::computeEffectiveRate(
                        (float) $product->rate,
                        (float) $line->coupon_amount,
                    ),
                ]);

                $updated++;
            }
        }

        if ($updated > 0) {
            $this->command?->info("Farm #{$farm->id}: diversified {$updated} subscription lines across products.");
        }
    }

    private function seedFarm(Farm $farm): void
    {
        $existing = $farm->customers()->count();
        $toCreate = max(0, 50 - $existing);

        if ($toCreate === 0) {
            $this->command?->info("Farm #{$farm->id} already has {$existing} customers — skipped.");

            return;
        }

        $products = $this->activeProducts($farm);
        if ($products->isEmpty()) {
            $product = $farm->products()->create([
                'name' => 'Premium Cow Milk',
                'milk_type' => 'cow',
                'rate' => 80,
                'unit' => 'ltr',
                'container_type' => 'glass_bottle',
                'is_active' => true,
            ]);
            $products = collect([$product]);
        }

        $firstNames = ['Amit', 'Priya', 'Rahul', 'Neha', 'Vijay', 'Kiran', 'Sagar', 'Meera', 'Harsh', 'Anita'];
        $lastNames = ['Patel', 'Shah', 'Mehta', 'Joshi', 'Desai', 'Savaliya', 'Rathod', 'Parmar', 'Gohil', 'Trivedi'];
        $areas = ['Mavdi', 'Kalawad Road', 'University Road', 'Raiya', '150 Feet Ring Road', 'Gondal Road'];
        $today = Carbon::today();

        for ($i = 0; $i < $toCreate; $i++) {
            $index = $existing + $i + 1;
            $first = $firstNames[$i % count($firstNames)];
            $last = $lastNames[intdiv($i, count($firstNames)) % count($lastNames)];

            $bucket = $i % 10;
            $isActive = $bucket !== 2 && $bucket !== 3;
            $onVacation = $bucket === 1 || $bucket === 5;

            $vacationStart = null;
            $vacationEnd = null;
            if ($onVacation) {
                $vacationStart = $today->copy()->subDays(2);
                $vacationEnd = $today->copy()->addDays(5 + ($i % 4));
            }

            $customer = $farm->customers()->create([
                'first_name' => $first,
                'last_name' => $last.' '.$index,
                'address_line' => 'Block '.chr(65 + ($i % 26)).', Shivalik Heights',
                'area' => $areas[$i % count($areas)],
                'landmark' => 'Near main chowk',
                'city' => 'Rajkot',
                'state' => 'Gujarat',
                'zip' => '36000'.str_pad((string) ($i % 10), 1, '0'),
                'contact' => '9'.str_pad((string) (100000000 + $index), 9, '0', STR_PAD_LEFT),
                'whatsapp_enabled' => $i % 3 !== 0,
                'is_active' => $isActive,
                'vacation_start' => $vacationStart,
                'vacation_end' => $vacationEnd,
                'created_at' => now()->subDays(50 - $i),
                'updated_at' => now()->subDays($i % 30),
            ]);

            if (! $isActive) {
                continue;
            }

            $status = $i % 8 === 0 ? 'paused' : 'active';
            if ($status === 'paused') {
                continue;
            }

            $product = $products[($index - 1) % $products->count()];

            $subscription = Subscription::query()->create([
                'farm_id' => $farm->id,
                'customer_id' => $customer->id,
                'status' => 'active',
            ]);

            SubscriptionLine::query()->create([
                'subscription_id' => $subscription->id,
                'product_id' => $product->id,
                'quantity' => 1 + ($i % 3),
                'unit_rate' => $product->rate,
                'coupon_amount' => $i % 5 === 0 ? 5 : 0,
                'effective_rate' => SubscriptionLine::computeEffectiveRate(
                    (float) $product->rate,
                    $i % 5 === 0 ? 5.0 : 0.0,
                ),
                'shift' => $i % 2 === 0 ? 'morning' : 'evening',
            ]);

            if ($i % 6 === 0) {
                $secondProduct = $products[($index + 3) % $products->count()];
                SubscriptionLine::query()->create([
                    'subscription_id' => $subscription->id,
                    'product_id' => $secondProduct->id,
                    'quantity' => 0.5 + ($i % 2),
                    'unit_rate' => $secondProduct->rate,
                    'coupon_amount' => 0,
                    'effective_rate' => (float) $secondProduct->rate,
                    'shift' => $i % 2 === 0 ? 'evening' : 'morning',
                ]);
            }
        }

        $this->command?->info("Farm #{$farm->id}: seeded {$toCreate} demo customers (total {$farm->customers()->count()}).");
    }

    private function backfillSubscriptions(Farm $farm): void
    {
        $products = $this->activeProducts($farm);
        if ($products->isEmpty()) {
            return;
        }

        $customers = $farm->customers()
            ->where('is_active', true)
            ->whereDoesntHave('subscriptions', fn ($q) => $q->where('status', 'active'))
            ->get();

        foreach ($customers as $i => $customer) {
            $product = $products[($customer->id + $i) % $products->count()];
            $subscription = Subscription::query()->create([
                'farm_id' => $farm->id,
                'customer_id' => $customer->id,
                'status' => 'active',
            ]);

            SubscriptionLine::query()->create([
                'subscription_id' => $subscription->id,
                'product_id' => $product->id,
                'quantity' => 1 + ($i % 3),
                'unit_rate' => $product->rate,
                'coupon_amount' => $i % 5 === 0 ? 5 : 0,
                'effective_rate' => SubscriptionLine::computeEffectiveRate(
                    (float) $product->rate,
                    $i % 5 === 0 ? 5.0 : 0.0,
                ),
                'shift' => $i % 2 === 0 ? 'morning' : 'evening',
            ]);
        }

        if ($customers->isNotEmpty()) {
            $this->command?->info("Farm #{$farm->id}: backfilled {$customers->count()} subscriptions.");
        }
    }
}
