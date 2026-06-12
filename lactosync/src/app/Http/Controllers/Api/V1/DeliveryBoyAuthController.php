<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * Delivery Boy app authentication.
 *
 * POST /api/delivery-boy/v1/auth/login
 * POST /api/delivery-boy/v1/auth/change-pin   (requires auth:delivery_boy)
 * POST /api/delivery-boy/v1/auth/logout        (requires auth:delivery_boy)
 */
class DeliveryBoyAuthController extends Controller
{
    /**
     * Authenticate with phone + PIN and issue a Sanctum token.
     *
     * POST /api/delivery-boy/v1/auth/login
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
            'pin'   => ['required', 'digits:4'],
        ]);

        $boy = DeliveryBoy::where('phone', $validated['phone'])->first();

        if (! $boy || ! $boy->is_active) {
            return ApiResponse::error('INVALID_CREDENTIALS', 'Invalid phone number or PIN.', 401);
        }

        if ($boy->pin_hash === null) {
            return ApiResponse::error('PIN_NOT_SET', 'PIN has not been set. Ask your manager to reset your PIN.', 422);
        }

        if (! Hash::check($validated['pin'], $boy->pin_hash)) {
            return ApiResponse::error('INVALID_CREDENTIALS', 'Invalid phone number or PIN.', 401);
        }

        $boy->tokens()->delete();
        $token = $boy->createToken('delivery-boy-app', ['delivery_boy'])->plainTextToken;

        return ApiResponse::success([
            'token' => $token,
            'name'  => $boy->name,
        ]);
    }

    /**
     * Change PIN while authenticated.
     *
     * POST /api/delivery-boy/v1/auth/change-pin
     */
    public function changePin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'current_pin' => ['required', 'digits:4'],
            'new_pin'     => ['required', 'digits:4'],
        ]);

        /** @var DeliveryBoy $boy */
        $boy = $request->user();

        if ($boy->pin_hash === null || ! Hash::check($validated['current_pin'], $boy->pin_hash)) {
            return ApiResponse::error('INVALID_PIN', 'Current PIN is incorrect.', 401);
        }

        $boy->update(['pin_hash' => Hash::make($validated['new_pin'])]);

        return ApiResponse::success(['message' => 'PIN updated.']);
    }

    /**
     * Revoke the current token.
     *
     * POST /api/delivery-boy/v1/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return ApiResponse::success(['message' => 'Logged out.']);
    }
}
