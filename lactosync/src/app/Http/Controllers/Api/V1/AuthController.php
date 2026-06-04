<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\ResetPinRequest;
use App\Http\Requests\Auth\SendOtpRequest;
use App\Http\Requests\Auth\SignupCompleteRequest;
use App\Http\Requests\Auth\SignupSendOtpRequest;
use App\Http\Requests\Auth\VerifyOtpRequest;
use App\Enums\OnboardingStep;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Services\Auth\OtpService;
use App\Services\Onboarding\OnboardingService;
use App\Support\ApiResponse;
use App\Support\AuthPayload;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use RuntimeException;
use Throwable;

class AuthController extends Controller
{
    public function __construct(
        private readonly OtpService $otpService,
        private readonly OnboardingService $onboarding,
    ) {}

    public function login(LoginRequest $request): JsonResponse
    {
        $owner = FarmOwner::query()
            ->with('farm')
            ->where('mobile', $request->validated('mobile'))
            ->where('is_active', true)
            ->first();

        if (! $owner || ! Hash::check($request->validated('pin'), $owner->pin)) {
            return ApiResponse::error(
                'INVALID_CREDENTIALS',
                'Mobile number or PIN is incorrect.',
                401,
            );
        }

        $owner->forceFill(['last_login_at' => now()])->save();
        $token = $owner->createToken('lactosync_flutter')->plainTextToken;

        return ApiResponse::success(
            AuthPayload::ownerSession($owner, $token, $this->onboarding),
        );
    }

    /** @deprecated Use signup flow instead */
    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();
        $parts = preg_split('/\s+/', trim($data['owner_name']), 2) ?: ['', ''];

        $owner = DB::transaction(function () use ($data, $parts) {
            $farm = Farm::query()->create([
                'name' => $data['farm_name'],
                'subscription_status' => 'active',
                'timezone' => config('lactosync.schedule.timezone', 'Asia/Kolkata'),
                'onboarding_completed_at' => now(),
            ]);

            return FarmOwner::query()->create([
                'farm_id' => $farm->id,
                'first_name' => $parts[0] ?? $data['owner_name'],
                'last_name' => $parts[1] ?? '',
                'name' => $data['owner_name'],
                'mobile' => $data['mobile'],
                'pin' => $data['pin'],
                'is_active' => true,
                'mobile_verified_at' => now(),
                'onboarding_step' => OnboardingStep::Completed,
            ]);
        });

        $owner->load('farm');
        $token = $owner->createToken('lactosync_flutter')->plainTextToken;

        return ApiResponse::success(
            AuthPayload::ownerSession($owner, $token, $this->onboarding),
            null,
            201,
        );
    }

    public function signupSendOtp(SignupSendOtpRequest $request): JsonResponse
    {
        try {
            $this->otpService->sendSignupOtp(
                $request->validated('first_name'),
                $request->validated('last_name'),
                $request->validated('mobile'),
            );
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

    public function signupVerifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        try {
            $signupToken = $this->otpService->verifySignupOtp(
                $request->validated('mobile'),
                $request->validated('otp'),
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('OTP_INVALID', $e->getMessage(), 422);
        }

        return ApiResponse::success([
            'signup_token' => $signupToken,
            'expires_in_seconds' => config('lactosync.otp.reset_token_ttl_seconds'),
        ]);
    }

    public function signupComplete(SignupCompleteRequest $request): JsonResponse
    {
        try {
            $pending = $this->otpService->consumeSignupToken($request->validated('signup_token'));
        } catch (RuntimeException $e) {
            return ApiResponse::error('SIGNUP_EXPIRED', $e->getMessage(), 422);
        }

        if (FarmOwner::query()->where('mobile', $pending['mobile'])->exists()) {
            return ApiResponse::error(
                'MOBILE_TAKEN',
                'This mobile number is already registered. Sign in instead.',
                422,
            );
        }

        $owner = DB::transaction(function () use ($pending, $request) {
            $farm = Farm::query()->create([
                'name' => 'Setup pending',
                'subscription_status' => 'active',
                'timezone' => config('lactosync.schedule.timezone', 'Asia/Kolkata'),
            ]);

            $fullName = trim("{$pending['first_name']} {$pending['last_name']}");

            return FarmOwner::query()->create([
                'farm_id' => $farm->id,
                'first_name' => $pending['first_name'],
                'last_name' => $pending['last_name'],
                'name' => $fullName,
                'mobile' => $pending['mobile'],
                'pin' => $request->validated('pin'),
                'is_active' => true,
                'mobile_verified_at' => now(),
                'onboarding_step' => OnboardingStep::FarmProfile,
            ]);
        });

        $owner->load('farm');
        $token = $owner->createToken('lactosync_flutter')->plainTextToken;

        return ApiResponse::success(
            AuthPayload::ownerSession($owner, $token, $this->onboarding),
            null,
            201,
        );
    }

    public function sendOtp(SendOtpRequest $request): JsonResponse
    {
        try {
            $this->otpService->sendPinResetOtp($request->validated('mobile'));
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

    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        try {
            $resetToken = $this->otpService->verifyPinResetOtp(
                $request->validated('mobile'),
                $request->validated('otp'),
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('OTP_INVALID', $e->getMessage(), 422);
        }

        return ApiResponse::success([
            'reset_token' => $resetToken,
            'expires_in_seconds' => config('lactosync.otp.reset_token_ttl_seconds'),
        ]);
    }

    public function resetPin(ResetPinRequest $request): JsonResponse
    {
        try {
            $this->otpService->resetPin(
                $request->validated('mobile'),
                $request->validated('reset_token'),
                $request->validated('pin'),
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('RESET_FAILED', $e->getMessage(), 422);
        }

        return ApiResponse::success([
            'message' => 'PIN updated. You can sign in with your new PIN.',
        ]);
    }
}
