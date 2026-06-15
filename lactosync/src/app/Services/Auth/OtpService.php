<?php

namespace App\Services\Auth;

use App\Models\DeliveryBoy;
use App\Models\FarmOwner;
use App\Models\OtpRequest;
use App\Services\WhatsApp\WhatsAppService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use RuntimeException;

class OtpService
{
    public const PURPOSE_PIN_RESET = 'pin_reset';

    public const PURPOSE_DELIVERY_BOY_PIN_RESET = 'delivery_boy_pin_reset';

    public const PURPOSE_SIGNUP = 'signup';

    public function __construct(
        private readonly WhatsAppService $whatsApp,
    ) {}

    public function sendSignupOtp(string $firstName, string $lastName, string $mobile): void
    {
        if (FarmOwner::query()->where('mobile', $mobile)->exists()) {
            throw new RuntimeException('This mobile number is already registered. Sign in instead.');
        }

        $this->sendOtp($mobile, self::PURPOSE_SIGNUP, [
            'first_name' => $firstName,
            'last_name' => $lastName,
        ]);
    }

    public function verifySignupOtp(string $mobile, string $otp): string
    {
        $this->verifyOtp($mobile, $otp, self::PURPOSE_SIGNUP);

        $pending = Cache::get($this->signupPendingCacheKey($mobile));

        if (! is_array($pending)) {
            throw new RuntimeException('Signup session expired. Please start again.');
        }

        $signupToken = Str::random(64);
        $ttl = config('lactosync.otp.reset_token_ttl_seconds');

        Cache::put(
            $this->signupTokenCacheKey($signupToken),
            array_merge($pending, ['mobile' => $mobile]),
            $ttl,
        );

        return $signupToken;
    }

    public function consumeSignupToken(string $signupToken): array
    {
        $data = Cache::get($this->signupTokenCacheKey($signupToken));

        if (! is_array($data) || empty($data['mobile'])) {
            throw new RuntimeException('Signup session expired. Please start again.');
        }

        Cache::forget($this->signupTokenCacheKey($signupToken));

        return $data;
    }

    private function sendOtp(string $mobile, string $purpose, array $meta = []): void
    {
        $rateKey = "otp:send:{$mobile}";
        $sends = (int) Cache::get($rateKey, 0);
        $maxSends = config('lactosync.otp.max_sends_per_hour');

        if ($sends >= $maxSends) {
            throw new RuntimeException('Too many OTP requests. Please wait an hour and try again.');
        }

        $length = config('lactosync.otp.length');
        $otp = str_pad((string) random_int(0, (10 ** $length) - 1), $length, '0', STR_PAD_LEFT);
        $ttl = config('lactosync.otp.ttl_seconds');

        OtpRequest::query()->create([
            'mobile' => $mobile,
            'purpose' => $purpose,
            'otp_hash' => Hash::make($otp),
            'expires_at' => now()->addSeconds($ttl),
        ]);

        Cache::put("otp:verify:{$mobile}:{$purpose}", 0, $ttl);
        Cache::put($rateKey, $sends + 1, now()->addHour());

        if ($purpose === self::PURPOSE_SIGNUP) {
            Cache::put($this->signupPendingCacheKey($mobile), $meta, $ttl);
        }

        $this->whatsApp->sendOtp($mobile, $otp);
    }

    private function verifyOtp(string $mobile, string $otp, string $purpose): void
    {
        $attemptKey = "otp:verify:{$mobile}:{$purpose}";
        $attempts = (int) Cache::get($attemptKey, 0);
        $maxAttempts = config('lactosync.otp.max_verify_attempts');

        if ($attempts >= $maxAttempts) {
            throw new RuntimeException('Too many wrong attempts. Request a new OTP.');
        }

        $record = OtpRequest::query()
            ->where('mobile', $mobile)
            ->where('purpose', $purpose)
            ->whereNull('verified_at')
            ->where('expires_at', '>', now())
            ->latest('id')
            ->first();

        if (! $record || ! Hash::check($otp, $record->otp_hash)) {
            Cache::put($attemptKey, $attempts + 1, config('lactosync.otp.ttl_seconds'));
            throw new RuntimeException('The OTP is incorrect or has expired.');
        }

        $record->update(['verified_at' => now()]);
    }

