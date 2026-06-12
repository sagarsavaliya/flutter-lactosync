<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Models\Admin\SaasPayment;
use App\Models\Admin\TenantPlanAssignment;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\FarmOwner;
use App\Models\Subscription;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * GET /api/admin/v1/dashboard
 *
 * Returns aggregate KPIs across all tenants (FR-07) and a per-tenant
 * summary row for each farm owner (FR-08).
 *
 * Protected by auth:admin — a farm-owner token cannot reach this route.
 */
class DashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $today     = Carbon::today();
        $monthStart = Carbon::now()->startOfMonth()->toDateString();
        $monthEnd   = Carbon::now()->endOfMonth()->toDateString();

        $kpis    = $this->buildKpis($today, $monthStart, $monthEnd);
        $tenants = $this->buildTenantRows($today, $monthStart, $monthEnd);

        return response()->json([
            'kpis'    => $kpis,
            'tenants' => $tenants,
        ]);
    }

    // -------------------------------------------------------------------------
    // KPI block
    // -------------------------------------------------------------------------

    private function buildKpis(
        Carbon $today,
        string $monthStart,
        string $monthEnd,
    ): array {
        // 1. Total tenants — COUNT(*) of farm_owners (non-deleted).
        $totalTenants = FarmOwner::count();

        // 2. Active subscriptions (SaaS plan assignments that are live).
        $activeSubscriptions = TenantPlanAssignment::whereIn('status', ['active', 'grace_period'])
            ->count();

        // 3. Total milk-delivery customers across all farms.
        $totalCustomers = Customer::count();

        // 4. Today's milk-delivery orders.
        $todaysOrders = DailyOrderLog::whereDate('delivery_date', $today)->count();

        // 5. Monthly collected — SaaS payments recorded this calendar month.
        $monthlyCollected = SaasPayment::whereBetween('payment_date', [$monthStart, $monthEnd])
            ->sum('amount');

        // 6. Monthly billed — sum of plan prices for all active/grace assignments.
        //    "Billed this month" = each tenant with an active assignment is charged
        //    their plan's monthly-equivalent price once per month.
        $monthlyBilled = TenantPlanAssignment::whereIn('status', ['active', 'grace_period'])
            ->join('subscription_plans', 'subscription_plans.id', '=', 'tenant_plan_assignments.subscription_plan_id')
            ->sum('subscription_plans.price');

        // 7. Total outstanding — SUM(plan prices for active/grace tenants) minus
        //    SUM(all payments those owners have ever made). Reuses $monthlyBilled
        //    for the billed side since at most one cycle per tenant is active.
        $activeOwnerIds = TenantPlanAssignment::whereIn('status', ['active', 'grace_period'])
            ->pluck('owner_id');

        $totalPaidActive  = SaasPayment::whereIn('owner_id', $activeOwnerIds)->sum('amount');
        $totalOutstanding = max(0, (float) $monthlyBilled - (float) $totalPaidActive);

        return [
            'total_tenants'         => $totalTenants,
            'active_subscriptions'  => $activeSubscriptions,
            'total_customers'       => $totalCustomers,
            'todays_orders'         => $todaysOrders,
            'monthly_collected'     => number_format((float) $monthlyCollected, 2, '.', ''),
            'monthly_billed'        => number_format((float) $monthlyBilled, 2, '.', ''),
            'total_outstanding'     => number_format($totalOutstanding, 2, '.', ''),
        ];
    }

    // -------------------------------------------------------------------------
    // Per-tenant rows
    // -------------------------------------------------------------------------

    /**
     * Returns one row per farm owner. Uses three targeted aggregate queries
     * (keyed by owner_id / farm_id) then maps them onto the owners list —
     * no N+1 queries regardless of tenant count.
     */
    private function buildTenantRows(
        Carbon $today,
        string $monthStart,
        string $monthEnd,
    ): array {
        // ── Load all owners with their farm and plan assignment ──────────────
        $owners = FarmOwner::with([
            'farm',
            'tenantPlanAssignment.subscriptionPlan',
        ])->get();

        if ($owners->isEmpty()) {
            return [];
        }

        $ownerIds = $owners->pluck('id')->all();
        $farmIds  = $owners->pluck('farm_id')->filter()->all();

        // ── Customer count per farm_id ────────────────────────────────────────
        $customerCounts = Customer::whereIn('farm_id', $farmIds)
            ->select('farm_id', DB::raw('COUNT(*) as total'))
            ->groupBy('farm_id')
            ->pluck('total', 'farm_id');

        // ── Milk-delivery subscription count per farm_id ──────────────────────
        $subscriptionCounts = Subscription::whereIn('farm_id', $farmIds)
            ->select('farm_id', DB::raw('COUNT(*) as total'))
            ->groupBy('farm_id')
            ->pluck('total', 'farm_id');

        // ── Last payment per owner_id ─────────────────────────────────────────
        // Subquery: for each owner the single most-recent payment row.
        $lastPayments = SaasPayment::whereIn('owner_id', $ownerIds)
            ->select('owner_id', 'payment_date', 'amount')
            ->orderBy('payment_date', 'desc')
            ->get()
            ->unique('owner_id')          // keeps first (most-recent) per owner
            ->keyBy('owner_id');

        // ── Total paid per owner_id (all time, for outstanding calc) ──────────
        $totalPaidPerOwner = SaasPayment::whereIn('owner_id', $ownerIds)
            ->select('owner_id', DB::raw('SUM(amount) as total_paid'))
            ->groupBy('owner_id')
            ->pluck('total_paid', 'owner_id');

        // ── Build rows ────────────────────────────────────────────────────────
        $rows = [];

        foreach ($owners as $owner) {
            $assignment = $owner->tenantPlanAssignment;
            $plan       = $assignment?->subscriptionPlan;
            $farmId     = $owner->farm_id;

            $planPrice  = $plan ? (float) $plan->price : 0.0;
            $totalPaid  = (float) ($totalPaidPerOwner[$owner->id] ?? 0);
            $outstanding = max(0, $planPrice - $totalPaid);

            $lastPayment       = $lastPayments[$owner->id] ?? null;
            $lastPaymentDate   = $lastPayment?->payment_date?->toDateString();
            $lastPaymentAmount = $lastPayment
                ? number_format((float) $lastPayment->amount, 2, '.', '')
                : '0.00';

            $renewalDate       = $assignment?->renewal_date?->toDateString();
            $daysUntilRenewal  = $renewalDate
                ? (int) $today->diffInDays(Carbon::parse($renewalDate), false)
                : null;

            $rows[] = [
                'id'                    => $owner->id,
                'name'                  => $owner->fullName() ?: $owner->farm?->name,
                'phone'                 => $owner->mobile,
                'plan_name'             => $plan?->name,
                'plan_status'           => $assignment?->status,
                'renewal_date'          => $renewalDate,
                'days_until_renewal'    => $daysUntilRenewal,
                'last_payment_date'     => $lastPaymentDate,
                'last_payment_amount'   => $lastPaymentAmount,
                'outstanding_balance'   => number_format($outstanding, 2, '.', ''),
                'customer_count'        => (int) ($customerCounts[$farmId] ?? 0),
                'subscription_count'    => (int) ($subscriptionCounts[$farmId] ?? 0),
            ];
        }

        return $rows;
    }
}
