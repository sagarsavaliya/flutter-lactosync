<?php

namespace App\Services\Admin;

use App\Enums\OnboardingStep;
use App\Models\ContainerType;
use App\Models\ContainerTypeSize;
use App\Models\Customer;
use App\Models\DeliveryRoute;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Models\MilkType;
use App\Models\Product;
use App\Models\RouteCustomerAssignment;
use App\Models\Subscription;
use App\Models\SubscriptionLine;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TenantBootstrapImporter
{
    public function __construct(
        private readonly TenantBootstrapWorkbookReader $reader,
    ) {}

    /**
     * @return array{
     *   farm_updated: bool,
     *   products_created: int,
     *   customers_created: int,
     *   subscriptions_created: int,
     *   subscription_lines_created: int,
     *   routes_created: int,
     *   route_customers_created: int,
     *   warnings: list<string>
     * }
     */
    public function importFromWorkbook(FarmOwner $owner, UploadedFile $file): array
    {
        $workbook = $this->reader->read($file);
        $farm = $owner->farm()->firstOrFail();

        $warnings = [];
        $stats = [
            'farm_updated' => false,
            'products_created' => 0,
            'customers_created' => 0,
            'subscriptions_created' => 0,
            'subscription_lines_created' => 0,
            'routes_created' => 0,
            'route_customers_created' => 0,
            'warnings' => &$warnings,
        ];

        DB::transaction(function () use ($workbook, $farm, $owner, &$stats, &$warnings): void {
            $customersByContact = [];
            $productsByName = [];
            $routesByKey = [];
            $subscriptionsByCustomerId = [];

            if ($this->hasFarmProfileData($workbook['farm_profile'])) {
                $this->applyFarmProfile($farm, $workbook['farm_profile']);
                $stats['farm_updated'] = true;
            }

            foreach ($workbook['products'] as $index => $row) {
                $sheetRow = $index + 2;
                $name = trim((string) ($row['product_name'] ?? ''));
                if ($name === '') {
                    $warnings[] = "Products row {$sheetRow}: skipped because product_name is empty.";
                    continue;
                }

                $normalized = Str::lower($name);
                if (isset($productsByName[$normalized])) {
                    continue;
                }

                $rate = (float) ($row['product_rate'] ?? 0);
                if ($rate <= 0) {
                    $warnings[] = "Products row {$sheetRow}: skipped '{$name}' because product_rate is invalid.";
                    continue;
                }

                $product = Product::query()
                    ->where('farm_id', $farm->id)
                    ->whereRaw('LOWER(name) = ?', [$normalized])
                    ->first();

                if (! $product) {
                    $milkType = $this->resolveMilkType($farm, (string) ($row['milk_type_name'] ?? 'Cow'));
                    $containerType = $this->resolveContainerType(
                        $farm,
                        (string) ($row['container_type_name'] ?? 'Glass Bottle'),
                        (string) ($row['available_container_sizes'] ?? ''),
                    );

                    $product = Product::query()->create([
                        'farm_id' => $farm->id,
                        'name' => $name,
                        'milk_type_id' => $milkType->id,
                        'rate' => $rate,
                        'unit' => 'ltr',
                        'container_type_id' => $containerType->id,
                        'is_active' => $this->toBool($row['is_active'] ?? '1', true),
                    ]);
                    $stats['products_created']++;
                }

                $productsByName[$normalized] = $product;
            }

            foreach ($workbook['customers'] as $index => $row) {
                $sheetRow = $index + 2;
                $contact = $this->normalizeMobile((string) ($row['customer_contact'] ?? ''));
                if ($contact === null) {
                    $warnings[] = "Customers row {$sheetRow}: skipped because customer_contact is invalid.";
                    continue;
                }

                if (isset($customersByContact[$contact])) {
                    continue;
                }

                $firstName = trim((string) ($row['customer_first_name'] ?? ''));
                if ($firstName === '') {
                    $firstName = 'Customer';
                }

                $deliveryType = Str::lower(trim((string) ($row['delivery_type'] ?? 'home_delivery')));
                if (! in_array($deliveryType, ['home_delivery', 'walk_in'], true)) {
                    $deliveryType = 'home_delivery';
                }

                $customer = Customer::query()
                    ->where('farm_id', $farm->id)
                    ->where('contact', $contact)
                    ->first();

                if (! $customer) {
                    $isWalkIn = $deliveryType === 'walk_in';
                    $customer = Customer::query()->create([
                        'farm_id' => $farm->id,
                        'first_name' => $firstName,
                        'last_name' => trim((string) ($row['customer_last_name'] ?? '')),
                        'address_line' => $isWalkIn
                            ? 'Walk-in customer'
                            : $this->fallback((string) ($row['address_line'] ?? ''), 'Address pending'),
                        'area' => $this->nullableText($row['area'] ?? null),
                        'landmark' => $this->nullableText($row['landmark'] ?? null),
                        'city' => $isWalkIn
                            ? 'Walk-in'
                            : $this->fallback((string) ($row['city'] ?? ''), 'Rajkot'),
                        'state' => $isWalkIn
                            ? 'NA'
                            : $this->fallback((string) ($row['state'] ?? ''), 'Gujarat'),
                        'zip' => $isWalkIn
                            ? '000000'
                            : $this->normalizeZip((string) ($row['zip'] ?? '')),
                        'contact' => $contact,
                        'whatsapp_enabled' => $this->toBool($row['whatsapp_enabled'] ?? '1', true),
                        'secondary_contact' => $this->normalizeMobile((string) ($row['secondary_contact'] ?? '')),
                        'is_active' => $this->toBool($row['is_active'] ?? '1', true),
                        'delivery_type' => $deliveryType,
                    ]);
                    $stats['customers_created']++;
                }

                $customersByContact[$contact] = $customer;
            }

            foreach ($workbook['subscriptions'] as $index => $row) {
                $sheetRow = $index + 2;
                $contact = $this->normalizeMobile((string) ($row['customer_contact'] ?? ''));
                $productName = trim((string) ($row['product_name'] ?? ''));
                $qty = (float) ($row['quantity_ltr'] ?? 0);
                $shift = Str::lower(trim((string) ($row['shift'] ?? 'morning')));

                if ($contact === null || ! isset($customersByContact[$contact])) {
                    $warnings[] = "Subscriptions row {$sheetRow}: customer_contact not found in Customers sheet.";
                    continue;
                }
                if ($productName === '') {
                    $warnings[] = "Subscriptions row {$sheetRow}: product_name is empty.";
                    continue;
                }
                if ($qty <= 0) {
                    $warnings[] = "Subscriptions row {$sheetRow}: quantity_ltr must be greater than zero.";
                    continue;
                }
                if (! in_array($shift, ['morning', 'evening'], true)) {
                    $shift = 'morning';
                }

                $product = $productsByName[Str::lower($productName)] ?? Product::query()
                    ->where('farm_id', $farm->id)
                    ->whereRaw('LOWER(name) = ?', [Str::lower($productName)])
                    ->first();
                if (! $product) {
                    $warnings[] = "Subscriptions row {$sheetRow}: product '{$productName}' not found in Products sheet.";
                    continue;
                }

                $customer = $customersByContact[$contact];
                $subscription = $subscriptionsByCustomerId[$customer->id] ?? Subscription::query()
                    ->where('farm_id', $farm->id)
                    ->where('customer_id', $customer->id)
                    ->where('status', 'active')
                    ->first();

                if (! $subscription) {
                    $subscription = Subscription::query()->create([
                        'farm_id' => $farm->id,
                        'customer_id' => $customer->id,
                        'status' => 'active',
                    ]);
                    $stats['subscriptions_created']++;
                }
                $subscriptionsByCustomerId[$customer->id] = $subscription;

                $duplicate = SubscriptionLine::query()
                    ->where('subscription_id', $subscription->id)
                    ->where('product_id', $product->id)
                    ->where('shift', $shift)
                    ->exists();

                if ($duplicate) {
                    continue;
                }

                $coupon = max(0, (float) ($row['coupon_amount'] ?? 0));
                $unitRate = (float) $product->rate;
                SubscriptionLine::query()->create([
                    'subscription_id' => $subscription->id,
                    'product_id' => $product->id,
                    'quantity' => $qty,
                    'unit_rate' => $unitRate,
                    'coupon_amount' => $coupon,
                    'effective_rate' => SubscriptionLine::computeEffectiveRate($unitRate, $coupon),
                    'shift' => $shift,
                ]);
                $stats['subscription_lines_created']++;
            }

            foreach ($workbook['routes'] as $index => $row) {
                $sheetRow = $index + 2;
                $routeName = trim((string) ($row['route_name'] ?? ''));
                $shift = Str::lower(trim((string) ($row['shift'] ?? 'morning')));
                if ($routeName === '') {
                    $warnings[] = "Routes row {$sheetRow}: route_name is empty.";
                    continue;
                }
                if (! in_array($shift, ['morning', 'evening'], true)) {
                    $shift = 'morning';
                }
                $key = Str::lower($routeName).'|'.$shift;
                if (isset($routesByKey[$key])) {
                    continue;
                }

                $route = DeliveryRoute::query()
                    ->where('farm_id', $farm->id)
                    ->whereRaw('LOWER(name) = ?', [Str::lower($routeName)])
                    ->where('shift', $shift)
                    ->first();

                if (! $route) {
                    $route = DeliveryRoute::query()->create([
                        'farm_id' => $farm->id,
                        'name' => $routeName,
                        'shift' => $shift,
                        'sort_order' => (int) ($row['sort_order'] ?? 0),
                        'is_active' => $this->toBool($row['is_active'] ?? '1', true),
                    ]);
                    $stats['routes_created']++;
                }

                $routesByKey[$key] = $route;
            }

            foreach ($workbook['route_customers'] as $index => $row) {
                $sheetRow = $index + 2;
                $routeName = trim((string) ($row['route_name'] ?? ''));
                $shift = Str::lower(trim((string) ($row['shift'] ?? 'morning')));
                $contact = $this->normalizeMobile((string) ($row['customer_contact'] ?? ''));
                if ($routeName === '' || $contact === null) {
                    $warnings[] = "Route Customers row {$sheetRow}: route_name or customer_contact is invalid.";
                    continue;
                }

                $routeKey = Str::lower($routeName).'|'.$shift;
                $route = $routesByKey[$routeKey] ?? null;
                $customer = $customersByContact[$contact] ?? Customer::query()
                    ->where('farm_id', $farm->id)
                    ->where('contact', $contact)
                    ->first();

                if (! $route || ! $customer) {
                    $warnings[] = "Route Customers row {$sheetRow}: route or customer not found.";
                    continue;
                }

                $exists = RouteCustomerAssignment::query()
                    ->where('route_id', $route->id)
                    ->where('customer_id', $customer->id)
                    ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
                    ->exists();
                if ($exists) {
                    continue;
                }

                RouteCustomerAssignment::query()->create([
                    'route_id' => $route->id,
                    'customer_id' => $customer->id,
                    'sort_order' => (int) ($row['sort_order'] ?? 0),
                    'assigned_date' => RouteCustomerAssignment::STANDING_DATE,
                ]);
                $stats['route_customers_created']++;
            }

            $owner->forceFill(['onboarding_step' => OnboardingStep::Completed])->save();
            $farm->forceFill(['onboarding_completed_at' => now()])->save();
        });

        /** @var array{farm_updated: bool,products_created: int,customers_created: int,subscriptions_created: int,subscription_lines_created: int,routes_created: int,route_customers_created: int,warnings: list<string>} $stats */
        return $stats;
    }

    /**
     * @param array<string, string> $row
     */
    private function hasFarmProfileData(array $row): bool
    {
        foreach ($row as $value) {
            if (trim($value) !== '') {
                return true;
            }
        }

        return false;
    }

    /**
     * @param array<string, string> $row
     */
    private function applyFarmProfile(Farm $farm, array $row): void
    {
        $updates = [
            'name' => $this->fallback((string) ($row['farm_name'] ?? ''), $farm->name),
            'address_line' => $this->fallback((string) ($row['address_line'] ?? ''), $farm->address_line ?? ''),
            'city' => $this->fallback((string) ($row['city'] ?? ''), $farm->city ?? ''),
            'state' => $this->fallback((string) ($row['state'] ?? ''), $farm->state ?? ''),
            'zip' => $this->normalizeZip((string) ($row['zip'] ?? '')),
            'prefill_customer_address' => $this->toBool($row['prefill_customer_address'] ?? '1', true),
        ];

        if (array_key_exists('gst_number', $row)) {
            $settings = is_array($farm->document_settings) ? $farm->document_settings : [];
            $settings['gst_number'] = $this->nullableText($row['gst_number']);
            $updates['document_settings'] = $settings;
        }

        $farm->update($updates);
    }

    private function resolveMilkType(Farm $farm, string $name): MilkType
    {
        $name = trim($name) !== '' ? trim($name) : 'Cow';
        $normalized = Str::lower($name);

        $existing = MilkType::query()
            ->where(function ($q) use ($farm) {
                $q->whereNull('farm_id')->orWhere('farm_id', $farm->id);
            })
            ->whereRaw('LOWER(name) = ?', [$normalized])
            ->first();

        if ($existing) {
            return $existing;
        }

        return MilkType::query()->create([
            'farm_id' => $farm->id,
            'name' => $name,
            'is_active' => true,
        ]);
    }

    private function resolveContainerType(Farm $farm, string $name, string $sizesRaw = ''): ContainerType
    {
        $name = $this->normalizeContainerTypeName($name);
        $normalized = Str::lower($name);

        $existing = ContainerType::query()
            ->where(function ($q) use ($farm) {
                $q->whereNull('farm_id')->orWhere('farm_id', $farm->id);
            })
            ->whereRaw('LOWER(name) = ?', [$normalized])
            ->first();

        $sizes = $this->parseContainerSizes($sizesRaw, $normalized);

        if ($existing) {
            $this->syncContainerTypeSizes($existing, $sizes);

            return $existing;
        }

        $containerType = ContainerType::query()->create([
            'farm_id' => $farm->id,
            'name' => $name,
            'is_active' => true,
        ]);
        $this->syncContainerTypeSizes($containerType, $sizes);

        return $containerType;
    }

    private function normalizeContainerTypeName(string $name): string
    {
        $name = trim($name);
        if ($name === '') {
            return 'Glass Bottle';
        }

        // Legacy templates may still use combined names like "Glass Bottle 1L".
        $legacy = [
            '/^glass bottle\s+1\s*l$/i' => 'Glass Bottle',
            '/^glass bottle\s+500\s*ml$/i' => 'Glass Bottle',
            '/^plastic bag\s+1\s*l$/i' => 'Plastic Bag',
            '/^plastic bag\s+500\s*ml$/i' => 'Plastic Bag',
            '/^plastic bag\s+1\.5\s*l$/i' => 'Plastic Bag',
            '/^plastic bag\s+2\s*l$/i' => 'Plastic Bag',
        ];
        foreach ($legacy as $pattern => $canonical) {
            if (preg_match($pattern, $name) === 1) {
                return $canonical;
            }
        }

        return $name;
    }

    /**
     * @return list<float>
     */
    private function parseContainerSizes(string $raw, string $normalizedTypeName): array
    {
        $tokens = array_filter(array_map('trim', preg_split('/[,;|]+/', $raw) ?: []));
        $sizes = [];

        foreach ($tokens as $token) {
            $liters = $this->parseSizeTokenToLiters($token);
            if ($liters !== null && $liters > 0) {
                $sizes[] = $liters;
            }
        }

        if ($sizes !== []) {
            $sizes = array_values(array_unique($sizes));
            sort($sizes);

            return $sizes;
        }

        $defaults = TenantBootstrapWorkbookSpec::defaultContainerSizesByType();

        return $defaults[$normalizedTypeName] ?? [1.0];
    }

    private function parseSizeTokenToLiters(string $token): ?float
    {
        $token = Str::lower(trim($token));
        if ($token === '') {
            return null;
        }

        if (preg_match('/^(\d+(?:\.\d+)?)\s*ml$/', $token, $m) === 1) {
            return round(((float) $m[1]) / 1000, 4);
        }

        if (preg_match('/^(\d+(?:\.\d+)?)\s*l(?:itre|iter|trs)?$/', $token, $m) === 1) {
            return round((float) $m[1], 4);
        }

        if (is_numeric($token)) {
            return round((float) $token, 4);
        }

        return null;
    }

    /**
     * @param list<float> $sizes
     */
    private function syncContainerTypeSizes(ContainerType $containerType, array $sizes): void
    {
        foreach ($sizes as $sizeLiters) {
            ContainerTypeSize::query()->firstOrCreate(
                [
                    'container_type_id' => $containerType->id,
                    'size_liters' => $sizeLiters,
                ],
            );
        }
    }

    private function normalizeMobile(string $value): ?string
    {
        $digits = preg_replace('/\D/', '', $value) ?? '';
        if (strlen($digits) > 10) {
            $digits = substr($digits, -10);
        }

        return strlen($digits) === 10 ? $digits : null;
    }

    private function normalizeZip(string $value): string
    {
        $digits = preg_replace('/\D/', '', $value) ?? '';
        if (strlen($digits) >= 6) {
            return substr($digits, 0, 6);
        }

        return '360001';
    }

    private function fallback(string $value, string $fallback): string
    {
        $trimmed = trim($value);

        return $trimmed !== '' ? $trimmed : $fallback;
    }

    private function nullableText(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $text = trim((string) $value);

        return $text === '' ? null : $text;
    }

    private function toBool(mixed $value, bool $default): bool
    {
        if ($value === null || trim((string) $value) === '') {
            return $default;
        }
        $normalized = Str::lower(trim((string) $value));

        return in_array($normalized, ['1', 'true', 'yes', 'y'], true);
    }
}