    public function sendPinResetOtp(string $mobile): void
    {
        $owner = FarmOwner::query()->where('mobile', $mobile)->where('is_active', true)->first();

        if (! $owner) {
            throw new RuntimeException('This mobile number is not registered.');
        }

        $this->sendOtp($mobile, self::PURPOSE_PIN_RESET);
    }

    public function verifyPinResetOtp(string $mobile, string $otp): string
    {
        $this->verifyOtp($mobile, $otp, self::PURPOSE_PIN_RESET);

        $resetToken = Str::random(64);
        $ttl = config('lactosync.otp.reset_token_ttl_seconds');

        Cache::put(
            $this->resetTokenCacheKey($resetToken),
            $mobile,
            $ttl,
        );

        return $resetToken;
    }

    public function resetPin(string $mobile, string $resetToken, string $pin): void
    {
        $cachedMobile = Cache::get($this->resetTokenCacheKey($resetToken));

        if ($cachedMobile !== $mobile) {
            throw new RuntimeException('Your reset session expired. Please start again.');
        }

        $owner = FarmOwner::query()->where('mobile', $mobile)->where('is_active', true)->first();

        if (! $owner) {
            throw new RuntimeException('This mobile number is not registered.');
        }

        $owner->update(['pin' => $pin]);
        Cache::forget($this->resetTokenCacheKey($resetToken));
        $owner->tokens()->delete();
    }

    public function sendDeliveryBoyPinResetOtp(string $phone): void
    {
        $boy = DeliveryBoy::query()
            ->where('phone', $phone)
            ->where('is_active', true)
            ->first();

        if (! $boy || $boy->phone === null || $boy->phone === '') {
            throw new RuntimeException('No delivery account found for this phone number.');
        }

        $this->sendOtp($phone, self::PURPOSE_DELIVERY_BOY_PIN_RESET);
    }

    public function verifyDeliveryBoyPinResetOtp(string $phone, string $otp): string
    {
        $this->verifyOtp($phone, $otp, self::PURPOSE_DELIVERY_BOY_PIN_RESET);

        $resetToken = Str::random(64);
        $ttl = config('lactosync.otp.reset_token_ttl_seconds');

        Cache::put(
            $this->deliveryBoyResetTokenCacheKey($resetToken),
            $phone,
            $ttl,
        );

        return $resetToken;
    }

    public function resetDeliveryBoyPin(string $phone, string $resetToken, string $pin): DeliveryBoy
    {
        $cachedPhone = Cache::get($this->deliveryBoyResetTokenCacheKey($resetToken));

        if ($cachedPhone !== $phone) {
            throw new RuntimeException('Your reset session expired. Please start again.');
        }

        $boy = DeliveryBoy::query()
            ->where('phone', $phone)
            ->where('is_active', true)
            ->first();

        if (! $boy) {
            throw new RuntimeException('No delivery account found for this phone number.');
        }

        $boy->update(['pin_hash' => Hash::make($pin)]);
        Cache::forget($this->deliveryBoyResetTokenCacheKey($resetToken));
        $boy->tokens()->delete();

        return $boy;
    }

    private function resetTokenCacheKey(string $token): string
    {
        return 'otp:reset_token:'.$token;
    }

    private function deliveryBoyResetTokenCacheKey(string $token): string
    {
        return 'otp:delivery_boy_reset_token:'.$token;
    }

    private function signupPendingCacheKey(string $mobile): string
    {
        return 'signup:pending:'.$mobile;
    }

    private function signupTokenCacheKey(string $token): string
    {
        return 'signup:token:'.$token;
    }
}
