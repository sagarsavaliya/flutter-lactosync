<?php

namespace App\Http\Controllers\Api\Customer\V1;

use App\Services\WhatsApp\CustomerWhatsAppNotifier;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VacationController
{
    public function show(Request $request): JsonResponse
    {
        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        return ApiResponse::success([
            'vacation_start' => $customer->vacation_start?->format('Y-m-d'),
            'vacation_end'   => $customer->vacation_end?->format('Y-m-d'),
        ]);
    }

    public function store(Request $request, CustomerWhatsAppNotifier $notifier): JsonResponse
    {
        $request->validate([
            'vacation_start' => ['required', 'date', 'after:today'],
            'vacation_end'   => ['required', 'date', 'after_or_equal:vacation_start'],
        ]);

        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        // Constraint 1: vacation_start must be strictly in the future (already enforced by after:today).
        // Constraint 2: vacation_end >= vacation_start (already enforced by after_or_equal:vacation_start).
        // Constraint 3: cannot set while a vacation is already active.
        if ($customer->vacation_start !== null && $customer->vacation_end !== null) {
            return ApiResponse::error(
                'VACATION_ALREADY_SET',
                'A vacation is already set. Cancel it before setting a new one.',
                422,
            );
        }

        $vacationStart = $request->input('vacation_start');
        $vacationEnd   = $request->input('vacation_end');

        $customer->vacation_start = $vacationStart;
        $customer->vacation_end   = $vacationEnd;
        $customer->save();

        // Send WhatsApp notification (suppressed inside notifier when whatsapp_enabled = false).
        $farm = $customer->farm;
        $notifier->deliveryPaused(
            $customer,
            $vacationStart,
            $vacationEnd,
            $farm,
        );

        return ApiResponse::success([
            'vacation_start' => $customer->vacation_start->format('Y-m-d'),
            'vacation_end'   => $customer->vacation_end->format('Y-m-d'),
        ]);
    }

    public function destroy(Request $request): JsonResponse
    {
        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        $customer->vacation_start = null;
        $customer->vacation_end   = null;
        $customer->save();

        return ApiResponse::success(['cancelled' => true]);
    }
}
