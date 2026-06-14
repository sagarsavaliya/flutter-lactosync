<?php

namespace App\Http\Controllers\Api\Customer\V1;

use App\Enums\DeliveryShift;
use App\Enums\OrderLogStatus;
use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\SubscriptionLine;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class OrderController extends Controller
{
    /**
     * GET /api/customer/v1/orders?month=YYYY-MM
     *
     * Returns every calendar day in the requested month with delivery status
     * and per-subscription-line entries (including server-authoritative lock flag).
     *
     * CA-04
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'month' => ['sometimes', 'date_format:Y-m'],
        ]);

        /** @var Customer $customer */
        $customer = $request->user();
        $customer->loadMissing('farm');

        $monthStr = $request->input('month', Carbon::now()->format('Y-m'));
        $monthStart = Carbon::createFromFormat('Y-m', $monthStr)->startOfMonth()->startOfDay();
        $monthEnd   = $monthStart->copy()->endOfMonth()->startOfDay();
        $today      = Carbon::now()->startOfDay();

        // Load all active subscription lines for this customer (with product eager-loaded).
        $activeLines = $customer
            ->subscriptionLines()
            ->whereHas('subscription', fn ($q) => $q->where('status', 'active'))
            ->with('product')
            ->get();

        // Load all DailyOrderLog rows for this customer in the requested month in one query.
        $logsForMonth = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('billing_month', $monthStr)
            ->get()
            ->keyBy(fn (DailyOrderLog $log) => $log->delivery_date->format('Y-m-d') . '|' . $log->subscription_line_id);

        $farm = $customer->farm;

        $days = [];
        $cursor = $monthStart->copy();

        while ($cursor->lte($monthEnd)) {
            $dateStr = $cursor->format('Y-m-d');

            // ── Derive day status ────────────────────────────────────────────
            $dayStatus = $this->resolveDayStatus($customer, $cursor, $today, $logsForMonth, $dateStr);

            // ── Build per-line entries ───────────────────────────────────────
            $entries = $activeLines->map(function (SubscriptionLine $line) use (
                $dateStr,
                $cursor,
                $today,
                $logsForMonth,
                $farm,
            ): array {
                $logKey = $dateStr . '|' . $line->id;
                $log    = $logsForMonth->get($logKey);

                $shift = $line->shift instanceof DeliveryShift
                    ? $line->shift->value
                    : (string) $line->shift;

                $qty = $log !== null
                    ? (float) $log->quantity
                    : (float) $line->quantity;

                $locked = $this->isEntryLocked($shift, $cursor, $today, $farm);

                return [
                    'subscription_line_id' => $line->id,
                    'product_name'         => $line->product?->name ?? '',
                    'shift'                => $shift,
                    'qty'                  => $qty,
                    'locked'               => $locked,
                ];
            })->values()->all();

            $days[] = [
                'date'    => $dateStr,
                'status'  => $dayStatus,
                'entries' => $entries,
            ];

            $cursor->addDay();
        }

        $consumptionRows = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('billing_month', $monthStr)
            ->where('status', 'delivered')
            ->get()
            ->groupBy(fn (DailyOrderLog $log) => $log->product_name.'|'.$log->unit_rate)
            ->map(function ($group) {
                /** @var DailyOrderLog $first */
                $first = $group->first();

                return [
                    'product_name'    => $first->product_name,
                    'unit_rate'       => (float) $first->unit_rate,
                    'total_quantity'  => round((float) $group->sum('quantity'), 2),
                    'line_total'      => round((float) $group->sum('line_total'), 2),
                ];
            })
            ->values();

        return ApiResponse::success([
            'month' => $monthStr,
            'days'  => $days,
            'consumption' => [
                'billing_month' => $monthStr,
                'rows' => $consumptionRows,
                'grand_total' => round((float) $consumptionRows->sum('line_total'), 2),
            ],
        ]);
    }

    /**
     * PUT /api/customer/v1/orders/{date}/qty
     *
     * Update the quantity for one subscription line on the given date.
     * Enforces shift-aware lock; upserts a DailyOrderLog record.
     *
     * CA-07
     */
    public function updateQty(Request $request, string $date): JsonResponse
    {
        // Parse and validate date.
        try {
            $deliveryDate = Carbon::createFromFormat('Y-m-d', $date)->startOfDay();
        } catch (\Exception) {
            return ApiResponse::error('INVALID_DATE', 'Invalid date format. Expected YYYY-MM-DD.', 422);
        }

        $validated = $request->validate([
            'subscription_line_id' => ['required', 'integer'],
            'qty'                  => ['required', 'integer', 'min:0'],
        ]);

        /** @var Customer $customer */
        $customer = $request->user();
        $customer->loadMissing('farm');

        // Load subscription line and confirm it belongs to this customer.
        $line = SubscriptionLine::query()
            ->whereKey($validated['subscription_line_id'])
            ->whereHas('subscription', fn ($q) => $q->where('customer_id', $customer->id))
            ->with('product')
            ->first();

        if ($line === null) {
            return ApiResponse::error('FORBIDDEN', 'Subscription line does not belong to this customer.', 403);
        }

        $shift = $line->shift instanceof DeliveryShift
            ? $line->shift->value
            : (string) $line->shift;

        $today = Carbon::now()->startOfDay();

        // Enforce lock.
        if ($this->isEntryLocked($shift, $deliveryDate, $today, $customer->farm)) {
            return ApiResponse::error('LOCKED', 'Order already submitted — changes are locked.', 422);
        }

        $billingMonth = $deliveryDate->format('Y-m');
        $qty          = (int) $validated['qty'];

        // Upsert the DailyOrderLog record.
        $existing = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('subscription_line_id', $line->id)
            ->whereDate('delivery_date', $deliveryDate->toDateString())
            ->first();

        if ($existing !== null) {
            $newStatus = $qty === 0
                ? OrderLogStatus::Skipped->value
                : ($existing->status === OrderLogStatus::Delivered ? $existing->status->value : OrderLogStatus::Pending->value);

            $existing->update([
                'quantity'  => $qty,
                'status'    => $newStatus,
            ]);
        } else {
            $newStatus = $qty === 0
                ? OrderLogStatus::Skipped->value
                : OrderLogStatus::Pending->value;

            $subscription = $line->subscription;

            DailyOrderLog::query()->create([
                'farm_id'              => $customer->farm_id,
                'customer_id'          => $customer->id,
                'subscription_id'      => $line->subscription_id,
                'subscription_line_id' => $line->id,
                'product_id'           => $line->product_id,
                'product_name'         => $line->product?->name ?? '',
                'quantity'             => $qty,
                'unit_rate'            => $line->effective_rate ?? $line->unit_rate,
                'line_total'           => DailyOrderLog::computeLineTotal((float) $qty, (float) ($line->effective_rate ?? $line->unit_rate)),
                'shift'                => $shift,
                'status'               => $newStatus,
                'delivery_date'        => $deliveryDate->toDateString(),
                'billing_month'        => $billingMonth,
            ]);
        }

        return ApiResponse::success([
            'updated' => true,
            'date'    => $date,
            'qty'     => $qty,
        ]);
    }

    /**
     * POST /api/customer/v1/orders/{date}/skip
     *
     * Skip all subscription lines for the authenticated customer on the given date.
     * Enforces three PRD constraints and is idempotent for an already-skipped day.
     *
     * CA-08
     */
    public function skip(Request $request, string $date): JsonResponse
    {
        // Parse and validate date.
        try {
            $deliveryDate = Carbon::createFromFormat('Y-m-d', $date)->startOfDay();
        } catch (\Exception) {
            return ApiResponse::error('INVALID_DATE', 'Invalid date format. Expected YYYY-MM-DD.', 422);
        }

        /** @var Customer $customer */
        $customer = $request->user();

        $today = Carbon::now()->startOfDay();

        // Constraint 1: date must be strictly in the future.
        if (! $deliveryDate->gt($today)) {
            return ApiResponse::error('PAST_DATE', 'Date must be in the future.', 422);
        }

        // Constraint 2: date must not fall within customer's active vacation range.
        if ($customer->vacation_start !== null && $customer->vacation_end !== null) {
            if ($deliveryDate->between(
                $customer->vacation_start->copy()->startOfDay(),
                $customer->vacation_end->copy()->startOfDay(),
            )) {
                return ApiResponse::error('VACATION_DAY', 'Cannot skip a day during an active vacation.', 422);
            }
        }

        // Constraint 3: date must be within the next 7 days.
        if ($deliveryDate->gt($today->copy()->addDays(7))) {
            return ApiResponse::error('TOO_FAR_AHEAD', 'Cannot skip more than 7 days in advance.', 422);
        }

        $dateStr      = $deliveryDate->toDateString();
        $billingMonth = $deliveryDate->format('Y-m');

        // Check for already-delivered log.
        $deliveredExists = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->whereDate('delivery_date', $dateStr)
            ->where('status', OrderLogStatus::Delivered->value)
            ->exists();

        if ($deliveredExists) {
            return ApiResponse::error('ALREADY_DELIVERED', 'Cannot skip a day that has already been delivered.', 422);
        }

        // Idempotent: if all logs for this date are already skipped (and there's at least one), return success.
        $existingLogs = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->whereDate('delivery_date', $dateStr)
            ->get();

        $allSkipped = $existingLogs->isNotEmpty()
            && $existingLogs->every(fn (DailyOrderLog $log) => $log->status === OrderLogStatus::Skipped);

        if ($allSkipped) {
            return ApiResponse::success(['skipped' => true]);
        }

        // Load all active subscription lines for this customer.
        $customer->loadMissing('farm');
        $activeLines = $customer
            ->subscriptionLines()
            ->whereHas('subscription', fn ($q) => $q->where('status', 'active'))
            ->with('product')
            ->get();

        // Upsert a skipped log for each subscription line.
        foreach ($activeLines as $line) {
            $shift = $line->shift instanceof DeliveryShift
                ? $line->shift->value
                : (string) $line->shift;

            $existing = DailyOrderLog::query()
                ->where('customer_id', $customer->id)
                ->where('subscription_line_id', $line->id)
                ->whereDate('delivery_date', $dateStr)
                ->first();

            if ($existing !== null) {
                $existing->update([
                    'quantity' => 0,
                    'status'   => OrderLogStatus::Skipped->value,
                ]);
            } else {
                DailyOrderLog::query()->create([
                    'farm_id'              => $customer->farm_id,
                    'customer_id'          => $customer->id,
                    'subscription_id'      => $line->subscription_id,
                    'subscription_line_id' => $line->id,
                    'product_id'           => $line->product_id,
                    'product_name'         => $line->product?->name ?? '',
                    'quantity'             => 0,
                    'unit_rate'            => $line->effective_rate ?? $line->unit_rate,
                    'line_total'           => 0,
                    'shift'                => $shift,
                    'status'               => OrderLogStatus::Skipped->value,
                    'delivery_date'        => $dateStr,
                    'billing_month'        => $billingMonth,
                ]);
            }
        }

        return ApiResponse::success([
            'skipped' => true,
            'date'    => $date,
        ]);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    /**
     * Derive the status string for a single calendar day.
     *
     * Priority: vacation > delivered > skipped > expected (today/future) > no_record (past)
     */
    private function resolveDayStatus(
        Customer $customer,
        Carbon $date,
        Carbon $today,
        \Illuminate\Support\Collection $logsForMonth,
        string $dateStr,
    ): string {
        // Vacation check.
        if ($customer->vacation_start !== null && $customer->vacation_end !== null) {
            if ($date->between(
                $customer->vacation_start->copy()->startOfDay(),
                $customer->vacation_end->copy()->startOfDay(),
            )) {
                return 'vacation';
            }
        }

        // Check for any log matching this date (any subscription line).
        $logsForDate = $logsForMonth->filter(
            fn (DailyOrderLog $log) => $log->delivery_date->format('Y-m-d') === $dateStr
        );

        foreach ($logsForDate as $log) {
            if ($log->status === OrderLogStatus::Delivered) {
                return 'delivered';
            }
        }

        foreach ($logsForDate as $log) {
            if ($log->status === OrderLogStatus::Skipped) {
                return 'skipped';
            }
        }

        // Future or today with no log → expected; past with no log → no_record.
        if ($date->gte($today)) {
            return 'expected';
        }

        return 'no_record';
    }

    /**
     * Determine whether a subscription-line entry is locked for editing.
     *
     * Morning shift: editable_date = tomorrow.
     *   Locked if now() >= farm->morning_order_time (time-of-day comparison).
     *   A date != tomorrow is always locked.
     *
     * Evening shift: editable_date = today.
     *   Locked if now() >= farm->evening_order_time (time-of-day comparison).
     *   A date != today is always locked.
     *
     * Falls back to locked = true when farm or schedule time is unavailable.
     */
    private function isEntryLocked(
        string $shift,
        Carbon $date,
        Carbon $today,
        ?\App\Models\Farm $farm,
    ): bool {
        if ($farm === null) {
            return true;
        }

        $now = Carbon::now();

        if ($shift === DeliveryShift::Morning->value) {
            $editableDate = $today->copy()->addDay()->startOfDay();

            // Date must equal tomorrow.
            if (! $date->startOfDay()->eq($editableDate)) {
                return true;
            }

            // Check if we are past the morning order cut-off today.
            if ($farm->morning_order_time === null) {
                return false;
            }

            $cutoff = Carbon::parse($farm->morning_order_time)->setDateFrom($now);

            return $now->gte($cutoff);
        }

        // Evening shift.
        $editableDate = $today->copy()->startOfDay();

        if (! $date->startOfDay()->eq($editableDate)) {
            return true;
        }

        if ($farm->evening_order_time === null) {
            return false;
        }

        $cutoff = Carbon::parse($farm->evening_order_time)->setDateFrom($now);

        return $now->gte($cutoff);
    }
}
