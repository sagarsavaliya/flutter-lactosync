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
use App\Services\Onboarding\OnboardingService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OnboardingController extends Controller
{
    public function __construct(
        private readonly OnboardingService $onboarding,
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
            'products.*.name' => ['required', 'string', 'max:120'],
            'products.*.milk_type' => ['required', 'string', 'in:gir_cow,cow,buffalo'],
            'products.*.rate' => ['required', 'numeric', 'min:1', 'max:99999'],
            'products.*.unit' => ['required', 'string', 'in:ltr'],
            'products.*.container_type' => ['required', 'string', 'in:glass_bottle,plastic_bag'],
        ]);

        $created = DB::transaction(function () use ($owner, $validated) {
            $items = [];
            foreach ($validated['products'] as $row) {
                $items[] = $owner->farm->products()->create($row);
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
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(fn (Product $p) => $this->productPayload($p));

        return ApiResponse::success(['products' => $products]);
    }

    public function storeCustomer(StoreCustomerRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $customer = $owner->farm->customers()->create($request->validated());
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
        return [
            'id' => $product->id,
            'name' => $product->name,
            'milk_type' => $product->milk_type->value,
            'milk_type_label' => $product->milk_type->label(),
            'rate' => (float) $product->rate,
            'unit' => $product->unit,
            'container_type' => $product->container_type->value,
            'container_type_label' => $product->container_type->label(),
        ];
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
