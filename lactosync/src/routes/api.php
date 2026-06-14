<?php

use App\Http\Controllers\Api\Admin\V1\AuthController as AdminAuthController;
use App\Http\Controllers\Api\Customer\V1\AuthController as CustomerAuthController;
use App\Http\Controllers\Api\Customer\V1\DashboardController as CustomerDashboardController;
use App\Http\Controllers\Api\Customer\V1\OrderController as CustomerOrderController;
use App\Http\Controllers\Api\Customer\V1\BillingController as CustomerBillingController;
use App\Http\Controllers\Api\Customer\V1\ProfileController as CustomerProfileController;
use App\Http\Controllers\Api\Customer\V1\VacationController as CustomerVacationController;
use App\Http\Controllers\Api\Admin\V1\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\Admin\V1\PaymentController as AdminPaymentController;
use App\Http\Controllers\Api\Admin\V1\PlanController as AdminPlanController;
use App\Http\Controllers\Api\Admin\V1\CouponController as AdminCouponController;
use App\Http\Controllers\Api\Admin\V1\TenantController as AdminTenantController;
use App\Http\Controllers\Api\Admin\V1\TenantModuleController as AdminTenantModuleController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DeliveryBoyAuthController;
use App\Http\Controllers\Api\V1\DeliveryBoyController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\OnboardingController;
use App\Http\Controllers\Api\V1\OwnerBillingController;
use App\Http\Controllers\Api\V1\OwnerController;
use App\Http\Controllers\Api\V1\OwnerDeliveryController;
use App\Http\Controllers\Api\V1\OwnerModuleController;
use App\Http\Controllers\Api\V1\OwnerProductTypesController;
use App\Http\Controllers\Api\V1\OwnerSettingsController;
use Illuminate\Support\Facades\Route;

// ---------------------------------------------------------------------------
// Admin API — Tenant Admin Web App
// Completely separate from the owner API. The 'auth:admin' guard ensures
// a farm-owner Sanctum token cannot access any of these routes.
// ---------------------------------------------------------------------------
Route::prefix('admin/v1')->group(function (): void {
    Route::post('auth/login', [AdminAuthController::class, 'login'])
        ->middleware('throttle:10,1');  // 10 attempts per IP per minute

    Route::middleware('auth:admin')->group(function (): void {
        Route::post('auth/logout', [AdminAuthController::class, 'logout']);

        // Dashboard
        Route::get('dashboard', [AdminDashboardController::class, 'index']);

        // Tenant management (T1-10)
        Route::get('tenants', [AdminTenantController::class, 'index']);
        Route::get('tenants/{id}', [AdminTenantController::class, 'show']);
        Route::post('tenants/{id}/plan-assign', [AdminTenantController::class, 'planAssign']);
        Route::post('tenants/{id}/plan-change', [AdminTenantController::class, 'planChange']);
        Route::post('tenants/{id}/plan-pause', [AdminTenantController::class, 'planPause']);
        Route::post('tenants/{id}/plan-resume', [AdminTenantController::class, 'planResume']);
        Route::put('tenants/{id}/profile', [AdminTenantController::class, 'updateProfile']);

        // Plan management (T1-11)
        Route::get('plans', [AdminPlanController::class, 'index']);
        Route::post('plans', [AdminPlanController::class, 'store']);
        Route::put('plans/{plan}', [AdminPlanController::class, 'update']);
        Route::post('plans/{plan}/archive', [AdminPlanController::class, 'archive']);
        Route::post('plans/{plan}/unarchive', [AdminPlanController::class, 'unarchive']);

        // Payment tracking (T1-12)
        Route::post('tenants/{id}/payments', [AdminPaymentController::class, 'store']);
        Route::get('tenants/{id}/payments', [AdminPaymentController::class, 'indexForTenant']);
        Route::get('payments', [AdminPaymentController::class, 'index']);
        Route::put('payments/{id}', [AdminPaymentController::class, 'update']);
        Route::delete('payments/{id}', [AdminPaymentController::class, 'destroy']);

        // Coupon / promotional offers
        Route::get('coupons', [AdminCouponController::class, 'index']);
        Route::post('coupons', [AdminCouponController::class, 'store']);
        Route::patch('coupons/{id}/toggle-active', [AdminCouponController::class, 'toggleActive']);
        Route::post('tenants/{id}/apply-coupon', [AdminCouponController::class, 'applyToTenant']);

        // Tenant module overrides (S8-04)
        Route::get('tenants/{id}/modules', [AdminTenantModuleController::class, 'show']);
        Route::put('tenants/{id}/modules', [AdminTenantModuleController::class, 'update']);
    });
});

