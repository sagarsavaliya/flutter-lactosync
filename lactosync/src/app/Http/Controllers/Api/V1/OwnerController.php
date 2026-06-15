<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\DeliveryShift;
use App\Enums\InvoiceStatus;
use App\Enums\OrderLogStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentType;
use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\Product;
use App\Models\FarmActivityLog;
use App\Models\Subscription;
use App\Models\SubscriptionLine;
use App\Services\Activity\FarmActivityLogger;
use App\Services\Billing\ConsumptionAggregator;
use App\Services\Billing\MonthlyInvoiceGenerator;
use App\Support\BillingGuard;
use App\Http\Requests\Onboarding\StoreSubscriptionRequest;
use App\Services\Operations\DailyOrderLogGenerator;
use App\Services\Operations\DeliveryLogUpdateService;
use App\Services\Operations\MilkLogImageService;
use App\Services\Operations\MilkPreparationSummaryBuilder;
use App\Services\WhatsApp\CustomerWhatsAppNotifier;
use App\Services\WhatsApp\WhatsAppService;
use App\Support\ApiResponse;
use App\Support\DeliveryLogPresenter;
use App\Support\SentLabel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use RuntimeException;

class OwnerController extends Controller
{
    public function __construct(
        private readonly MilkPreparationSummaryBuilder $milkPreparationSummary,
        private readonly FarmActivityLogger $activityLogger,
        private readonly ConsumptionAggregator $consumptionAggregator,
    ) {}

    public function dashboard(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $customers = $owner->farm->customers()->get();
        $onVacation = $customers->filter(fn ($c) => $c->isOnVacation())->count();
        $active = $customers->filter(
            fn ($c) => $c->is_active && ! $c->isOnVacation()
        )->count();
        $inactive = $customers->where('is_active', false)->count();

        $subscriptions = $owner->farm->subscriptions()->get();
        $activeSubs = $subscriptions->where('status', 'active')->count();
        $pausedSubs = $subscriptions->where('status', 'paused')->count();

        $today = Carbon::today()->toDateString();
        $todayOrders = DailyOrderLog::query()
            ->where('farm_id', $owner->farm_id)
            ->whereDate('delivery_date', $today)
            ->get();

        // Wrapped so the dashboard still loads if Sprint OR migrations haven't
        // been run yet (milk_type_id column / container_type_sizes table absent).
        $milkPreparation = null;
        try {
            $products = $owner->farm->products()
                ->with(['milkType', 'containerType.sizes'])
                ->where('is_active', true)
                ->orderBy('name')
                ->get();

            $milkPreparation = $this->milkPreparationSummary->build(
                $todayOrders,
                $products,
                $today,
                $owner->farm_id,
            );
        } catch (\Throwable) {
            // Migration not yet applied — dashboard loads without milk preparation panel.
        }

        return ApiResponse::success([
            'customers' => [
                'total' => $customers->count(),
                'active' => $active,
                'inactive' => $inactive,
                'on_vacation' => $onVacation,
            ],
            'subscriptions' => [
                'total' => $subscriptions->count(),
                'active' => $activeSubs,
                'paused' => $pausedSubs,
            ],
            'today_orders' => [
                'total' => $todayOrders->count(),
                'pending' => $todayOrders->where('status', OrderLogStatus::Pending)->count(),
                'delivered' => $todayOrders->where('status', OrderLogStatus::Delivered)->count(),
                'skipped' => $todayOrders->where('status', OrderLogStatus::Skipped)->count(),
            ],
            'milk_preparation' => $milkPreparation,
        ]);
    }

