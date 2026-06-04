<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\UpdateOwnerSettingsRequest;
use App\Http\Requests\Owner\UpdateOwnerProductRequest;
use App\Models\FarmOwner;
use App\Models\Product;
use App\Support\ApiResponse;
use App\Support\DocumentSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OwnerSettingsController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $products = $owner->farm->products()
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(fn (Product $p) => $this->productPayload($p));

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

        $product->update($request->validated());

        return ApiResponse::success([
            'product' => $this->productPayload($product->fresh()),
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
                'This product is linked to a customer subscription. Update those subscriptions first.',
                409,
            );
        }

        $product->delete();

        return ApiResponse::success(['deleted' => true]);
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
}
