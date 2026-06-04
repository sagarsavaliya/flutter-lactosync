<?php

namespace App\Services\Legacy;

use App\Enums\ContainerType;
use App\Enums\MilkType;
use App\Models\Customer;
use App\Models\Farm;
use App\Models\Product;
use App\Models\Subscription;
use App\Models\SubscriptionLine;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class LegacyDugdhSetuImporter
{
    /** @var array<string, int> */
    private array $customerMap = [];

    /** @var array<string, int> */
    private array $productMap = [];

    private int $dryRunProductSeq = 900000;

    private int $dryRunCustomerSeq = 900000;

    public function __construct(
        private readonly bool $dryRun = false,
        private readonly bool $skipExisting = true,
    ) {}

    /**
     * @param  array{
     *   farm: array<string, mixed>,
     *   customers: list<array<string, mixed>>,
     *   products: list<array<string, mixed>>,
     *   subscriptions: list<array<string, mixed>>
     * }  $payload
     * @return array{customers: int, products: int, subscriptions: int, lines: int, skipped_customers: int}
     */
    public function import(Farm $farm, array $payload): array
    {
        $stats = [
            'customers' => 0,
            'products' => 0,
            'subscriptions' => 0,
            'lines' => 0,
            'skipped_customers' => 0,
        ];

        try {
            DB::transaction(function () use ($farm, $payload, &$stats): void {
                $this->runImportBody($farm, $payload, $stats);

                if ($this->dryRun) {
                    throw new \RuntimeException('dry-run-rollback');
                }
            });
        } catch (\RuntimeException $e) {
            if ($e->getMessage() !== 'dry-run-rollback') {
                throw $e;
            }
        }

        return $stats;
    }

    /**
     * @param  array{customers: int, products: int, subscriptions: int, lines: int, skipped_customers: int}  $stats
     */
    private function runImportBody(Farm $farm, array $payload, array &$stats): void
    {
        $this->loadExistingMaps($farm);

            foreach ($payload['products'] as $row) {
                $legacyId = (string) $row['ProductId'];
                if (isset($this->productMap[$legacyId])) {
                    continue;
                }

                $product = $this->resolveProduct($farm, $row);
                $this->productMap[$legacyId] = $product->id ?? ++$this->dryRunProductSeq;
                $this->rememberMap($farm, 'product', $legacyId, $this->productMap[$legacyId]);
                $stats['products']++;
            }

            foreach ($payload['customers'] as $row) {
                $legacyId = (string) $row['CustomerId'];
                if (isset($this->customerMap[$legacyId])) {
                    continue;
                }

                $contact = $this->normalizeMobile((string) ($row['Contact'] ?? ''));
                if ($contact === null) {
                    $stats['skipped_customers']++;

                    continue;
                }

                if ($this->skipExisting && ! $this->dryRun) {
                    $existing = Customer::query()
                        ->where('farm_id', $farm->id)
                        ->where('contact', $contact)
                        ->first();

                    if ($existing) {
                        $this->customerMap[$legacyId] = $existing->id;
                        $this->rememberMap($farm, 'customer', $legacyId, $existing->id);
                        $stats['skipped_customers']++;

                        continue;
                    }
                }

                if ($this->skipExisting && $this->dryRun) {
                    $exists = Customer::query()
                        ->where('farm_id', $farm->id)
                        ->where('contact', $contact)
                        ->exists();

                    if ($exists) {
                        $stats['skipped_customers']++;

                        continue;
                    }
                }

                $customer = $this->createCustomer($farm, $row, $contact);
                $this->customerMap[$legacyId] = $customer->id ?? ++$this->dryRunCustomerSeq;
                $this->rememberMap($farm, 'customer', $legacyId, $this->customerMap[$legacyId]);
                $stats['customers']++;
            }

            $linesByCustomer = [];
            foreach ($payload['subscriptions'] as $row) {
                $customerLegacyId = (string) $row['CustomerId'];
                $linesByCustomer[$customerLegacyId][] = $row;
            }

            foreach ($linesByCustomer as $customerLegacyId => $rows) {
                $customerId = $this->customerMap[$customerLegacyId] ?? null;
                if ($customerId === null) {
                    continue;
                }

                $activeRows = array_values(array_filter(
                    $rows,
                    fn (array $row) => (bool) ($row['IsActive'] ?? true) && (int) ($row['Status'] ?? 0) === 0,
                ));

                if ($activeRows === []) {
                    continue;
                }

                if ($this->dryRun) {
                    $stats['subscriptions']++;
                    $stats['lines'] += count($activeRows);

                    continue;
                }

                $existingSubscription = Subscription::query()
                    ->where('farm_id', $farm->id)
                    ->where('customer_id', $customerId)
                    ->where('status', 'active')
                    ->first();

                $subscription = $existingSubscription ?? Subscription::query()->create([
                    'farm_id' => $farm->id,
                    'customer_id' => $customerId,
                    'status' => 'active',
                ]);

                if ($existingSubscription === null) {
                    $stats['subscriptions']++;
                }

                foreach ($activeRows as $row) {
                    $productLegacyId = (string) $row['ProductId'];
                    $productId = $this->productMap[$productLegacyId] ?? null;
                    if ($productId === null) {
                        continue;
                    }

                    $shift = $this->mapShift((int) ($row['Shift'] ?? 0));
                    $quantity = (float) ($row['Qty'] ?? 0);
                    if ($quantity <= 0) {
                        continue;
                    }

                    $duplicate = SubscriptionLine::query()
                        ->where('subscription_id', $subscription->id)
                        ->where('product_id', $productId)
                        ->where('shift', $shift)
                        ->exists();

                    if ($duplicate) {
                        continue;
                    }

                    $product = Product::query()->findOrFail($productId);
                    $unitRate = (float) ($row['Rate'] ?? $product->rate);
                    $coupon = (float) ($row['DiscountAmount'] ?? 0);

                    SubscriptionLine::query()->create([
                        'subscription_id' => $subscription->id,
                        'product_id' => $productId,
                        'quantity' => $quantity,
                        'unit_rate' => $unitRate,
                        'coupon_amount' => $coupon,
                        'effective_rate' => SubscriptionLine::computeEffectiveRate($unitRate, $coupon),
                        'shift' => $shift,
                    ]);

                    $stats['lines']++;
                }
            }
    }

    private function loadExistingMaps(Farm $farm): void
    {
        if (! Schema::hasTable('legacy_import_maps')) {
            return;
        }

        $rows = DB::table('legacy_import_maps')
            ->where('farm_id', $farm->id)
            ->get(['entity_type', 'legacy_id', 'local_id']);

        foreach ($rows as $row) {
            if ($row->entity_type === 'customer') {
                $this->customerMap[$row->legacy_id] = (int) $row->local_id;
            }
            if ($row->entity_type === 'product') {
                $this->productMap[$row->legacy_id] = (int) $row->local_id;
            }
        }
    }

    /**
     * @param  array<string, mixed>  $row
     */
    private function createCustomer(Farm $farm, array $row, string $contact): Customer
    {
        $payload = [
            'farm_id' => $farm->id,
            'first_name' => trim((string) ($row['FirstName'] ?? 'Customer')),
            'last_name' => trim((string) ($row['LastName'] ?? '')),
            'address_line' => trim((string) ($row['Address'] ?? '')) ?: 'Address pending',
            'area' => $this->nullableString($row['Location'] ?? null),
            'landmark' => $this->nullableString($row['Landmark'] ?? null),
            'city' => trim((string) ($row['City'] ?? '')) ?: 'Rajkot',
            'state' => trim((string) ($row['State'] ?? '')) ?: 'Gujarat',
            'zip' => $this->normalizeZip((string) ($row['ZipCode'] ?? '')),
            'contact' => $contact,
            'whatsapp_enabled' => true,
            'secondary_contact' => $this->normalizeMobile((string) ($row['SecondaryContact'] ?? '')),
            'is_active' => (bool) ($row['IsActive'] ?? true),
        ];

        if ($this->dryRun) {
            return new Customer($payload);
        }

        return Customer::query()->create($payload);
    }

    /**
     * @param  array<string, mixed>  $row
     */
    private function resolveProduct(Farm $farm, array $row): Product
    {
        $name = trim((string) ($row['Name'] ?? 'Milk'));
        $rate = (float) ($row['Rate'] ?? 0);
        $normalized = $this->normalizeName($name);

        $existing = $farm->products()
            ->get()
            ->first(fn (Product $product) => $this->normalizeName($product->name) === $normalized);

        if ($existing) {
            return $existing;
        }

        $payload = [
            'farm_id' => $farm->id,
            'name' => $name,
            'milk_type' => $this->inferMilkType($name)->value,
            'rate' => $rate > 0 ? $rate : 70,
            'unit' => 'ltr',
            'container_type' => ContainerType::GlassBottle->value,
            'is_active' => (bool) ($row['IsActive'] ?? true),
        ];

        if ($this->dryRun) {
            return new Product($payload);
        }

        return Product::query()->create($payload);
    }

    private function rememberMap(Farm $farm, string $entityType, string $legacyId, int $localId): void
    {
        if ($this->dryRun) {
            return;
        }

        DB::table('legacy_import_maps')->updateOrInsert(
            [
                'farm_id' => $farm->id,
                'entity_type' => $entityType,
                'legacy_id' => $legacyId,
            ],
            [
                'local_id' => $localId,
                'updated_at' => now(),
                'created_at' => now(),
            ],
        );
    }

    private function mapShift(int $shift): string
    {
        return $shift === 1 ? 'evening' : 'morning';
    }

    private function inferMilkType(string $name): MilkType
    {
        $lower = Str::lower($name);

        if (Str::contains($lower, ['gir', 'gircow'])) {
            return MilkType::GirCow;
        }

        if (Str::contains($lower, ['buffalo', 'bufalo', 'buff'])) {
            return MilkType::Buffalo;
        }

        return MilkType::Cow;
    }

    private function normalizeName(string $name): string
    {
        return Str::lower(preg_replace('/\s+/', ' ', trim($name)) ?? '');
    }

    private function normalizeMobile(?string $value): ?string
    {
        if ($value === null || trim($value) === '') {
            return null;
        }

        $digits = preg_replace('/\D/', '', $value) ?? '';
        if (strlen($digits) > 10) {
            $digits = substr($digits, -10);
        }

        return strlen($digits) === 10 ? $digits : null;
    }

    private function normalizeZip(string $value): string
    {
        $digits = preg_replace('/\D/', '', $value) ?? '';

        return strlen($digits) === 6 ? $digits : '360001';
    }

    private function nullableString(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $trimmed = trim((string) $value);

        return $trimmed === '' ? null : $trimmed;
    }
}
