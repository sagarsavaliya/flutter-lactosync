<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Services\Auth\OtpService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use RuntimeException;
use Throwable;

/**
 * Delivery Boy app authentication.
 *
 * POST /api/delivery-boy/v1/auth/login
 * POST /api/delivery-boy/v1/auth/forgot-pin/send-otp
 * POST /api/delivery-boy/v1/auth/forgot-pin/verify-otp
 * POST /api/delivery-boy/v1/auth/forgot-pin/reset
 * POST /api/delivery-boy/v1/auth/change-pin   (requires auth:delivery_boy)
 * POST /api/delivery-boy/v1/auth/logout        (requires auth:delivery_boy)
 */
class DeliveryBoyAuthController extends Controller
{
    public function __construct(
        private readonly OtpService $otpService,
    ) {}

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
     * Send a WhatsApp OTP to reset a forgotten PIN.
     *
     * POST /api/delivery-boy/v1/auth/forgot-pin/send-otp
     */
    public function sendForgotPinOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'digits:10'],
        ]);

        try {
            $this->otpService->sendDeliveryBoyPinResetOtp($validated['phone']);
        } catch (RuntimeException $e) {
            return ApiResponse::error('OTP_SEND_FAILED', $e->getMessage(), 422);
        } catch (Throwable) {
            return ApiResponse::error(
                'OTP_SEND_FAILED',
                'We could not send the OTP. Please try again.',
                503,
            );
        }

        return ApiResponse::success([
            'message' => 'OTP sent on WhatsApp.',
            'expires_in_seconds' => config('lactosync.otp.ttl_seconds'),
        ]);
    }

    /**
     * Verify the OTP and issue a short-lived reset token.
     *
     * POST /api/delivery-boy/v1/auth/forgot-pin/verify-otp
     */
    public function verifyForgotPinOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'digits:10'],
            'otp'   => ['required', 'string'],
        ]);

        try {
            $resetToken = $this->otpService->verifyDeliveryBoyPinResetOtp(
                $validated['phone'],
                $validated['otp'],
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('OTP_INVALID', $e->getMessage(), 422);
        }

        return ApiResponse::success([
            'reset_token' => $resetToken,
            'expires_in_seconds' => config('lactosync.otp.reset_token_ttl_seconds'),
        ]);
    }

    /**
     * Set a new PIN after OTP verification and sign the delivery boy in.
     *
     * POST /api/delivery-boy/v1/auth/forgot-pin/reset
     */
    public function resetForgotPin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone'        => ['required', 'digits:10'],
            'reset_token'  => ['required', 'string'],
            'pin'          => ['required', 'digits:4'],
            'pin_confirmation' => ['required', 'same:pin'],
        ]);

        try {
            $boy = $this->otpService->resetDeliveryBoyPin(
                $validated['phone'],
                $validated['reset_token'],
                $validated['pin'],
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('RESET_FAILED', $e->getMessage(), 422);
        }

        $token = $boy->createToken('delivery-boy-app', ['delivery_boy'])->plainTextToken;

        return ApiResponse::success([
            'token' => $token,
            'name'  => $boy->name,
            'message' => 'PIN updated. You are now signed in.',
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
