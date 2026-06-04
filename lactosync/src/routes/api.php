<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\OnboardingController;
use App\Http\Controllers\Api\V1\OwnerBillingController;
use App\Http\Controllers\Api\V1\OwnerController;
use App\Http\Controllers\Api\V1\OwnerProductTypesController;
use App\Http\Controllers\Api\V1\OwnerSettingsController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    $otpSendThrottle = app()->environment('local') ? 'throttle:30,1' : 'throttle:3,60';

    Route::get('/health', HealthController::class);

    Route::prefix('auth')->group(function () use ($otpSendThrottle) {
        Route::post('/signup/send-otp', [AuthController::class, 'signupSendOtp'])
            ->middleware($otpSendThrottle);
        Route::post('/signup/verify-otp', [AuthController::class, 'signupVerifyOtp'])
            ->middleware('throttle:10,1');
        Route::post('/signup/complete', [AuthController::class, 'signupComplete'])
            ->middleware('throttle:5,1');

        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/forgot-pin/send-otp', [AuthController::class, 'sendOtp'])
            ->middleware($otpSendThrottle);
        Route::post('/forgot-pin/verify-otp', [AuthController::class, 'verifyOtp'])
            ->middleware('throttle:10,1');
        Route::post('/forgot-pin/reset', [AuthController::class, 'resetPin'])
            ->middleware('throttle:5,1');
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::prefix('onboarding')->group(function () {
            Route::get('/status', [OnboardingController::class, 'status']);
            Route::patch('/farm', [OnboardingController::class, 'updateFarm']);
            Route::get('/products', [OnboardingController::class, 'products']);
            Route::post('/products', [OnboardingController::class, 'storeProduct']);
            Route::post('/products/batch', [OnboardingController::class, 'storeProductsBatch']);
            Route::get('/customers', [OnboardingController::class, 'customers']);
            Route::post('/customers', [OnboardingController::class, 'storeCustomer']);
            Route::post('/subscriptions', [OnboardingController::class, 'storeSubscription']);
            Route::post('/subscriptions/skip', [OnboardingController::class, 'skipSubscription']);
        });

        Route::prefix('owner')->group(function () {
            Route::get('/dashboard', [OwnerController::class, 'dashboard']);
            Route::get('/activities', [OwnerController::class, 'activities']);
            Route::post('/activities/{activityLog}/restore', [OwnerController::class, 'restoreActivity']);
            Route::get('/customers', [OwnerController::class, 'customers']);
            Route::get('/customers/{customer}', [OwnerController::class, 'customerDetail']);
            Route::patch('/customers/{customer}', [OwnerController::class, 'updateCustomer']);
            Route::delete('/customers/{customer}', [OwnerController::class, 'destroyCustomer']);
            Route::post('/customers/{customer}/milk-log/send', [OwnerController::class, 'sendMilkLog']);
            Route::get('/customers/{customer}/delivery-logs', [OwnerController::class, 'deliveryLogGrid']);
            Route::patch('/customers/{customer}/delivery-logs', [OwnerController::class, 'updateDeliveryLogs']);
            Route::post('/subscriptions', [OwnerController::class, 'storeSubscription']);
            Route::delete('/subscriptions/{subscription}', [OwnerController::class, 'destroySubscription']);
            Route::patch('/subscriptions/{subscription}/lines/{line}', [OwnerController::class, 'updateSubscriptionLine']);
            Route::delete('/subscriptions/{subscription}/lines/{line}', [OwnerController::class, 'destroySubscriptionLine']);
            Route::get('/daily-orders', [OwnerController::class, 'dailyOrders']);
            Route::post('/daily-orders/generate', [OwnerController::class, 'generateDailyOrders']);
            Route::patch('/daily-orders/{dailyOrderLog}', [OwnerController::class, 'updateDailyOrder']);
            Route::get('/invoices', [OwnerController::class, 'invoices']);
            Route::post('/invoices/generate', [OwnerBillingController::class, 'generateInvoice']);
            Route::get('/invoices/{invoice}', [OwnerController::class, 'invoiceDetail']);
            Route::post('/invoices/{invoice}/send', [OwnerBillingController::class, 'sendInvoice']);
            Route::post('/invoices/send-bulk', [OwnerBillingController::class, 'sendBulk']);
            Route::get('/notifications', [OwnerBillingController::class, 'notifications']);
            Route::post('/notifications/read', [OwnerBillingController::class, 'markNotificationsRead']);
            Route::post('/device-token', [OwnerBillingController::class, 'registerDeviceToken']);
            Route::get('/payments', [OwnerController::class, 'payments']);
            Route::post('/payments', [OwnerBillingController::class, 'recordPayment']);
            Route::post('/payments/share-upi-qr', [OwnerBillingController::class, 'shareUpiQr']);
            Route::get('/settings', [OwnerSettingsController::class, 'show']);
            Route::patch('/settings', [OwnerSettingsController::class, 'update']);
            Route::patch('/products/{product}', [OwnerSettingsController::class, 'updateProduct']);
            Route::delete('/products/{product}', [OwnerSettingsController::class, 'destroyProduct']);

            // Dynamic product types (milk + container)
            Route::get('/milk-types', [OwnerProductTypesController::class, 'indexMilkTypes']);
            Route::post('/milk-types', [OwnerProductTypesController::class, 'storeMilkType']);
            Route::patch('/milk-types/{milkType}', [OwnerProductTypesController::class, 'updateMilkType']);
            Route::delete('/milk-types/{milkType}', [OwnerProductTypesController::class, 'destroyMilkType']);
            Route::post('/milk-types/{milkType}/hide', [OwnerProductTypesController::class, 'hideMilkType']);
            Route::delete('/milk-types/{milkType}/hide', [OwnerProductTypesController::class, 'unhideMilkType']);

            Route::get('/container-types', [OwnerProductTypesController::class, 'indexContainerTypes']);
            Route::post('/container-types', [OwnerProductTypesController::class, 'storeContainerType']);
            Route::patch('/container-types/{containerType}', [OwnerProductTypesController::class, 'updateContainerType']);
            Route::delete('/container-types/{containerType}', [OwnerProductTypesController::class, 'destroyContainerType']);
            Route::post('/container-types/{containerType}/hide', [OwnerProductTypesController::class, 'hideContainerType']);
            Route::delete('/container-types/{containerType}/hide', [OwnerProductTypesController::class, 'unhideContainerType']);
        });
    });
});
