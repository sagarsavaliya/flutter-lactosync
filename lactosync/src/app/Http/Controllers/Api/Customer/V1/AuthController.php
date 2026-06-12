<?php

namespace App\Http\Controllers\Api\Customer\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Services\WhatsApp\WhatsAppService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Throwable;

class AuthController extends Controller
{
    public function __construct(
        private readonly WhatsAppService $whatsApp,
    ) {}

    /**
     * Send a 6-digit OTP to the customer's WhatsApp number.
     *
     * POST /api/customer/v1/auth/send-otp
     */
    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'contact' => ['required', 'digits:10'],
        ]);

        $customer = Customer::query()
            ->where('contact', $validated['contact'])
            ->first();

        if (! $customer) {
            return ApiResponse::error(
                'NOT_FOUND',
                'No account found for this mobile number.',
                422,
            );
        }

        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        $customer->update([
            'otp'            => Hash::make($otp),
            'otp_expires_at' => now()->addMinutes(10),
        ]);

        // Fire-and-forget: log warning on failure but do not block the customer.
        try {
            $this->whatsApp->sendOtp($customer->contact, $otp);
        } catch (Throwable $e) {
            Log::warning('Customer OTP WhatsApp send failed', [
                'contact' => $customer->contact,
                'error'   => $e->getMessage(),
            ]);
        }

        return ApiResponse::success(['message' => 'OTP sent.']);
    }

    /**
     * Verify the OTP and mark the mobile as verified.
     *
     * POST /api/customer/v1/auth/verify-otp
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'contact' => ['required', 'string'],
            'otp'     => ['required', 'string'],
        ]);

        $customer = Customer::query()
            ->where('contact', $validated['contact'])
            ->first();

        if (! $customer) {
            return ApiResponse::error(
                'NOT_FOUND',
                'No account found for this mobile number.',
                422,
            );
        }

        if ($customer->otp_expires_at === null || $customer->otp_expires_at->isPast()) {
            return ApiResponse::error(
                'OTP_EXPIRED',
                'OTP has expired. Please request a new one.',
                422,
            );
        }

        if (! Hash::check($validated['otp'], $customer->otp)) {
            return ApiResponse::error(
                'INVALID_OTP',
                'Invalid OTP.',
                422,
            );
        }

        $customer->mobile_verified_at = now();
        $customer->otp                = null;
        $customer->otp_expires_at     = null;
        $customer->save();

        return ApiResponse::success([
            'verified' => true,
            'contact'  => $customer->contact,
        ]);
    }

    /**
     * Set the customer's 4-digit PIN and issue a Sanctum token.
     * Requires prior OTP verification (mobile_verified_at must be set).
     *
     * POST /api/customer/v1/auth/set-pin
     */
    public function setPin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'contact' => ['required', 'string'],
            'pin'     => ['required', 'string', 'digits:4'],
        ]);

        $customer = Customer::query()
            ->where('contact', $validated['contact'])
            ->first();

        if (! $customer) {
            return ApiResponse::error(
                'NOT_FOUND',
                'No account found for this mobile number.',
                422,
            );
        }

        if ($customer->mobile_verified_at === null) {
            return ApiResponse::error(
                'NOT_VERIFIED',
                'Mobile number not verified. Please complete OTP verification first.',
                422,
            );
        }

        // The 'hashed' cast on the Customer model will bcrypt the PIN automatically.
        $customer->update(['pin' => $validated['pin']]);

        // Revoke all existing tokens and issue a fresh one.
        $customer->tokens()->delete();
        $token = $customer->createToken('customer-app', ['customer'])->plainTextToken;

        $customer->update(['last_login_at' => now()]);

        return ApiResponse::success(['token' => $token]);
    }

    /**
     * Authenticate with contact + PIN and issue a Sanctum token.
     *
     * POST /api/customer/v1/auth/login
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'contact' => ['required', 'string'],
            'pin'     => ['required', 'digits:4'],
        ]);

        $customer = Customer::query()
            ->where('contact', $validated['contact'])
            ->first();

        if (! $customer) {
            return ApiResponse::error(
                'INVALID_CREDENTIALS',
                'Invalid mobile number or PIN.',
                401,
            );
        }

        if ($customer->pin === null) {
            return ApiResponse::error(
                'PIN_NOT_SET',
                'Please set your PIN first.',
                422,
            );
        }

        if (! Hash::check($validated['pin'], $customer->pin)) {
            return ApiResponse::error(
                'INVALID_CREDENTIALS',
                'Invalid mobile number or PIN.',
                401,
            );
        }

        $customer->update(['last_login_at' => now()]);
        $token = $customer->createToken('customer-app', ['customer'])->plainTextToken;

        return ApiResponse::success(['token' => $token]);
    }
}