    public function customers(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $farmId = $owner->farm_id;

        $search = trim((string) $request->query('search', ''));
        $status = (string) $request->query('status', 'all');
        $sort = (string) $request->query('sort', 'name_asc');
        $today = Carbon::today()->toDateString();

        $query = Customer::query()->where('farm_id', $farmId);

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('contact', 'like', "%{$search}%")
                    ->orWhere('address_line', 'like', "%{$search}%")
                    ->orWhere('area', 'like', "%{$search}%");
            });
        }

        if ($status === 'active') {
            $query->where('is_active', true)
                ->where(function ($q) use ($today) {
                    $q->whereNull('vacation_start')
                        ->orWhereNull('vacation_end')
                        ->orWhere('vacation_end', '<', $today)
                        ->orWhere('vacation_start', '>', $today);
                });
        } elseif ($status === 'inactive') {
            $query->where('is_active', false);
        } elseif ($status === 'vacation') {
            $query->whereNotNull('vacation_start')
                ->whereNotNull('vacation_end')
                ->where('vacation_start', '<=', $today)
                ->where('vacation_end', '>=', $today);
        }

        match ($sort) {
            'name_desc' => $query->orderByDesc('first_name')->orderByDesc('last_name'),
            'updated_desc' => $query->orderByDesc('updated_at'),
            'updated_asc' => $query->orderBy('updated_at'),
            default => $query->orderBy('first_name')->orderBy('last_name'),
        };

        $customers = $query
            ->withCount('subscriptionLines as subscription_count')
            ->get();

        $summaryQuery = Customer::query()->where('farm_id', $farmId);
        $summary = [
            'total' => (clone $summaryQuery)->count(),
            'active' => (clone $summaryQuery)
                ->where('is_active', true)
                ->where(function ($q) use ($today) {
                    $q->whereNull('vacation_start')
                        ->orWhereNull('vacation_end')
                        ->orWhere('vacation_end', '<', $today)
                        ->orWhere('vacation_start', '>', $today);
                })
                ->count(),
            'inactive' => (clone $summaryQuery)->where('is_active', false)->count(),
            'on_vacation' => (clone $summaryQuery)
                ->whereNotNull('vacation_start')
                ->whereNotNull('vacation_end')
                ->where('vacation_start', '<=', $today)
                ->where('vacation_end', '>=', $today)
                ->count(),
            'morning' => $this->shiftCustomerSummary($farmId, DeliveryShift::Morning, $today),
            'evening' => $this->shiftCustomerSummary($farmId, DeliveryShift::Evening, $today),
        ];

        return ApiResponse::success([
            'summary' => $summary,
            'customers' => $customers->map(fn ($c) => $this->customerPayload($c)),
        ]);
    }

    public function updateCustomer(Request $request, Customer $customer): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($customer->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        $validated = $request->validate([
            'is_active' => ['sometimes', 'boolean'],
            'delivery_type' => ['sometimes', 'string', Rule::in(['home_delivery', 'walk_in'])],
            'vacation_start' => ['sometimes', 'nullable', 'date'],
            'vacation_end' => ['sometimes', 'nullable', 'date'],
            'first_name' => ['sometimes', 'string', 'max:80'],
            'last_name' => ['sometimes', 'string', 'max:80'],
            'address_line' => ['sometimes', 'nullable', 'string', 'max:255'],
            'area' => ['sometimes', 'nullable', 'string', 'max:120'],
            'landmark' => ['sometimes', 'nullable', 'string', 'max:120'],
            'city' => ['sometimes', 'nullable', 'string', 'max:80'],
            'state' => ['sometimes', 'nullable', 'string', 'max:80'],
            'zip' => ['sometimes', 'nullable', 'digits:6'],
            'contact' => ['sometimes', 'digits:10'],
            'whatsapp_enabled' => ['sometimes', 'boolean'],
            'secondary_contact' => ['sometimes', 'nullable', 'digits:10'],
        ]);

        if (array_key_exists('vacation_end', $validated)
            && array_key_exists('vacation_start', $validated)
            && $validated['vacation_start'] !== null
            && $validated['vacation_end'] !== null
            && Carbon::parse($validated['vacation_end'])->lt(Carbon::parse($validated['vacation_start']))) {
            return ApiResponse::error('INVALID_DATES', 'Vacation end date must be on or after start date.');
        }

        if (isset($validated['is_active']) && $validated['is_active'] === false && $customer->isOnVacation()) {
            return ApiResponse::error(
                'VACATION_ACTIVE',
                'Clear vacation dates before marking customer inactive.',
            );
        }

        // Capture vacation state before mutations so we can detect transitions below
        $wasOnVacation = $customer->vacation_start !== null && $customer->vacation_end !== null;

        if (array_key_exists('vacation_start', $validated)) {
            $customer->vacation_start = $validated['vacation_start'];
        }

        if (array_key_exists('vacation_end', $validated)) {
            $customer->vacation_end = $validated['vacation_end'];
        }

        if (isset($validated['is_active'])) {
            $customer->is_active = $validated['is_active'];

            if (! $validated['is_active']) {
                $customer->vacation_start = null;
                $customer->vacation_end = null;
            }
        }

        foreach ([
            'first_name',
            'last_name',
            'address_line',
            'area',
            'landmark',
            'city',
            'state',
            'zip',
            'contact',
            'whatsapp_enabled',
            'secondary_contact',
            'delivery_type',
        ] as $field) {
            if (array_key_exists($field, $validated)) {
                $customer->{$field} = $validated[$field];
            }
        }

        if ($customer->vacation_start === null && $customer->vacation_end === null) {
            // keep as-is
        } elseif ($customer->vacation_start !== null && $customer->vacation_end !== null) {
            $customer->is_active = true;
        }

        $customer->save();

        // ── WhatsApp notifications ──────────────────────────────────────────
        $owner->loadMissing('farm');
        $notifier = app(CustomerWhatsAppNotifier::class);
        $isNowOnVacation = $customer->vacation_start !== null && $customer->vacation_end !== null;

        if ($isNowOnVacation && ! $wasOnVacation) {
            $notifier->deliveryPaused(
                $customer,
                $customer->vacation_start->toDateString(),
                $customer->vacation_end->toDateString(),
                $owner->farm,
            );
        } elseif (! $isNowOnVacation && $wasOnVacation) {
            $notifier->subscriptionResumed($customer, now()->toDateString(), $owner->farm);
        }
        // ────────────────────────────────────────────────────────────────────

        return ApiResponse::success($this->customerPayload($customer->fresh()));
    }

    public function updateSubscriptionLine(
        Request $request,
        Subscription $subscription,
        SubscriptionLine $line,
    ): JsonResponse {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($subscription->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Subscription not found.', 404);
        }

        if ($line->subscription_id !== $subscription->id) {
            return ApiResponse::error('NOT_FOUND', 'Subscription line not found.', 404);
        }

        $validated = $request->validate([
            'product_id' => [
                'required',
                'integer',
                Rule::exists('products', 'id')->where(
                    fn ($query) => $query->where('farm_id', $owner->farm_id)->where('is_active', true),
                ),
            ],
            'quantity' => ['required', 'numeric', 'min:0.5', 'max:99'],
            'coupon_amount' => ['sometimes', 'numeric', 'min:0'],
            'shift' => ['required', 'string', 'in:morning,evening'],
        ]);

        $product = Product::query()
            ->where('farm_id', $owner->farm_id)
            ->whereKey($validated['product_id'])
            ->where('is_active', true)
            ->firstOrFail();

        $unitRate = (float) $product->rate;
        $coupon = (float) ($validated['coupon_amount'] ?? $line->coupon_amount);

        if ($coupon > $unitRate) {
            return ApiResponse::error('INVALID_COUPON', 'Coupon cannot exceed product rate.');
        }

        $line->update([
            'product_id' => $product->id,
            'quantity' => $validated['quantity'],
            'unit_rate' => $unitRate,
            'coupon_amount' => $coupon,
            'effective_rate' => SubscriptionLine::computeEffectiveRate($unitRate, $coupon),
            'shift' => $validated['shift'],
        ]);

        $line->load('product');

        // WhatsApp notification for quantity / product change
        $customer = $subscription->customer;
        if ($customer !== null) {
            $owner->loadMissing('farm');
            app(CustomerWhatsAppNotifier::class)->qtyChanged(
                $customer,
                $line,
                now()->toDateString(),
                $owner->farm,
            );
        }

        return ApiResponse::success([
            'id' => $line->id,
            'product_id' => $line->product_id,
            'product_name' => $line->product?->name ?? '',
            'quantity' => (float) $line->quantity,
            'unit_rate' => (float) $line->unit_rate,
            'coupon_amount' => (float) $line->coupon_amount,
            'effective_rate' => (float) $line->effective_rate,
            'shift' => $line->shift instanceof \BackedEnum ? $line->shift->value : $line->shift,
            'shift_label' => $line->shift instanceof \BackedEnum ? $line->shift->label() : $line->shift,
        ]);
    }

    public function destroySubscriptionLine(
        Request $request,
        Subscription $subscription,
        SubscriptionLine $line,
    ): JsonResponse {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($subscription->farm_id !== $owner->farm_id || $line->subscription_id !== $subscription->id) {
            return ApiResponse::error('NOT_FOUND', 'Subscription line not found.', 404);
        }

        if ($subscription->lines()->count() <= 1) {
            return ApiResponse::error(
                'LAST_LINE',
                'At least one subscription line is required.',
                409,
            );
        }

        if (BillingGuard::customerHasUnpaidInvoices($subscription->customer_id)) {
            return ApiResponse::error(
                'CUSTOMER_HAS_UNPAID_BILLS',
                'Clear outstanding bills before removing subscriptions.',
                409,
            );
        }

        $line->delete();

        return ApiResponse::success(['deleted' => true]);
    }

    public function storeSubscription(StoreSubscriptionRequest $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $data = $request->validated();

        $customer = $owner->farm->customers()->whereKey($data['customer_id'])->first();
        if (! $customer) {
            return ApiResponse::error('CUSTOMER_NOT_FOUND', 'Customer not found.', 404);
        }

        $subscription = DB::transaction(function () use ($owner, $customer, $data) {
            $subscription = Subscription::query()->create([
                'farm_id' => $owner->farm_id,
                'customer_id' => $customer->id,
                'status' => 'active',
            ]);

            foreach ($data['lines'] as $line) {
                $product = $owner->farm->products()
                    ->whereKey($line['product_id'])
                    ->where('is_active', true)
                    ->firstOrFail();

                $unitRate = (float) $product->rate;
                $coupon = (float) ($line['coupon_amount'] ?? 0);

                SubscriptionLine::query()->create([
                    'subscription_id' => $subscription->id,
                    'product_id' => $product->id,
                    'quantity' => $line['quantity'],
                    'unit_rate' => $unitRate,
                    'coupon_amount' => $coupon,
                    'effective_rate' => SubscriptionLine::computeEffectiveRate($unitRate, $coupon),
                    'shift' => $line['shift'],
                ]);
            }

            return $subscription->load(['lines.product', 'customer']);
        });

        return ApiResponse::success([
            'subscription' => [
                'id' => $subscription->id,
                'status' => $subscription->status,
                'customer_id' => $subscription->customer_id,
                'lines' => $subscription->lines->map(fn ($line) => [
                    'id' => $line->id,
                    'product_id' => $line->product_id,
                    'product_name' => $line->product?->name ?? '',
                    'quantity' => (float) $line->quantity,
                    'shift' => $line->shift instanceof \BackedEnum ? $line->shift->value : $line->shift,
                ]),
            ],
        ], null, 201);
    }

    public function destroySubscription(Request $request, Subscription $subscription): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($subscription->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Subscription not found.', 404);
        }

        if (BillingGuard::customerHasUnpaidInvoices($subscription->customer_id)) {
            return ApiResponse::error(
                'CUSTOMER_HAS_UNPAID_BILLS',
                'Clear outstanding bills before removing subscriptions.',
                409,
            );
        }

        $label = $subscription->customer?->fullName() ?? 'Subscription';
        $subscription->load('lines');

        DB::transaction(function () use ($owner, $subscription, $label) {
            foreach ($subscription->lines as $line) {
                $line->delete();
            }
            $subscription->delete();
            $this->activityLogger->logDeleted(
                $owner,
                'subscription',
                $subscription->id,
                $label,
                ['customer_id' => $subscription->customer_id],
            );
        });

        return ApiResponse::success(['deleted' => true]);
    }

    public function destroyCustomer(Request $request, Customer $customer): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($customer->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        if (BillingGuard::customerHasUnpaidInvoices($customer->id)) {
            return ApiResponse::error(
                'CUSTOMER_HAS_UNPAID_BILLS',
                'This customer has an unpaid bill. Collect payment or generate a final bill first.',
                409,
            );
        }

        $label = $customer->fullName();
        $customer->load('subscriptions');

        DB::transaction(function () use ($owner, $customer, $label) {
            foreach ($customer->subscriptions as $subscription) {
                $subscription->lines()->delete();
                $subscription->delete();
            }
            $customer->delete();
            $this->activityLogger->logDeleted(
                $owner,
                'customer',
                $customer->id,
                $label,
                ['contact' => $customer->contact],
            );
        });

        return ApiResponse::success(['deleted' => true]);
    }

    public function activities(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $items = FarmActivityLog::query()
            ->where('farm_id', $owner->farm_id)
            ->orderByDesc('created_at')
            ->limit(200)
            ->get()
            ->map(fn (FarmActivityLog $log) => [
                'id' => $log->id,
                'action' => $log->action,
                'entity_type' => $log->entity_type,
                'entity_id' => $log->entity_id,
                'entity_label' => $log->entity_label,
                'meta' => $log->meta,
                'created_at' => $log->created_at?->toIso8601String(),
                'can_restore' => $log->action === 'deleted'
                    && in_array($log->entity_type, ['customer', 'subscription'], true),
            ]);

        return ApiResponse::success(['activities' => $items]);
    }

    public function restoreActivity(Request $request, FarmActivityLog $activityLog): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($activityLog->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Activity not found.', 404);
        }

        try {
            $this->activityLogger->restore($owner, $activityLog);
        } catch (RuntimeException $e) {
            return ApiResponse::error('RESTORE_FAILED', $e->getMessage(), 422);
        }

        return ApiResponse::success(['restored' => true]);
    }

    public function sendMilkLog(
        Request $request,
        Customer $customer,
        MilkLogImageService $imageService,
        WhatsAppService $whatsApp,
    ): JsonResponse {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        if ($customer->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        if (! $customer->whatsapp_enabled) {
            return ApiResponse::error('WHATSAPP_DISABLED', 'Customer does not have WhatsApp enabled.', 422);
        }

        $validated = $request->validate([
            'billing_month' => ['required', 'date_format:Y-m'],
            'subscription_line_id' => ['sometimes', 'integer'],
        ]);

        $billingMonth = $validated['billing_month'];
        $logsQuery = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('billing_month', $billingMonth)
            ->whereIn('status', DeliveryLogPresenter::billableStatuses())
            ->orderBy('delivery_date');

        $line = null;
        if (isset($validated['subscription_line_id'])) {
            $line = SubscriptionLine::query()
                ->whereKey($validated['subscription_line_id'])
                ->whereHas('subscription', fn ($q) => $q
                    ->where('customer_id', $customer->id)
                    ->where('farm_id', $owner->farm_id))
                ->with('product')
                ->first();

            if ($line === null) {
                return ApiResponse::error('NOT_FOUND', 'Subscription line not found.', 404);
            }

            $logsQuery->where('subscription_line_id', $line->id);
        }

        $logs = $logsQuery->get();
        if ($logs->isEmpty()) {
            return ApiResponse::error('NO_LOGS', 'No delivery logs found for this month.', 422);
        }

        try {
            $imagePath = $imageService->generate(
                $customer,
                $owner->farm,
                $owner,
                $billingMonth,
                $logs,
                $line,
            );

            $monthLabel  = Carbon::createFromFormat('Y-m', $billingMonth)->format('F Y');
            $productName = $line?->product?->name ?? 'All products';
            $shiftLabel  = $line
                ? ($line->shift instanceof \BackedEnum ? $line->shift->label() : (string) $line->shift)
                : 'Morning & Evening';
            $monthStart  = Carbon::createFromFormat('Y-m', $billingMonth)->startOfMonth()->format('d M');
            $monthEnd    = Carbon::createFromFormat('Y-m', $billingMonth)->endOfMonth()->format('d M Y');
            $period      = "{$monthStart} – {$monthEnd}";

            // Send log image as the template header — one message instead of two
            $whatsApp->sendTemplateWithImageHeader(
                $customer->contact,
                config('services.whatsapp.template_order_log', 'lacto_sync_order_log'),
                $imagePath,
                [
                    $customer->fullName(),
                    $monthLabel,
                    $productName,
                    $shiftLabel,
                    $period,
                    $owner->farm->name,
                ],
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('SEND_FAILED', $e->getMessage(), 422);
        }

        return ApiResponse::success(['sent' => true]);
    }

    public function updateDeliveryLogs(
        Request $request,
        Customer $customer,
        DeliveryLogUpdateService $updateService,
    ): JsonResponse {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($customer->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        $validated = $request->validate([
            'billing_month' => ['required', 'date_format:Y-m'],
            'subscription_line_id' => ['required', 'integer'],
            'entries' => ['required', 'array', 'min:1'],
            'entries.*.date' => ['required', 'date'],
            'entries.*.morning' => ['nullable', 'numeric', 'min:0', 'max:99'],
            'entries.*.evening' => ['nullable', 'numeric', 'min:0', 'max:99'],
        ]);

        $line = SubscriptionLine::query()
            ->whereKey($validated['subscription_line_id'])
            ->whereHas('subscription', fn ($q) => $q
                ->where('customer_id', $customer->id)
                ->where('farm_id', $owner->farm_id))
            ->with(['product', 'subscription'])
            ->first();

        if ($line === null) {
            return ApiResponse::error('NOT_FOUND', 'Subscription line not found.', 404);
        }

        try {
            $updateService->updateLineLogs(
                $owner->farm,
                $customer,
                $line,
                $validated['billing_month'],
                $validated['entries'],
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('UPDATE_FAILED', $e->getMessage(), 422);
        }

        return ApiResponse::success([
            'updated' => true,
            'grid' => $updateService->editableGrid($customer, $line, $validated['billing_month']),
        ]);
    }

    public function deliveryLogGrid(
        Request $request,
        Customer $customer,
        DeliveryLogUpdateService $updateService,
    ): JsonResponse {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($customer->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        $validated = $request->validate([
            'billing_month' => ['required', 'date_format:Y-m'],
            'subscription_line_id' => ['required', 'integer'],
        ]);

        $line = SubscriptionLine::query()
            ->whereKey($validated['subscription_line_id'])
            ->whereHas('subscription', fn ($q) => $q
                ->where('customer_id', $customer->id)
                ->where('farm_id', $owner->farm_id))
            ->first();

        if ($line === null) {
            return ApiResponse::error('NOT_FOUND', 'Subscription line not found.', 404);
        }

        return ApiResponse::success([
            'grid' => $updateService->editableGrid(
                $customer,
                $line,
                $validated['billing_month'],
            ),
        ]);
    }

    public function generateDailyOrders(Request $request, DailyOrderLogGenerator $generator): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $validated = $request->validate([
            'date' => ['required', 'date'],
            'shift' => ['required', Rule::in(['morning', 'evening'])],
        ]);

        $date = Carbon::parse($validated['date'], config('lactosync.schedule.timezone', 'Asia/Kolkata'))->startOfDay();
        $shift = DeliveryShift::from($validated['shift']);
        $created = $generator->generateForFarm($owner->farm, $date, $shift);

        return ApiResponse::success([
            'date' => $date->toDateString(),
            'shift' => $shift->value,
            'created' => $created,
        ]);
    }

    public function customerDetail(Request $request, Customer $customer): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($customer->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        $billingMonth = (string) $request->query(
            'billing_month',
            Carbon::now()->format('Y-m'),
        );

        $customer->load([
            'subscriptions' => fn ($q) => $q->with(['lines.product'])->orderBy('id'),
        ]);

        $monthLogs = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('billing_month', $billingMonth)
            ->whereIn('status', DeliveryLogPresenter::billableStatuses())
            ->orderBy('delivery_date')
            ->get();

        $through = Carbon::today();
        $subscriptions = $customer->subscriptions->map(function (Subscription $subscription) use ($monthLogs, $billingMonth, $through) {
            $subLogs = $monthLogs->where('subscription_id', $subscription->id);
            $dailyOrders = DeliveryLogPresenter::fullMonthDailyOrdersTable($subLogs, $billingMonth, $through);

            return [
                'id' => $subscription->id,
                'status' => $subscription->status,
                'lines' => $subscription->lines->map(function ($line) use ($subLogs, $billingMonth, $through) {
                    $lineLogs = DeliveryLogPresenter::logsForSubscriptionLine($subLogs, $line);

                    return [
                        'id' => $line->id,
                        'product_id' => $line->product_id,
                        'product_name' => $line->product?->name ?? '',
                        'quantity' => (float) $line->quantity,
                        'unit_rate' => (float) $line->unit_rate,
                        'coupon_amount' => (float) $line->coupon_amount,
                        'effective_rate' => (float) $line->effective_rate,
                        'shift' => $line->shift instanceof \BackedEnum ? $line->shift->value : $line->shift,
                        'shift_label' => $line->shift instanceof \BackedEnum ? $line->shift->label() : $line->shift,
                        'daily_orders' => DeliveryLogPresenter::fullMonthDailyOrdersTable($lineLogs, $billingMonth, $through),
                    ];
                }),
                'daily_orders' => $dailyOrders,
            ];
        });

        $through = Carbon::today();
        $consumptionLogs = DeliveryLogPresenter::logsThroughDate($monthLogs, $billingMonth, $through);
        $consumptionRows = $this->consumptionAggregator->aggregate($consumptionLogs);

        $billingHistory = Invoice::query()
            ->where('customer_id', $customer->id)
            ->orderByDesc('billing_month')
            ->get()
            ->map(fn (Invoice $invoice) => $this->invoicePayload($invoice));

        $payments = Payment::query()
            ->where('customer_id', $customer->id)
            ->orderByDesc('payment_date')
            ->limit(50)
            ->get()
            ->map(fn (Payment $payment) => $this->paymentPayload($payment));

        return ApiResponse::success([
            'customer' => $this->customerPayload($customer),
            'billing_month' => $billingMonth,
            'subscriptions' => $subscriptions,
            'consumption' => [
                'billing_month' => $billingMonth,
                'rows' => $consumptionRows,
                'grand_total' => round((float) $consumptionRows->sum('line_total'), 2),
            ],
            'billing_history' => $billingHistory,
            'payments' => $payments,
        ]);
    }

    public function dailyOrders(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $date = $request->query('date', Carbon::today()->toDateString());
        $shift = (string) $request->query('shift', 'all');
        $status = (string) $request->query('status', 'all');

        $query = DailyOrderLog::query()
            ->where('farm_id', $owner->farm_id)
            ->whereDate('delivery_date', $date)
            ->with('customer')
            ->orderBy('shift')
            ->orderBy('product_name');

        if ($shift !== 'all') {
            $query->where('shift', $shift);
        }

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $orders = $query->get();
        $summaryQuery = DailyOrderLog::query()
            ->where('farm_id', $owner->farm_id)
            ->whereDate('delivery_date', $date);

        if ($shift !== 'all') {
            $summaryQuery->where('shift', $shift);
        }

        $allForDate = $summaryQuery->get();

        return ApiResponse::success([
            'date' => $date,
            'summary' => [
                'total' => $allForDate->count(),
                'pending' => $allForDate->where('status', OrderLogStatus::Pending)->count(),
                'delivered' => $allForDate->where('status', OrderLogStatus::Delivered)->count(),
                'skipped' => $allForDate->where('status', OrderLogStatus::Skipped)->count(),
                'litres_to_deliver' => round((float) $allForDate
                    ->where('status', '!=', OrderLogStatus::Skipped)
                    ->sum('quantity'), 2),
            ],
            'orders' => $orders->map(fn (DailyOrderLog $log) => $this->orderPayload($log)),
        ]);
    }

    public function updateDailyOrder(Request $request, DailyOrderLog $dailyOrderLog): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($dailyOrderLog->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Order not found.', 404);
        }

        $validated = $request->validate([
            'status' => ['sometimes', Rule::enum(OrderLogStatus::class)],
            'quantity' => ['sometimes', 'numeric', 'min:0', 'max:999'],
        ]);

        if (isset($validated['status'])) {
            $wasSkipped = $dailyOrderLog->status === OrderLogStatus::Skipped;
            $dailyOrderLog->status = $validated['status'];

            if ($wasSkipped
                && $dailyOrderLog->status !== OrderLogStatus::Skipped
                && (float) $dailyOrderLog->quantity <= 0) {
                $dailyOrderLog->loadMissing('subscriptionLine');
                if ($dailyOrderLog->subscriptionLine !== null) {
                    $dailyOrderLog->quantity = (float) $dailyOrderLog->subscriptionLine->quantity;
                }
            }
        }

        if (array_key_exists('quantity', $validated)) {
            $dailyOrderLog->quantity = $validated['quantity'];
        }

        if ($dailyOrderLog->status === OrderLogStatus::Skipped) {
            $dailyOrderLog->quantity = 0;
        }

        $dailyOrderLog->line_total = DailyOrderLog::computeLineTotal(
            (float) $dailyOrderLog->quantity,
            (float) $dailyOrderLog->unit_rate,
        );
        $dailyOrderLog->save();
        $dailyOrderLog->load('customer');

        return ApiResponse::success($this->orderPayload($dailyOrderLog));
    }

    public function invoices(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $billingMonth = (string) $request->query(
            'billing_month',
            Carbon::now()->format('Y-m'),
        );
        $status = (string) $request->query('status', 'all');

        $query = Invoice::query()
            ->where('farm_id', $owner->farm_id)
            ->where('billing_month', $billingMonth)
            ->with('customer')
            ->orderByDesc('issued_at');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $invoices = $query->get();
        $allForMonth = Invoice::query()
            ->where('farm_id', $owner->farm_id)
            ->where('billing_month', $billingMonth)
            ->get();

        return ApiResponse::success([
            'billing_month' => $billingMonth,
            'summary' => [
                'total' => $allForMonth->count(),
                'paid' => $allForMonth->where('status', InvoiceStatus::Paid)->count(),
                'partial' => $allForMonth->where('status', InvoiceStatus::Partial)->count(),
                'unpaid' => $allForMonth->filter(
                    fn (Invoice $i) => in_array($i->status, [InvoiceStatus::Issued, InvoiceStatus::Draft], true),
                )->count(),
                'total_amount' => round((float) $allForMonth->sum('total_amount'), 2),
                'collected' => round((float) $allForMonth->sum('amount_paid'), 2),
                'outstanding' => round((float) $allForMonth->sum('balance_due'), 2),
            ],
            'invoices' => $invoices->map(fn (Invoice $invoice) => $this->invoicePayload($invoice)),
        ]);
    }

    public function invoiceDetail(Request $request, Invoice $invoice): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($invoice->farm_id !== $owner->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Bill not found.', 404);
        }

        $invoice->load(['customer', 'lines', 'payments']);

        return ApiResponse::success([
            'invoice' => $this->invoicePayload($invoice, detailed: true),
            'lines' => $invoice->lines->map(fn ($line) => [
                'id' => $line->id,
                'subscription_id' => $line->subscription_id,
                'product_id' => $line->product_id,
                'product_name' => $line->product_name,
                'shift' => $line->shift instanceof \BackedEnum ? $line->shift->value : $line->shift,
                'shift_label' => $line->shift instanceof \BackedEnum ? $line->shift->label() : $line->shift,
                'delivery_days' => $line->delivery_days,
                'total_quantity' => (float) $line->total_quantity,
                'unit_rate' => (float) $line->unit_rate,
                'line_total' => (float) $line->line_total,
            ]),
            'payments' => $invoice->payments->map(fn (Payment $payment) => $this->paymentPayload($payment)),
        ]);
    }

    public function payments(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $billingMonth = (string) $request->query(
            'billing_month',
            Carbon::now()->format('Y-m'),
        );
        $paymentMethod = (string) $request->query('payment_method', 'all');

        $payments = Payment::query()
            ->where('farm_id', $owner->farm_id)
            ->whereHas('invoice', fn ($q) => $q->where('billing_month', $billingMonth))
            ->with(['customer', 'invoice'])
            ->orderByDesc('payment_date');

        if ($paymentMethod !== 'all') {
            $payments->where('payment_method', $paymentMethod);
        }

        $payments = $payments->get();

        $total = round((float) $payments->sum('amount'), 2);

        return ApiResponse::success([
            'billing_month' => $billingMonth,
            'summary' => [
                'total_transactions' => $payments->count(),
                'total_collected' => $total,
            ],
            'payments' => $payments->map(fn (Payment $payment) => $this->paymentPayload($payment, withCustomer: true)),
        ]);
    }

    private function customerPayload($customer): array
    {
        $status = $customer->displayStatus();

        return [
            'id' => $customer->id,
            'first_name' => $customer->first_name,
            'last_name' => $customer->last_name,
            'full_name' => $customer->fullName(),
            'address_line' => $customer->address_line,
            'area' => $customer->area,
            'landmark' => $customer->landmark,
            'city' => $customer->city,
            'state' => $customer->state,
            'zip' => $customer->zip,
            'contact' => $customer->contact,
            'whatsapp_enabled' => $customer->whatsapp_enabled,
            'secondary_contact' => $customer->secondary_contact,
            'is_active' => $customer->is_active,
            'delivery_type' => $customer->delivery_type ?? 'home_delivery',
            'vacation_start' => $customer->vacation_start?->toDateString(),
            'vacation_end' => $customer->vacation_end?->toDateString(),
            'display_status' => $status,
            'short_address' => $customer->shortAddress(),
            'subscription_count' => (int) ($customer->subscription_count ?? $customer->subscription_lines_count ?? 0),
            'updated_at' => $customer->updated_at?->toIso8601String(),
        ];
    }

    private function orderPayload(DailyOrderLog $log): array
    {
        $log->loadMissing('subscriptionLine');

        return [
            'id' => $log->id,
            'customer_id' => $log->customer_id,
            'customer_name' => $log->customer?->fullName() ?? '',
            'subscription_id' => $log->subscription_id,
            'subscription_line_id' => $log->subscription_line_id,
            'product_id' => $log->product_id,
            'product_name' => $log->product_name,
            'quantity' => (float) $log->quantity,
            'subscribed_quantity' => (float) ($log->subscriptionLine?->quantity ?? $log->quantity),
            'unit_rate' => (float) $log->unit_rate,
            'line_total' => (float) $log->line_total,
            'shift' => $log->shift instanceof \BackedEnum ? $log->shift->value : $log->shift,
            'shift_label' => $log->shift instanceof \BackedEnum ? $log->shift->label() : $log->shift,
            'status' => $log->status instanceof \BackedEnum ? $log->status->value : $log->status,
            'status_label' => $log->status instanceof \BackedEnum ? $log->status->label() : $log->status,
            'delivery_date' => $log->delivery_date?->toDateString(),
            'billing_month' => $log->billing_month,
        ];
    }

    private function invoicePayload(Invoice $invoice, bool $detailed = false): array
    {
        $payload = [
            'id' => $invoice->id,
            'customer_id' => $invoice->customer_id,
            'customer_name' => $invoice->customer?->fullName() ?? '',
            'billing_month' => $invoice->billing_month,
            'invoice_number' => $invoice->invoice_number,
            'subtotal' => (float) $invoice->subtotal,
            'discount_total' => (float) $invoice->discount_total,
            'total_amount' => (float) $invoice->total_amount,
            'amount_paid' => (float) $invoice->amount_paid,
            'balance_due' => (float) $invoice->balance_due,
            'status' => $invoice->status instanceof \BackedEnum ? $invoice->status->value : $invoice->status,
            'status_label' => $invoice->status instanceof \BackedEnum ? $invoice->status->label() : $invoice->status,
            'issued_at' => $invoice->issued_at?->toIso8601String(),
            'due_date' => $invoice->due_date?->toDateString(),
            'sent_at' => $invoice->sent_at?->toIso8601String(),
            'sent_via' => $invoice->sent_via,
            'sent_label' => SentLabel::format($invoice->sent_at),
        ];

        if ($detailed) {
            $payload['customer_contact'] = $invoice->customer?->contact;
            $payload['customer_address'] = $invoice->customer?->shortAddress();
        }

        return $payload;
    }

    private function paymentPayload(Payment $payment, bool $withCustomer = false): array
    {
        $payload = [
            'id' => $payment->id,
            'invoice_id' => $payment->invoice_id,
            'invoice_number' => $payment->invoice?->invoice_number,
            'amount' => (float) $payment->amount,
            'payment_type' => $payment->payment_type instanceof \BackedEnum ? $payment->payment_type->value : $payment->payment_type,
            'payment_type_label' => $payment->payment_type instanceof \BackedEnum ? $payment->payment_type->label() : $payment->payment_type,
            'payment_method' => $payment->payment_method instanceof \BackedEnum ? $payment->payment_method->value : $payment->payment_method,
            'payment_method_label' => $payment->payment_method instanceof \BackedEnum ? $payment->payment_method->label() : $payment->payment_method,
            'payment_date' => $payment->payment_date?->toDateString(),
            'handed_to' => $payment->handed_to,
            'notes' => $payment->notes,
        ];

        if ($withCustomer) {
            $payload['customer_id'] = $payment->customer_id;
            $payload['customer_name'] = $payment->customer?->fullName() ?? '';
        }

        return $payload;
    }

    /** @return array{active: int, inactive: int} */
    private function shiftCustomerSummary(int $farmId, DeliveryShift $shift, string $today): array
    {
        $base = Customer::query()
            ->where('farm_id', $farmId)
            ->whereHas('subscriptions', function ($q) use ($shift) {
                $q->where('status', 'active')
                    ->whereHas('lines', fn ($line) => $line->where('shift', $shift));
            });

        $active = (clone $base)
            ->where('is_active', true)
            ->where(function ($q) use ($today) {
                $q->whereNull('vacation_start')
                    ->orWhereNull('vacation_end')
                    ->orWhere('vacation_end', '<', $today)
                    ->orWhere('vacation_start', '>', $today);
            })
            ->count();

        $inactive = (clone $base)->where('is_active', false)->count();

        return [
            'active' => $active,
            'inactive' => $inactive,
        ];
    }
}
