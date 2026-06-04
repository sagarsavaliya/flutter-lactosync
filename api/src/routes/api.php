<?php

use App\Http\Controllers\Api\V1\HealthController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/health', HealthController::class);

    Route::prefix('auth')->group(function () {
        Route::post('/login', fn () => response()->json([
            'success' => false,
            'error' => ['code' => 'NOT_IMPLEMENTED', 'message' => 'Login API coming soon.'],
        ], 501));

        Route::post('/forgot-pin/send-otp', fn () => response()->json([
            'success' => false,
            'error' => ['code' => 'NOT_IMPLEMENTED', 'message' => 'WhatsApp OTP API coming soon.'],
        ], 501));

        Route::post('/forgot-pin/verify-otp', fn () => response()->json([
            'success' => false,
            'error' => ['code' => 'NOT_IMPLEMENTED', 'message' => 'OTP verify API coming soon.'],
        ], 501));

        Route::post('/forgot-pin/reset', fn () => response()->json([
            'success' => false,
            'error' => ['code' => 'NOT_IMPLEMENTED', 'message' => 'PIN reset API coming soon.'],
        ], 501));
    });
});