// ---------------------------------------------------------------------------
// Owner / farm API (unchanged)
// ---------------------------------------------------------------------------
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

        Route::prefix('owner')->middleware('check.subscription')->group(function () {
            Route::get('/modules', [OwnerModuleController::class, 'index']);
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
            Route::get('/products', [OwnerProductTypesController::class, 'indexProducts']);
            Route::post('/products', [OwnerProductTypesController::class, 'storeProduct']);
            Route::patch('/products/{product}', [OwnerSettingsController::class, 'updateProduct']);
            Route::delete('/products/{product}', [OwnerSettingsController::class, 'destroyProduct']);
            Route::get('/pincode/{pincode}', [OwnerSettingsController::class, 'pincodeLookup']);

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

            // Delivery module (S8-07 through S8-14) — gated by route_delivery module
            Route::middleware('module:route_delivery')->group(function (): void {
                // Delivery boys CRUD
                Route::get('/delivery-boys', [OwnerDeliveryController::class, 'deliveryBoys']);
                Route::post('/delivery-boys', [OwnerDeliveryController::class, 'storeDeliveryBoy']);
                Route::patch('/delivery-boys/{boy}', [OwnerDeliveryController::class, 'updateDeliveryBoy']);
                Route::delete('/delivery-boys/{boy}', [OwnerDeliveryController::class, 'destroyDeliveryBoy']);
                Route::post('/delivery-boys/{boy}/reset-pin', [OwnerDeliveryController::class, 'resetDeliveryBoyPin']);

                // Routes CRUD
                Route::get('/routes', [OwnerDeliveryController::class, 'routes']);
                Route::post('/routes', [OwnerDeliveryController::class, 'storeRoute']);
                Route::patch('/routes/{route}', [OwnerDeliveryController::class, 'updateRoute']);
                Route::delete('/routes/{route}', [OwnerDeliveryController::class, 'destroyRoute']);

                // Route customer assignments
                Route::get('/routes/{route}/customers', [OwnerDeliveryController::class, 'routeCustomers']);
                Route::get('/routes/{route}/available-customers', [OwnerDeliveryController::class, 'availableRouteCustomers']);
                Route::post('/routes/{route}/customers', [OwnerDeliveryController::class, 'addRouteCustomer']);
                Route::delete('/routes/{route}/customers/{assignment}', [OwnerDeliveryController::class, 'removeRouteCustomer']);
                Route::put('/routes/{route}/customers/reorder', [OwnerDeliveryController::class, 'reorderRouteCustomers']);

                // Route-delivery-boy assignments
                Route::get('/routes/{route}/assignments', [OwnerDeliveryController::class, 'routeBoyAssignment']);
                Route::put('/routes/{route}/assignments', [OwnerDeliveryController::class, 'assignRouteDeliveryBoy']);

                // Owner daily route sheet
                Route::get('/route-sheet', [OwnerDeliveryController::class, 'ownerRouteSheet']);

                // Skip delivery
                Route::post('/skip-delivery', [OwnerDeliveryController::class, 'skipDelivery']);
            });
        });
    });
});

// ── Customer App API ──────────────────────────────────────────────────────────
Route::prefix('customer/v1')->group(function (): void {

    // Auth (unauthenticated)
    Route::prefix('auth')->group(function (): void {
        Route::post('send-otp',   [CustomerAuthController::class, 'sendOtp']);
        Route::post('verify-otp', [CustomerAuthController::class, 'verifyOtp']);
        Route::post('set-pin',    [CustomerAuthController::class, 'setPin']);
        Route::post('login',      [CustomerAuthController::class, 'login']);
    });

    // Authenticated customer routes
    Route::middleware('auth:customer')->group(function (): void {
        // CA-03 — Dashboard
        Route::get('dashboard', [CustomerDashboardController::class, 'index']);

        // CA-04 — Order log
        Route::get('orders', [CustomerOrderController::class, 'index']);

        // CA-07 — Qty change (shift-aware lock)
        Route::put('orders/{date}/qty', [CustomerOrderController::class, 'updateQty']);

        // CA-08 — Single-day skip
        Route::post('orders/{date}/skip', [CustomerOrderController::class, 'skip']);

        // CA-05 — Bills + bill image + payments
        Route::get('bills', [CustomerBillingController::class, 'bills']);
        Route::get('bills/{id}/image', [CustomerBillingController::class, 'billImage']);
        Route::get('payments', [CustomerBillingController::class, 'payments']);

        // CA-06 — Profile + farm contact
        Route::get('profile', [CustomerProfileController::class, 'show']);
        Route::put('profile', [CustomerProfileController::class, 'update']);
        Route::get('farm-contact', [CustomerProfileController::class, 'farmContact']);

        // CA-09 — Vacation CRUD
        Route::get('vacation', [CustomerVacationController::class, 'show']);
        Route::post('vacation', [CustomerVacationController::class, 'store']);
        Route::delete('vacation', [CustomerVacationController::class, 'destroy']);
    });
});

// ── Delivery Boy App API ──────────────────────────────────────────────────────
Route::prefix('delivery-boy/v1')->group(function (): void {

    // Auth (unauthenticated)
    Route::prefix('auth')->group(function (): void {
        Route::post('login', [DeliveryBoyAuthController::class, 'login'])
            ->middleware('throttle:10,1');
    });

    // Authenticated delivery boy routes
    Route::middleware('auth:delivery_boy')->group(function (): void {
        Route::post('auth/change-pin', [DeliveryBoyAuthController::class, 'changePin']);
        Route::post('auth/logout',     [DeliveryBoyAuthController::class, 'logout']);

        // S8-12 — Route sheet (packing view)
        Route::get('route-sheet', [DeliveryBoyController::class, 'routeSheet']);

        // S8-13 — Skip delivery
        Route::post('skip-delivery', [DeliveryBoyController::class, 'skipDelivery']);
    });
});
