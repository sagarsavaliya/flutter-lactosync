<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Http\Controllers\Controller;
use App\Models\Admin\SaasPayment;
use App\Models\Admin\TenantPlanAssignment;
use App\Models\FarmOwner;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Admin endpoints for SaaS payment tracking.
 *
 * All routes are protected by auth:admin middleware.
 * Satisfies FR-23 through FR-27 (T1-12).
 */
class PaymentController extends Controller
{
    // -------------------------------------------------------------------------
    // POST /api/admin/v1/tenants/{id}/payments
    // Record a new SaaS payment for a tenant.
    // -------------------------------------------------------------------------

    public function store(Request $request, int $id): JsonResponse
    {
        // Verify the tenant exists.
        $owner = FarmOwner::findOrFail($id);

        $validated = $request->validate([
            'amount'         => ['required', 'numeric', 'gt:0'],
            'payment_date'   => ['required', 'date'],
            'due_date'       => ['nullable', 'date'],
            'payment_method' => ['required', Rule::in(['upi', 'cash', 'credit', 'bank_transfer', 'other'])],
            'paid_by_name'   => ['nullable', 'string', 'max:150'],
            'reference'      => ['nullable', 'string', 'max:255'],
            'notes'          => ['nullable', 'string'],
        ]);

        $payment = DB::transaction(function () use ($validated, $owner, $request) {
            $payment = SaasPayment::create([
                'owner_id'       => $owner->id,
                'amount'         => $validated['amount'],
                'payment_date'   => $validated['payment_date'],
                'due_date'       => $validated['due_date'] ?? null,
                'payment_method' => $validated['payment_method'],
                'paid_by_name'   => $validated['paid_by_name'] ?? null,
                'reference'      => $validated['reference'] ?? null,
                'notes'          => $validated['notes'] ?? null,
                'recorded_by'    => $request->user()->id,
            ]);

            // Auto-resume: if the tenant is in grace or suspended, reactivate.
            $assignment = TenantPlanAssignment::where('owner_id', $owner->id)->first();

            if ($assignment && ($assignment->isInGrace() || $assignment->isSuspended())) {
                $nextDue = $this->nextDueDate($assignment->due_date, $assignment->subscriptionPlan->billing_cycle);

                $assignment->status           = 'active';
                $assignment->suspended_at     = null;
                $assignment->due_date         = $nextDue;
                $assignment->renewal_date     = $nextDue;
                $assignment->grace_expires_at = null;
                $assignment->save();
            }

            return $payment;
        });

        return response()->json([
            'success' => true,
            'data'    => $this->formatPayment($payment),
        ], 201);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/v1/tenants/{id}/payments
    // Per-tenant payment history + outstanding balance.
    // -------------------------------------------------------------------------

    public function indexForTenant(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::findOrFail($id);

        $payments = SaasPayment::forTenant($owner->id)
            ->orderBy('payment_date', 'desc')
            ->get();

        $outstandingBalance = $this->computeOutstandingBalance($owner->id);

        return response()->json([
            'success'             => true,
            'data'                => $payments->map(fn ($p) => $this->formatPayment($p)),
            'outstanding_balance' => $outstandingBalance,
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/v1/payments
    // Global paginated payments list with filters.
    // -------------------------------------------------------------------------

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'tenant_id' => ['nullable', 'integer'],
            'from'      => ['nullable', 'date'],
            'to'        => ['nullable', 'date'],
            'sort_by'   => ['nullable', Rule::in(['date', 'amount', 'tenant'])],
            'page'      => ['nullable', 'integer', 'min:1'],
        ]);

        $query = SaasPayment::query()
            ->join('farm_owners', 'farm_owners.id', '=', 'saas_payments.owner_id')
            ->select('saas_payments.*', 'farm_owners.name as tenant_name');

        if ($request->filled('tenant_id')) {
            $query->where('saas_payments.owner_id', $request->integer('tenant_id'));
        }

        if ($request->filled('from')) {
            $query->whereDate('saas_payments.payment_date', '>=', $request->input('from'));
        }

        if ($request->filled('to')) {
            $query->whereDate('saas_payments.payment_date', '<=', $request->input('to'));
        }

        $sortBy = $request->input('sort_by', 'date');

        match ($sortBy) {
            'amount' => $query->orderBy('saas_payments.amount', 'desc'),
            'tenant' => $query->orderBy('farm_owners.name', 'asc'),
            default  => $query->orderBy('saas_payments.payment_date', 'desc'),
        };

        $paginated = $query->paginate(20);

        // Total outstanding across all active tenants.
        $totalOutstanding = $this->computeTotalOutstanding();

        return response()->json([
            'success'           => true,
            'data'              => collect($paginated->items())->map(fn ($p) => $this->formatPaymentWithTenant($p)),
            'meta'              => [
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
                'total'        => $paginated->total(),
            ],
            'total_outstanding' => $totalOutstanding,
        ]);
    }

    // -------------------------------------------------------------------------
    // PUT /api/admin/v1/payments/{id}
    // Edit a payment. Does not allow changing owner_id.
    // -------------------------------------------------------------------------

    public function update(Request $request, int $id): JsonResponse
    {
        $payment = SaasPayment::findOrFail($id);

        $validated = $request->validate([
            'amount'         => ['required', 'numeric', 'gt:0'],
            'payment_date'   => ['required', 'date'],
            'due_date'       => ['nullable', 'date'],
            'payment_method' => ['required', Rule::in(['upi', 'cash', 'credit', 'bank_transfer', 'other'])],
            'paid_by_name'   => ['nullable', 'string', 'max:150'],
            'reference'      => ['nullable', 'string', 'max:255'],
            'notes'          => ['nullable', 'string'],
        ]);

        $payment->fill($validated);
        $payment->edited_by = $request->user()->id;
        $payment->save();

        return response()->json([
            'success' => true,
            'data'    => $this->formatPayment($payment),
        ]);
    }

    // -------------------------------------------------------------------------
    // DELETE /api/admin/v1/payments/{id}
    // Soft-delete with audit trail.
    // -------------------------------------------------------------------------

    public function destroy(Request $request, int $id): JsonResponse
    {
        $payment = SaasPayment::findOrFail($id);

        // Populate deleted_by before SoftDeletes sets deleted_at.
        $payment->deleted_by = $request->user()->id;
        $payment->save();
        $payment->delete();

        return response()->json([
            'success' => true,
            'message' => 'Payment deleted.',
        ]);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Format a SaasPayment row for API output.
     */
    private function formatPayment(SaasPayment $payment): array
    {
        return [
            'id'             => $payment->id,
            'owner_id'       => $payment->owner_id,
            'amount'         => $payment->amount,
            'payment_date'   => optional($payment->payment_date)->toDateString(),
            'due_date'       => optional($payment->due_date)->toDateString(),
            'payment_method' => $payment->payment_method,
            'paid_by_name'   => $payment->paid_by_name,
            'reference'      => $payment->reference,
            'notes'          => $payment->notes,
            'created_at'     => optional($payment->created_at)->toIso8601String(),
        ];
    }

    /**
     * Format a payment row that includes the joined tenant_name column.
     *
     * @param  \stdClass|SaasPayment  $payment
     */
    private function formatPaymentWithTenant(mixed $payment): array
    {
        return [
            'id'             => $payment->id,
            'owner_id'       => $payment->owner_id,
            'tenant_name'    => $payment->tenant_name,
            'amount'         => $payment->amount,
            'payment_date'   => $payment instanceof SaasPayment
                ? optional($payment->payment_date)->toDateString()
                : $payment->payment_date,
            'due_date'       => $payment instanceof SaasPayment
                ? optional($payment->due_date)->toDateString()
                : $payment->due_date,
            'payment_method' => $payment->payment_method,
            'paid_by_name'   => $payment->paid_by_name,
            'reference'      => $payment->reference,
            'notes'          => $payment->notes,
            'created_at'     => $payment instanceof SaasPayment
                ? optional($payment->created_at)->toIso8601String()
                : $payment->created_at,
        ];
    }

    /**
     * Compute the outstanding balance for a single tenant:
     *   plan_price − total_paid_this_cycle
     *
     * "This cycle" = payments recorded on or after the assignment's current
     * due_date (i.e. within the billing period the assignment tracks).
     * If no active assignment exists, balance = 0.
     */
    private function computeOutstandingBalance(int $ownerId): string
    {
        $assignment = TenantPlanAssignment::with('subscriptionPlan')
            ->where('owner_id', $ownerId)
            ->first();

        if (! $assignment || ! $assignment->subscriptionPlan) {
            return '0.00';
        }

        $planPrice = (float) $assignment->subscriptionPlan->price;

        // Sum payments for this cycle (payment_date >= cycle start / due_date).
        $cycleStart = $assignment->due_date
            ? Carbon::parse($assignment->due_date)->subMonth() // start = due minus one cycle
            : $assignment->start_date;

        $totalPaid = SaasPayment::where('owner_id', $ownerId)
            ->whereDate('payment_date', '>=', $cycleStart)
            ->sum('amount');

        $balance = max(0, $planPrice - $totalPaid);

        return number_format($balance, 2, '.', '');
    }

    /**
     * Sum outstanding balances across all tenants with an active assignment.
     * Uses two queries instead of N+1: one for assignments, one grouped aggregate for payments.
     */
    private function computeTotalOutstanding(): string
    {
        $assignments = TenantPlanAssignment::with('subscriptionPlan')
            ->whereIn('status', ['active', 'grace_period', 'suspended'])
            ->get();

        if ($assignments->isEmpty()) {
            return '0.00';
        }

        // Single query: total paid per owner (no cycle filter — outstanding = plan price minus all-time paid)
        $paidByOwner = SaasPayment::whereIn('owner_id', $assignments->pluck('owner_id'))
            ->selectRaw('owner_id, SUM(amount) as total_paid')
            ->groupBy('owner_id')
            ->pluck('total_paid', 'owner_id');

        $total = 0.0;

        foreach ($assignments as $assignment) {
            if (! $assignment->subscriptionPlan) {
                continue;
            }
            $planPrice = (float) $assignment->subscriptionPlan->price;
            $paid      = (float) ($paidByOwner[$assignment->owner_id] ?? 0);
            $total    += max(0, $planPrice - $paid);
        }

        return number_format($total, 2, '.', '');
    }

    /**
     * Calculate the next due date from a given date and billing cycle string.
     *
     * Supported cycles: monthly, quarterly, half_yearly, yearly.
     */
    private function nextDueDate(?Carbon $currentDue, string $billingCycle): Carbon
    {
        $base = $currentDue ?? now();

        return match ($billingCycle) {
            'quarterly'   => $base->copy()->addMonths(3),
            'half_yearly' => $base->copy()->addMonths(6),
            'yearly'      => $base->copy()->addYear(),
            default       => $base->copy()->addMonth(), // monthly
        };
    }
}
