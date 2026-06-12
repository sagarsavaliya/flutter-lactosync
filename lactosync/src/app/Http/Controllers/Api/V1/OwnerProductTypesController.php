<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\StoreContainerTypeRequest;
use App\Http\Requests\Owner\StoreOwnerProductRequest;
use App\Models\ContainerType;
use App\Models\ContainerTypeSize;
use App\Models\FarmContainerTypeVisibility;
use App\Models\FarmMilkTypeVisibility;
use App\Models\FarmOwner;
use App\Models\MilkType;
use App\Models\Product;
use App\Support\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OwnerProductTypesController extends Controller
{
    // ─────────────────────────────────────────────────────────────────────
    // Products
    // ─────────────────────────────────────────────────────────────────────

    public function indexProducts(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $products = Product::with(['milkType', 'containerType.sizes'])
            ->where('farm_id', $owner->farm_id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(fn (Product $p) => $this->productPayload($p));

        return ApiResponse::success(['products' => $products]);
    }

    public function storeProduct(StoreOwnerProductRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $farmId = $owner->farm_id;

        $validated = $request->validated();

        // Validate milk_type_id is visible to this farm
        $milkType = MilkType::visibleToFarm($farmId)->find($validated['milk_type_id']);
        if (! $milkType) {
            return ApiResponse::error('INVALID_MILK_TYPE', 'The selected milk type is not available for your farm.', 422);
        }

        // Validate container_type_id is a system default OR this farm's custom type
        $containerType = ContainerType::with('sizes')
            ->visibleToFarm($farmId)
            ->find($validated['container_type_id']);
        if (! $containerType) {
            return ApiResponse::error('INVALID_CONTAINER_TYPE', 'The selected container type is not available for your farm.', 422);
        }

        $rate = (float) $validated['rate'];
        $rateLabel = fmod($rate, 1.0) === 0.0
            ? (string) (int) $rate
            : rtrim(number_format($rate, 1), '0');

        $name = "{$milkType->name} - ₹{$rateLabel}";

        $product = Product::create([
            'farm_id'           => $farmId,
            'milk_type_id'      => $milkType->id,
            'container_type_id' => $containerType->id,
            'rate'              => $rate,
            'name'              => $name,
            'is_active'         => true,
        ]);

        $product->load(['milkType', 'containerType.sizes']);

        return ApiResponse::success(['product' => $this->productPayload($product)], null, 201);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Milk Types
    // ─────────────────────────────────────────────────────────────────────

    public function indexMilkTypes(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $farmId = $owner->farm_id;

        // Hidden system-default IDs for this farm
        $hiddenIds = FarmMilkTypeVisibility::where('farm_id', $farmId)
            ->pluck('milk_type_id')
            ->all();

        $milkTypes = MilkType::visibleToFarm($farmId)->get()->map(function (MilkType $mt) use ($hiddenIds) {
            return [
                'id'        => $mt->id,
                'name'      => $mt->name,
                'farm_id'   => $mt->farm_id,
                'is_system' => $mt->farm_id === null,
                'is_hidden' => in_array($mt->id, $hiddenIds, true),
                'is_active' => $mt->is_active,
            ];
        });

        return ApiResponse::success(['milk_types' => $milkTypes]);
    }

    public function storeMilkType(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $farmId = $owner->farm_id;

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
        ]);

        $exists = MilkType::where('farm_id', $farmId)
            ->where('name', $validated['name'])
            ->exists();

        if ($exists) {
            return ApiResponse::error('DUPLICATE_NAME', 'A milk type with this name already exists for your farm.', 409);
        }

        $milkType = MilkType::create([
            'farm_id' => $farmId,
            'name'    => $validated['name'],
        ]);

        return ApiResponse::success(['milk_type' => $this->milkTypePayload($milkType, [])], null, 201);
    }

    public function updateMilkType(Request $request, MilkType $milkType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($milkType->farm_id === null) {
            return ApiResponse::error('FORBIDDEN', 'System defaults cannot be edited.', 403);
        }

        if ($milkType->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Milk type not found.', 404);
        }

        $validated = $request->validate([
            'name'      => ['sometimes', 'string', 'max:100'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if (isset($validated['name']) && $validated['name'] !== $milkType->name) {
            $exists = MilkType::where('farm_id', $owner->farm_id)
                ->where('name', $validated['name'])
                ->where('id', '!=', $milkType->id)
                ->exists();

            if ($exists) {
                return ApiResponse::error('DUPLICATE_NAME', 'A milk type with this name already exists for your farm.', 409);
            }
        }

        $milkType->update($validated);

        return ApiResponse::success(['milk_type' => $this->milkTypePayload($milkType->fresh(), [])]);
    }

    public function destroyMilkType(Request $request, MilkType $milkType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($milkType->farm_id === null) {
            return ApiResponse::error('FORBIDDEN', 'System defaults cannot be deleted.', 403);
        }

        if ($milkType->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Milk type not found.', 404);
        }

        try {
            $milkType->delete();
        } catch (QueryException $e) {
            // MySQL FK constraint violation code
            if (str_contains($e->getCode(), '23000')) {
                return ApiResponse::error(
                    'TYPE_IN_USE',
                    'This milk type is used by a product. Update those products first.',
                    409,
                );
            }
            throw $e;
        }

        return ApiResponse::success(['deleted' => true]);
    }

    public function hideMilkType(Request $request, MilkType $milkType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($milkType->farm_id !== null) {
            return ApiResponse::error('FORBIDDEN', 'Only system defaults can be hidden.', 403);
        }

        FarmMilkTypeVisibility::firstOrCreate([
            'farm_id'      => $owner->farm_id,
            'milk_type_id' => $milkType->id,
        ]);

        return ApiResponse::success(['hidden' => true]);
    }

    public function unhideMilkType(Request $request, MilkType $milkType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($milkType->farm_id !== null) {
            return ApiResponse::error('FORBIDDEN', 'Only system defaults can be unhidden.', 403);
        }

        FarmMilkTypeVisibility::where('farm_id', $owner->farm_id)
            ->where('milk_type_id', $milkType->id)
            ->delete();

        return ApiResponse::success(['hidden' => false]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Container Types
    // ─────────────────────────────────────────────────────────────────────

    public function indexContainerTypes(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $farmId = $owner->farm_id;

        // Hidden system-default IDs for this farm
        $hiddenIds = FarmContainerTypeVisibility::where('farm_id', $farmId)
            ->pluck('container_type_id')
            ->all();

        $containerTypes = ContainerType::with('sizes')
            ->visibleToFarm($farmId)
            ->orderBy('name')
            ->get()
            ->map(function (ContainerType $ct) use ($hiddenIds) {
                return $this->containerTypePayload($ct, $hiddenIds);
            });

        return ApiResponse::success(['container_types' => $containerTypes]);
    }

    public function storeContainerType(StoreContainerTypeRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $farmId = $owner->farm_id;

        $validated = $request->validated();

        // Validate each size is a positive multiple of 0.5
        $invalidSizes = collect($validated['sizes'])->filter(function ($size) {
            return fmod((float) $size / 0.5, 1.0) !== 0.0;
        });

        if ($invalidSizes->isNotEmpty()) {
            return ApiResponse::error(
                'VALIDATION_ERROR',
                'Each size must be a multiple of 0.5 litres (e.g. 0.5, 1.0, 1.5).',
                422,
            );
        }

        $exists = ContainerType::where('farm_id', $farmId)
            ->where('name', $validated['name'])
            ->exists();

        if ($exists) {
            return ApiResponse::error('DUPLICATE_NAME', 'A container type with this name already exists for your farm.', 409);
        }

        $containerType = ContainerType::create([
            'farm_id'   => $farmId,
            'name'      => $validated['name'],
            'is_active' => true,
        ]);

        $uniqueSizes = collect($validated['sizes'])->map(fn ($s) => (float) $s)->unique()->sort()->values();

        foreach ($uniqueSizes as $size) {
            ContainerTypeSize::create([
                'container_type_id' => $containerType->id,
                'size_liters'       => $size,
            ]);
        }

        $containerType->load('sizes');

        return ApiResponse::success(['container_type' => $this->containerTypePayload($containerType, [])], null, 201);
    }

    public function updateContainerType(Request $request, ContainerType $containerType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($containerType->farm_id === null) {
            return ApiResponse::error('FORBIDDEN', 'System defaults cannot be edited.', 403);
        }

        if ($containerType->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Container type not found.', 404);
        }

        $validated = $request->validate([
            'name'      => ['sometimes', 'string', 'max:100'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if (isset($validated['name']) && $validated['name'] !== $containerType->name) {
            $exists = ContainerType::where('farm_id', $owner->farm_id)
                ->where('name', $validated['name'])
                ->where('id', '!=', $containerType->id)
                ->exists();

            if ($exists) {
                return ApiResponse::error('DUPLICATE_NAME', 'A container type with this name already exists for your farm.', 409);
            }
        }

        $containerType->update(array_filter($validated, fn ($v) => $v !== null));

        return ApiResponse::success([
            'container_type' => $this->containerTypePayload($containerType->fresh(['sizes']), []),
        ]);
    }

    public function destroyContainerType(Request $request, ContainerType $containerType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($containerType->farm_id === null) {
            return ApiResponse::error('FORBIDDEN', 'System defaults cannot be deleted.', 403);
        }

        if ($containerType->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Container type not found.', 404);
        }

        $inUse = Product::where('container_type_id', $containerType->id)->where('is_active', true)->exists();

        if ($inUse) {
            return ApiResponse::error(
                'TYPE_IN_USE',
                'This container type is used by an active product. Update those products first.',
                422,
            );
        }

        try {
            $containerType->delete();
        } catch (QueryException $e) {
            if (str_contains($e->getCode(), '23000')) {
                return ApiResponse::error(
                    'TYPE_IN_USE',
                    'This container type is used by a product. Update those products first.',
                    409,
                );
            }
            throw $e;
        }

        return ApiResponse::success(['deleted' => true]);
    }

    public function hideContainerType(Request $request, ContainerType $containerType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($containerType->farm_id !== null) {
            return ApiResponse::error('FORBIDDEN', 'Only system defaults can be hidden.', 403);
        }

        FarmContainerTypeVisibility::firstOrCreate([
            'farm_id'           => $owner->farm_id,
            'container_type_id' => $containerType->id,
        ]);

        return ApiResponse::success(['hidden' => true]);
    }

    public function unhideContainerType(Request $request, ContainerType $containerType): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($containerType->farm_id !== null) {
            return ApiResponse::error('FORBIDDEN', 'Only system defaults can be unhidden.', 403);
        }

        FarmContainerTypeVisibility::where('farm_id', $owner->farm_id)
            ->where('container_type_id', $containerType->id)
            ->delete();

        return ApiResponse::success(['hidden' => false]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Private payload helpers
    // ─────────────────────────────────────────────────────────────────────

    private function productPayload(Product $product): array
    {
        $ct = $product->containerType;
        $sizes = $ct && $ct->relationLoaded('sizes')
            ? $ct->sizes->map(fn ($s) => (float) $s->size_liters)->sort()->values()->all()
            : [];

        return [
            'id'   => $product->id,
            'name' => $product->name,
            'milk_type' => $product->milkType ? [
                'id'   => $product->milkType->id,
                'name' => $product->milkType->name,
            ] : null,
            'container_type' => $ct ? [
                'id'    => $ct->id,
                'name'  => $ct->name,
                'sizes' => $sizes,
            ] : null,
            'rate' => $product->rate,
        ];
    }

    private function milkTypePayload(MilkType $milkType, array $hiddenIds): array
    {
        return [
            'id'        => $milkType->id,
            'name'      => $milkType->name,
            'farm_id'   => $milkType->farm_id,
            'is_system' => $milkType->farm_id === null,
            'is_hidden' => in_array($milkType->id, $hiddenIds, true),
            'is_active' => $milkType->is_active,
        ];
    }

    private function containerTypePayload(ContainerType $containerType, array $hiddenIds): array
    {
        $sizes = $containerType->relationLoaded('sizes')
            ? $containerType->sizes->map(fn ($s) => (float) $s->size_liters)->values()->all()
            : [];

        return [
            'id'        => $containerType->id,
            'name'      => $containerType->name,
            'is_system' => $containerType->farm_id === null,
            'is_hidden' => in_array($containerType->id, $hiddenIds, true),
            'is_active' => $containerType->is_active,
            'sizes'     => $sizes,
        ];
    }
}
