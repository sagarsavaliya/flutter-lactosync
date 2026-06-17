<?php

namespace App\Http\Controllers\Api\Customer\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Services\Notifications\CustomerAppOwnerAlertService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        $activeSubscriptions = $customer->subscriptions()
            ->where('status', 'active')
            ->with(['lines.product'])
            ->get()
            ->flatMap(function ($subscription) {
                return $subscription->lines->map(function ($line) {
                    return [
                        'product_name' => $line->product?->name,
                        'shift'        => $line->shift?->value ?? $line->shift,
                        'qty'          => $line->quantity,
                    ];
                });
            })
            ->values()
            ->all();

        $data = [
            'first_name'      => $customer->first_name,
            'last_name'       => $customer->last_name,
            'contact'         => $customer->contact,
            'address_line'    => $customer->address_line,
            'area'            => $customer->area,
            'landmark'        => $customer->landmark,
            'city'            => $customer->city,
            'state'           => $customer->state,
            'zip'             => $customer->zip,
            'whatsapp_enabled' => $customer->whatsapp_enabled,
            'active_subscriptions' => $activeSubscriptions,
        ];

        return ApiResponse::success(['profile' => $data]);
    }

    public function update(Request $request, CustomerAppOwnerAlertService $ownerAlerts): JsonResponse
    {
        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        $addressFields = ['address_line', 'area', 'landmark', 'city', 'state', 'zip'];
        $hasAddressChange = collect($addressFields)->some(fn ($field) => $request->has($field));

        if ($hasAddressChange) {
            if (
                $customer->last_address_change_at !== null &&
                now()->diffInHours($customer->last_address_change_at) < 24
            ) {
                return ApiResponse::error(
                    'ADDRESS_RATE_LIMITED',
                    'Address can only be updated once every 24 hours.',
                    422
                );
            }
        }

        $allowed = ['first_name', 'last_name', 'address_line', 'area', 'landmark', 'city', 'state', 'zip', 'whatsapp_enabled'];
        $validated = $request->only($allowed);

        $customer->fill($validated);

        if ($hasAddressChange) {
            $customer->last_address_change_at = now();
        }

        $customer->save();

        if ($hasAddressChange) {
            $ownerAlerts->addressUpdated($customer, $customer->shortAddress());
        }

        $updatedFields = $customer->only($allowed);

        return ApiResponse::success(['profile' => $updatedFields]);
    }

    public function farmContact(Request $request): JsonResponse
    {
        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        $farm = Farm::find($customer->farm_id);
        $farmOwner = FarmOwner::where('farm_id', $customer->farm_id)->first();

        return ApiResponse::success([
            'farm_name'        => $farm?->name,
            'owner_first_name' => $farmOwner?->first_name,
            'owner_last_name'  => $farmOwner?->last_name,
            'owner_mobile'     => $farmOwner?->mobile,
            'upi_vpa'          => $farm?->upi_vpa,
            'upi_payee_name'   => $farm?->upi_payee_name,
        ]);
    }
}
