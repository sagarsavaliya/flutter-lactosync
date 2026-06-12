<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\UpdateOwnerSettingsRequest;
use App\Http\Requests\Owner\UpdateOwnerProductRequest;
use App\Models\FarmOwner;
use App\Models\MilkType;
use App\Models\Pincode;
use App\Models\Product;
use App\Services\Catalog\ProductConfigurator;
use App\Support\ApiResponse;
use App\Support\DocumentSettings;
use App\Support\ProductPayload;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OwnerSettingsController extends Controller
{
    public function __construct(
        private readonly ProductConfigurator $productConfigurator,
    ) {}

    public function show(Request $request): JsonResponse
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

        return ApiResponse::success([
            'farm' => $this->farmPayload($owner->farm),
            'owner' => $this->ownerPayload($owner),
            'document_settings' => DocumentSettings::merge($owner->farm->document_settings),
            'products' => $products,
        ]);
    }

    public function update(UpdateOwnerSettingsRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $validated = $request->validated();

        if (isset($validated['farm'])) {
            $owner->farm->update($validated['farm']);
        }

        if (isset($validated['owner'])) {
            $owner->update($validated['owner']);
            $owner->syncLegacyName();
        }

        if (isset($validated['document_settings'])) {
            $owner->farm->update([
                'document_settings' => DocumentSettings::validate($validated['document_settings']),
            ]);
        }

        $owner->refresh();
        $owner->loadMissing('farm');

        return ApiResponse::success([
            'farm' => $this->farmPayload($owner->farm),
            'owner' => $this->ownerPayload($owner),
            'document_settings' => DocumentSettings::merge($owner->farm->document_settings),
        ]);
    }

    public function updateProduct(UpdateOwnerProductRequest $request, Product $product): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($product->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Product not found.', 404);
        }

        $validated = $request->validated();

        DB::transaction(function () use ($product, $validated, $owner) {
            $milkType = isset($validated['milk_type_id'])
                ? MilkType::query()->find($validated['milk_type_id'])
                : null;

            $rate = isset($validated['rate']) ? (float) $validated['rate'] : (float) $product->rate;
            $name = $validated['name'] ?? $this->productConfigurator->generateName(
                $milkType,
                null,
                $rate,
            );

            $product->update(array_filter([
                'name'              => $name,
                'milk_type_id'      => $validated['milk_type_id'] ?? null,
                'container_type_id' => $validated['container_type_id'] ?? null,
                'rate'              => $validated['rate'] ?? null,
                'unit'              => $validated['unit'] ?? null,
            ], fn ($value) => $value !== null));
        });

        return ApiResponse::success([
            'product' => ProductPayload::make($product->fresh(['milkType', 'containerType.sizes'])),
        ]);
    }

    public function destroyProduct(Request $request, Product $product): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($product->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Product not found.', 404);
        }

        $inUse = $product->subscriptionLines()
            ->whereHas('subscription', fn ($q) => $q->whereNull('deleted_at'))
            ->exists();

        if ($inUse) {
            return ApiResponse::error(
                'PRODUCT_IN_USE',
                'This product has active subscriptions and cannot be deleted.',
                422,
            );
        }

        $product->delete();

        return ApiResponse::success(['deleted' => true]);
    }

    public function pincodeLookup(Request $request, string $pincode): JsonResponse
    {
        if (! preg_match('/^\d{6}$/', $pincode)) {
            return ApiResponse::error('VALIDATION_ERROR', 'Pincode must be exactly 6 digits.', 422);
        }

        $row = Pincode::where('pincode', $pincode)->first();

        if (! $row) {
            return ApiResponse::error('PINCODE_NOT_FOUND', 'Pincode not found.', 404);
        }

        return ApiResponse::success([
            'city'     => $row->city,
            'district' => $row->district,
            'state'    => $row->state,
        ]);
    }

    private function farmPayload($farm): array
    {
        return [
            'id' => $farm->id,
            'name' => $farm->name,
            'address_line' => $farm->address_line,
            'city' => $farm->city,
            'state' => $farm->state,
            'zip' => $farm->zip,
            'upi_vpa' => $farm->upi_vpa,
            'upi_payee_name' => $farm->upi_payee_name,
            'morning_order_time' => $farm->morning_order_time ?? '05:00',
            'evening_order_time' => $farm->evening_order_time ?? '15:00',
            'prefill_customer_address' => (bool) $farm->prefill_customer_address,
        ];
    }

    private function ownerPayload(FarmOwner $owner): array
    {
        return [
            'first_name' => $owner->first_name,
            'last_name' => $owner->last_name,
            'full_name' => $owner->fullName(),
            'mobile' => $owner->mobile,
        ];
    }
}
