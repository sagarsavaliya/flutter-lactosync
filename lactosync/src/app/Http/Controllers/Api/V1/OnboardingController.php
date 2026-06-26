<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Onboarding\StoreCustomerRequest;
use App\Http\Requests\Onboarding\StoreProductRequest;
use App\Http\Requests\Onboarding\StoreSubscriptionRequest;
use App\Http\Requests\Onboarding\UpdateFarmProfileRequest;
use App\Models\Customer;
use App\Models\FarmOwner;
use App\Models\Product;
use App\Models\Subscription;
use App\Models\SubscriptionLine;
use App\Models\MilkType;
use App\Services\Catalog\ProductConfigurator;
use App\Services\Onboarding\OnboardingService;
use App\Services\Activity\FarmActivityLogger;
use App\Support\ApiResponse;
use App\Support\ProductPayload;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OnboardingController extends Controller
{
    public function __construct(
        private readonly OnboardingService $onboarding,
        private readonly ProductConfigurator $productConfigurator,
        private readonly FarmActivityLogger $activityLogger,
    ) {}

    public function status(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        return ApiResponse::success($this->onboarding->status($owner));
    }

    public function updateFarm(UpdateFarmProfileRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $owner->farm->update($request->validated());
        $this->onboarding->advanceAfterFarmProfile($owner);

        return ApiResponse::success($this->onboarding->status($owner->fresh(['farm'])));
    }

    public function storeProduct(StoreProductRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $product = $owner->farm->products()->create($request->validated());

        if ($owner->farm->products()->where('is_active', true)->count() >= 1) {
            $this->onboarding->advanceAfterProducts($owner);
        }

        return ApiResponse::success([
            'product' => $this->productPayload($product),
            'onboarding' => $this->onboarding->status($owner->fresh(['farm'])),
        ], null, 201);
    }

    public function storeProductsBatch(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $validated = $request->validate([
            'products' => ['required', 'array', 'min:1'],
            'products.*.name' => ['sometimes', 'string', 'max:120'],
            'products.*.milk_type_id' => ['sometimes', 'nullable', 'integer', 'exists:milk_types,id'],
            'products.*.rate' => ['required', 'numeric', 'min:1', 'max:99999'],
            'products.*.unit' => ['required', 'string', 'in:ltr'],
            'products.*.container_type_id' => ['sometimes', 'nullable', 'integer', 'exists:container_types,id'],
            'products.*.container_type_ids' => ['sometimes', 'array'],
            'products.*.container_type_ids.*' => ['integer', 'exists:container_types,id'],
        ]);

        $created = DB::transaction(function () use ($owner, $validated) {
            $items = [];
            foreach ($validated['products'] as $row) {
                $milkType = isset($row['milk_type_id'])
                    ? MilkType::query()->find($row['milk_type_id'])
                    : null;

                $name = $row['name'] ?? $this->productConfigurator->generateName(
                    $milkType,
                    null,
                    (float) $row['rate'],
                );

                // Resolve container_type_id: prefer explicit value, fall back to first of
                // the old-schema container_type_ids array sent by legacy APK builds.
                $containerTypeId = $row['container_type_id']
                    ?? (! empty($row['container_type_ids']) ? (int) $row['container_type_ids'][0] : null);

                $product = $owner->farm->products()->create([
                    'name'              => $name,
                    'milk_type_id'      => $row['milk_type_id'] ?? null,
                    'rate'              => $row['rate'],
                    'unit'              => $row['unit'],
                    'container_type_id' => $containerTypeId,
                    'is_active'         => true,
                ]);

                $items[] = $product->fresh(['milkType', 'containerType.sizes']);
            }

            return $items;
        });

        $this->onboarding->advanceAfterProducts($owner);

        return ApiResponse::success([
            'products' => collect($created)->map(fn (Product $p) => $this->productPayload($p))->values(),
            'onboarding' => $this->onboarding->status($owner->fresh(['farm'])),
        ], null, 201);
    }

    public function products(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $products = $owner->farm->products()
            ->with(['milkType', 'containerType.sizes'])
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(fn (Product $p) => ProductPayload::make($p));

        return ApiResponse::success(['products' => $products]);
    }

    public function storeCustomer(StoreCustomerRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $customer = $owner->farm->customers()->create($request->validated());
        $this->activityLogger->logCreated(
            $owner,
            'customer',
            $customer->id,
            $customer->fullName(),
            ['contact' => $customer->contact],
        );
        $this->onboarding->advanceAfterCustomer($owner);

        return ApiResponse::success([
            'customer' => $this->customerPayload($customer),
            'onboarding' => $this->onboarding->status($owner->fresh(['farm'])),
        ], null, 201);
    }

    public function customers(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $search = trim((string) $request->query('search', ''));

        $query = $owner->farm->customers()
            ->where('is_active', true)
            ->orderBy('first_name')
            ->orderBy('last_name');

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('contact', 'like', "%{$search}%");
            });
        }

        $customers = $query->get()->map(fn (Customer $c) => $this->customerPayload($c));

        return ApiResponse::success(['customers' => $customers]);
    }

    public function storeSubscription(StoreSubscriptionRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $data = $request->validated();

        $customer = $owner->farm->customers()->whereKey($data['customer_id'])->first();
        if (! $customer) {
            return ApiResponse::error('CUSTOMER_NOT_FOUND', 'Customer not found.', 404);
        }

        $subscription = DB::transaction(function () use ($owner, $customer, $data) {
            $subscription = Subscription::query()->create([
                'farm_id' => $owner->farm_id,
                'customer_id' => $customer->id,
                'status' => 'active',
            ]);

            foreach ($data['lines'] as $line) {
                $product = $owner->farm->products()
                    ->whereKey($line['product_id'])
                    ->where('is_active', true)
                    ->firstOrFail();

                $unitRate = (float) $product->rate;
                $coupon = (float) ($line['coupon_amount'] ?? 0);

                SubscriptionLine::query()->create([
                    'subscription_id' => $subscription->id,
                    'product_id' => $product->id,
                    'quantity' => $line['quantity'],
                    'unit_rate' => $unitRate,
                    'coupon_amount' => $coupon,
                    'effective_rate' => SubscriptionLine::computeEffectiveRate($unitRate, $coupon),
                    'shift' => $line['shift'],
                ]);
            }

            return $subscription->load(['lines.product', 'customer']);
        });

        $this->activityLogger->logCreated(
            $owner,
            'subscription',
            $subscription->id,
            $customer->fullName(),
            ['customer_id' => $customer->id],
        );

        $this->onboarding->markCompleted($owner);

        return ApiResponse::success([
            'subscription' => $this->subscriptionPayload($subscription),
            'onboarding' => $this->onboarding->status($owner->fresh(['farm'])),
        ], null, 201);
    }

    public function skipSubscription(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $this->onboarding->markCompleted($owner);

        return ApiResponse::success($this->onboarding->status($owner->fresh(['farm'])));
    }

    private function productPayload(Product $product): array
    {
        return ProductPayload::make($product->loadMissing(['milkType', 'containerType.sizes']));
    }

    private function customerPayload(Customer $customer): array
    {
        return [
            'id' => $customer->id,
            'first_name' => $customer->first_name,
            'last_name' => $customer->last_name,
            'full_name' => $customer->fullName(),
            'address_line' => $customer->address_line,
            'area' => $customer->area,
            'landmark' => $customer->landmark,
            'city' => $customer->city,
            'state' => $customer->state,
            'zip' => $customer->zip,
            'contact' => $customer->contact,
            'whatsapp_enabled' => $customer->whatsapp_enabled,
            'secondary_contact' => $customer->secondary_contact,
            'is_active' => $customer->is_active,
            'delivery_type' => $customer->delivery_type ?? 'home_delivery',
        ];
    }

    private function subscriptionPayload(Subscription $subscription): array
    {
        return [
            'id' => $subscription->id,
            'customer' => $this->customerPayload($subscription->customer),
            'lines' => $subscription->lines->map(fn (SubscriptionLine $line) => [
                'id' => $line->id,
                'product' => $this->productPayload($line->product),
                'quantity' => (float) $line->quantity,
                'unit_rate' => (float) $line->unit_rate,
                'coupon_amount' => (float) $line->coupon_amount,
                'effective_rate' => (float) $line->effective_rate,
                'shift' => $line->shift->value,
                'shift_label' => $line->shift->label(),
            ])->values(),
        ];
    }
}
