<?php

namespace App\Http\Controllers\Api\Customer\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\Invoice;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    /**
     * GET /api/customer/v1/dashboard
     *
     * Returns the authenticated customer's dashboard data:
     *   - outstanding_balance
     *   - upi_vpa + upi_payee_name (only when outstanding_balance > 0)
     *   - monthly_summary  { delivered, skipped, vacation_days }
     *   - active_subscriptions [ { product_name, shift, qty } ]
     */
    public function index(Request $request): JsonResponse
    {
        /** @var Customer $customer */
        $customer = $request->user();
        $customer->loadMissing('farm');

        // ── Outstanding balance ───────────────────────────────────────────────
        $outstandingBalance = round(
            (float) Invoice::query()
                ->where('customer_id', $customer->id)
                ->where('status', '!=', 'paid')
                ->sum('balance_due'),
            2,
        );

        // ── UPI details (only when balance is owed) ───────────────────────────
        $upiVpa      = null;
        $upiPayeeName = null;

        if ($outstandingBalance > 0 && $customer->farm !== null) {
            $upiVpa       = $customer->farm->upi_vpa;
            $upiPayeeName = $customer->farm->upi_payee_name;
        }

        // ── Monthly summary ───────────────────────────────────────────────────
        $now   = Carbon::now();
        $month = $now->format('Y-m');

        $delivered = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('billing_month', $month)
            ->where('status', 'delivered')
            ->count();

        $skipped = DailyOrderLog::query()
            ->where('customer_id', $customer->id)
            ->where('billing_month', $month)
            ->where('status', 'skipped')
            ->count();

        $vacationDays = $this->computeVacationDaysInMonth($customer, $now);

        // ── Active subscriptions ──────────────────────────────────────────────
        $activeSubscriptions = $customer
            ->subscriptionLines()
            ->whereHas('subscription', fn ($q) => $q->where('status', 'active'))
            ->with('product')
            ->get()
            ->map(fn ($line) => [
                'product_name' => $line->product?->name ?? '',
                'shift'        => $line->shift instanceof \BackedEnum
                    ? $line->shift->value
                    : (string) $line->shift,
                'qty'          => (float) $line->quantity,
            ])
            ->values()
            ->all();

        return ApiResponse::success([
            'outstanding_balance' => $outstandingBalance,
            'upi_vpa'             => $upiVpa,
            'upi_payee_name'      => $upiPayeeName,
            'monthly_summary'     => [
                'delivered'     => $delivered,
                'skipped'       => $skipped,
                'vacation_days' => $vacationDays,
            ],
            'active_subscriptions' => $activeSubscriptions,
        ]);
    }

    /**
     * Count how many days of the given month fall within the customer's
     * vacation_start–vacation_end range. Returns 0 if no vacation is set.
     */
    private function computeVacationDaysInMonth(Customer $customer, Carbon $now): int
    {
        if ($customer->vacation_start === null || $customer->vacation_end === null) {
            return 0;
        }

        $monthStart = $now->copy()->startOfMonth()->startOfDay();
        $monthEnd   = $now->copy()->endOfMonth()->startOfDay();

        // Clamp the vacation window to the current month
        $clampStart = $customer->vacation_start->copy()->startOfDay()->max($monthStart);
        $clampEnd   = $customer->vacation_end->copy()->startOfDay()->min($monthEnd);

        if ($clampEnd->lt($clampStart)) {
            return 0;
        }

        return (int) $clampStart->diffInDays($clampEnd) + 1;
    }
}
