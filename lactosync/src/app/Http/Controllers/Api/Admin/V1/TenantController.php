<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Http\Controllers\Controller;
use App\Models\Admin\SaasPayment;
use App\Models\Admin\SubscriptionPlan;
use App\Models\Admin\TenantPlanAssignment;
use App\Models\Customer;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Models\Subscription;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Admin Tenant Management API — T1-10
 *
 * All routes are behind auth:admin middleware.
 * The "tenant" concept maps 1-to-1 with a farm_owners row; its farm_id links
 * to the farms table which owns customers and subscriptions.
 *
 * Endpoints:
 *   GET    /api/admin/v1/tenants
 *   GET    /api/admin/v1/tenants/{id}
 *   POST   /api/admin/v1/tenants/{id}/plan-assign
 *   POST   /api/admin/v1/tenants/{id}/plan-change
 *   POST   /api/admin/v1/tenants/{id}/plan-pause
 *   POST   /api/admin/v1/tenants/{id}/plan-resume
 */
class TenantController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/v1/tenants
    // -------------------------------------------------------------------------

    /**
     * Paginated list of all tenants (farm_owners rows).
     *
     * Query parameters:
     *   ?search=        — LIKE filter on farm_owners.name
     *   ?plan_status=   — filter by tenant_plan_assignments.status
     *   ?page=          — pagination page (15 per page)
     *
     * Each row includes: id, name, phone, email, created_at, plan_name,
     * plan_status, renewal_date, days_until_renewal, outstanding_balance.
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'search'      => ['nullable', 'string', 'max:100'],
            'plan_status' => ['nullable', 'string', 'in:active,grace_period,suspended,paused,expired,no_plan'],
        ]);

        $query = FarmOwner::query()
            ->select([
                'farm_owners.id',
                'farm_owners.name',
                'farm_owners.mobile',
                'farm_owners.created_at',
            ])
            ->leftJoin('tenant_plan_assignments as tpa', 'tpa.owner_id', '=', 'farm_owners.id')
            ->leftJoin('subscription_plans as sp', 'sp.id', '=', 'tpa.subscription_plan_id')
            ->addSelect([
                'sp.name as plan_name',
                'tpa.status as plan_status',
                'tpa.renewal_date',
                'tpa.due_date',
                'tpa.start_date',
            ]);

        if ($request->filled('search')) {
            $query->where('farm_owners.name', 'like', '%' . $request->search . '%');
        }

        if ($request->filled('plan_status')) {
            if ($request->plan_status === 'no_plan') {
                $query->whereNull('tpa.id');
            } else {
                $query->where('tpa.status', $request->plan_status);
            }
        }

        $paginator = $query->orderBy('farm_owners.name')->paginate(15);

        // Attach outstanding balance per tenant using a subquery aggregate.
        $ownerIds = collect($paginator->items())->pluck('id')->all();

        $totals = SaasPayment::whereIn('owner_id', $ownerIds)
            ->groupBy('owner_id')
            ->selectRaw('owner_id, SUM(amount) as total_paid')
            ->pluck('total_paid', 'owner_id');

        $items = collect($paginator->items())->map(function ($owner) use ($totals) {
            $daysUntilRenewal = null;
            if ($owner->renewal_date) {
                $daysUntilRenewal = (int) now()->startOfDay()->diffInDays(
                    Carbon::parse($owner->renewal_date)->startOfDay(),
                    false
                );
            }

            $outstandingBalance = $this->computeOutstandingBalance(
                $owner->id,
                $owner->start_date ? Carbon::parse($owner->start_date) : null,
                (float) ($totals[$owner->id] ?? 0)
            );

            return [
                'id'                  => $owner->id,
                'name'                => $owner->name,
                'phone'               => $owner->mobile,
                'email'               => null, // FarmOwner does not store email
                'created_at'          => $owner->created_at,
                'plan_name'           => $owner->plan_name,
                'plan_status'         => $owner->plan_status ?? 'no_plan',
                'renewal_date'        => $owner->renewal_date,
                'days_until_renewal'  => $daysUntilRenewal,
                'outstanding_balance' => $outstandingBalance,
            ];
        });

        return response()->json([
            'success' => true,
            'data'    => [
                'items'        => $items,
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
                'per_page'     => $paginator->perPage(),
                'total'        => $paginator->total(),
            ],
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/v1/tenants/{id}
    // -------------------------------------------------------------------------

    /**
     * Full detail for a single tenant.
     *
     * Returns: farm-owner profile, current plan, usage counters, plan limits,
     * payment summary, last-10 payment rows, and activity trail from the
     * plan_change_log JSON column.
     */
    public function show(int $id): JsonResponse
    {
        $owner = FarmOwner::find($id);

        if ($owner === null) {
            return $this->notFound();
        }

        return response()->json([
            'success' => true,
            'data'    => $this->buildTenantDetail($owner),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/tenants/{id}/plan-assign
    // -------------------------------------------------------------------------

    /**
     * Assign (or re-assign) a subscription plan to a tenant.
     *
     * Creates or updates the single TenantPlanAssignment row for this owner.
     * Appends an 'assigned' entry to plan_change_log.
     *
     * Request: { plan_id: int, start_date: date }
     */
    public function planAssign(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::find($id);

        if ($owner === null) {
            return $this->notFound();
        }

        $validated = $request->validate([
            'plan_id'    => ['required', 'integer', 'exists:subscription_plans,id'],
            'start_date' => ['required', 'date'],
        ]);

        $plan = SubscriptionPlan::find($validated['plan_id']);

        if ($plan->is_archived) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'PLAN_ARCHIVED',
                    'message' => 'An archived plan cannot be assigned to a tenant.',
                ],
            ], 422);
        }

        $startDate  = Carbon::parse($validated['start_date']);
        $dueDate    = $this->calculateDueDate($startDate, $plan->billing_cycle);
        $graceDate  = $dueDate->copy()->addDays(5);

        DB::transaction(function () use ($owner, $plan, $startDate, $dueDate, $graceDate, $request) {
            $assignment = TenantPlanAssignment::firstOrNew(['owner_id' => $owner->id]);

            $assignment->fill([
                'subscription_plan_id' => $plan->id,
                'status'               => 'active',
                'start_date'           => $startDate->toDateString(),
                'renewal_date'         => $dueDate->toDateString(),
                'due_date'             => $dueDate->toDateString(),
                'grace_expires_at'     => $graceDate->toDateString(),
                'suspended_at'         => null,
                'paused_at'            => null,
                'resumed_at'           => null,
                'paused_by'            => null,
                'resumed_by'           => null,
                'assigned_by'          => $request->user()->id,
            ]);

            $assignment->save();

            $assignment->logPlanChange([
                'type'               => 'initial_assignment',
                'from_plan_id'       => null,
                'from_plan_name'     => null,
                'to_plan_id'         => $plan->id,
                'to_plan_name'       => $plan->name,
                'changed_by_admin_id'=> $request->user()->id,
                'reason'             => null,
            ]);
        });

        $owner->refresh();

        return response()->json([
            'success' => true,
            'data'    => $this->buildTenantDetail($owner),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/tenants/{id}/plan-change
    // -------------------------------------------------------------------------

    /**
     * Change (upgrade / downgrade) an existing plan assignment.
     *
     * Keeps the same start_date; recalculates due_date and grace_expires_at
     * based on the new plan's billing cycle.
     *
     * Request: { plan_id: int, reason: string (required, non-empty) }
     */
    public function planChange(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::find($id);

        if ($owner === null) {
            return $this->notFound();
        }

        $assignment = TenantPlanAssignment::where('owner_id', $id)->first();

        if ($assignment === null) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'NO_PLAN_ASSIGNED',
                    'message' => 'This tenant does not have an active plan assignment. Use plan-assign first.',
                ],
            ], 409);
        }

        $validated = $request->validate([
            'plan_id' => ['required', 'integer', 'exists:subscription_plans,id'],
            'reason'  => ['required', 'string', 'min:1', 'max:500'],
        ]);

        $newPlan = SubscriptionPlan::find($validated['plan_id']);

        if ($newPlan->is_archived) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'PLAN_ARCHIVED',
                    'message' => 'An archived plan cannot be assigned to a tenant.',
                ],
            ], 422);
        }

        $oldPlan    = $assignment->subscriptionPlan;
        $startDate  = $assignment->start_date;
        $dueDate    = $this->calculateDueDate($startDate, $newPlan->billing_cycle);
        $graceDate  = $dueDate->copy()->addDays(5);

        // Determine upgrade vs downgrade for the log entry type.
        $type = 'upgrade';
        if ($oldPlan && $newPlan->price < $oldPlan->price) {
            $type = 'downgrade';
        }

        DB::transaction(function () use ($assignment, $newPlan, $oldPlan, $dueDate, $graceDate, $type, $validated, $request) {
            $assignment->update([
                'subscription_plan_id' => $newPlan->id,
                'renewal_date'         => $dueDate->toDateString(),
                'due_date'             => $dueDate->toDateString(),
                'grace_expires_at'     => $graceDate->toDateString(),
            ]);

            $assignment->logPlanChange([
                'type'               => $type,
                'from_plan_id'       => $oldPlan?->id,
                'from_plan_name'     => $oldPlan?->name,
                'to_plan_id'         => $newPlan->id,
                'to_plan_name'       => $newPlan->name,
                'changed_by_admin_id'=> $request->user()->id,
                'reason'             => $validated['reason'],
            ]);
        });

        $owner->refresh();

        return response()->json([
            'success' => true,
            'data'    => $this->buildTenantDetail($owner),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/tenants/{id}/plan-pause
    // -------------------------------------------------------------------------

    /**
     * Pause the tenant's plan.
     *
     * Valid from states: active, grace_period.
     * Sets status='paused', paused_at=now(), paused_by=auth()->id().
     */
    public function planPause(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::find($id);

        if ($owner === null) {
            return $this->notFound();
        }

        $assignment = TenantPlanAssignment::where('owner_id', $id)->first();

        if ($assignment === null) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'NO_PLAN_ASSIGNED',
                    'message' => 'This tenant does not have an active plan assignment.',
                ],
            ], 409);
        }

        if (! in_array($assignment->status, ['active', 'grace_period'], true)) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'INVALID_STATE_TRANSITION',
                    'message' => "Plan cannot be paused from status '{$assignment->status}'. Only active or grace_period plans can be paused.",
                ],
            ], 409);
        }

        DB::transaction(function () use ($assignment, $request) {
            $assignment->update([
                'status'    => 'paused',
                'paused_at' => now(),
                'paused_by' => $request->user()->id,
            ]);

            $assignment->logPlanChange([
                'type'               => 'paused',
                'from_plan_id'       => $assignment->subscription_plan_id,
                'from_plan_name'     => $assignment->subscriptionPlan?->name,
                'to_plan_id'         => $assignment->subscription_plan_id,
                'to_plan_name'       => $assignment->subscriptionPlan?->name,
                'changed_by_admin_id'=> $request->user()->id,
                'reason'             => null,
            ]);
        });

        $owner->refresh();

        return response()->json([
            'success' => true,
            'data'    => $this->buildTenantDetail($owner),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/tenants/{id}/plan-resume
    // -------------------------------------------------------------------------

    /**
     * Resume a paused plan.
     *
     * Valid from state: paused.
     * Recalculates due_date = today + full billing cycle (simple approach;
     * logged in DECISIONS: we do not attempt to carry over remaining days from
     * before the pause because the pause duration is indeterminate and may be
     * agreed manually between admin and tenant).
     * Updates grace_expires_at = new due_date + 5 days.
     */
    public function planResume(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::find($id);

        if ($owner === null) {
            return $this->notFound();
        }

        $assignment = TenantPlanAssignment::where('owner_id', $id)->first();

        if ($assignment === null) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'NO_PLAN_ASSIGNED',
                    'message' => 'This tenant does not have an active plan assignment.',
                ],
            ], 409);
        }

        if ($assignment->status !== 'paused') {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'INVALID_STATE_TRANSITION',
                    'message' => "Plan cannot be resumed from status '{$assignment->status}'. Only paused plans can be resumed.",
                ],
            ], 409);
        }

        $plan      = $assignment->subscriptionPlan;
        $newDue    = $this->calculateDueDate(now(), $plan->billing_cycle);
        $graceDate = $newDue->copy()->addDays(5);

        DB::transaction(function () use ($assignment, $newDue, $graceDate, $request) {
            $assignment->update([
                'status'           => 'active',
                'resumed_at'       => now(),
                'resumed_by'       => $request->user()->id,
                'due_date'         => $newDue->toDateString(),
                'renewal_date'     => $newDue->toDateString(),
                'grace_expires_at' => $graceDate->toDateString(),
            ]);

            $assignment->logPlanChange([
                'type'               => 'resumed',
                'from_plan_id'       => $assignment->subscription_plan_id,
                'from_plan_name'     => $assignment->subscriptionPlan?->name,
                'to_plan_id'         => $assignment->subscription_plan_id,
                'to_plan_name'       => $assignment->subscriptionPlan?->name,
                'changed_by_admin_id'=> $request->user()->id,
                'reason'             => null,
            ]);
        });

        $owner->refresh();

        return response()->json([
            'success' => true,
            'data'    => $this->buildTenantDetail($owner),
        ]);
    }

    // -------------------------------------------------------------------------
    // PUT /api/admin/v1/tenants/{id}/profile
    // -------------------------------------------------------------------------

    /**
     * Update editable profile fields for a tenant.
     *
     * Touches:
     *   farm_owners — name, mobile, is_active, pin (only when new_pin is sent)
     *   farms       — name, address_line, city, state, zip,
     *                 document_settings.gst_number
     *
     * All body fields are optional; only those sent are updated.
     */
    public function updateProfile(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::find($id);

        if ($owner === null) {
            return $this->notFound();
        }

        $validated = $request->validate([
            'name'         => ['sometimes', 'string', 'max:150'],
            'mobile'       => ['sometimes', 'string', 'max:20'],
            'new_pin'      => ['sometimes', 'string', 'digits:6'],
            'is_active'    => ['sometimes', 'boolean'],
            'farm_name'    => ['sometimes', 'string', 'max:200'],
            'address_line' => ['sometimes', 'nullable', 'string', 'max:255'],
            'city'         => ['sometimes', 'nullable', 'string', 'max:100'],
            'state'        => ['sometimes', 'nullable', 'string', 'max:100'],
            'zip'          => ['sometimes', 'nullable', 'string', 'max:20'],
            'gst_number'   => ['sometimes', 'nullable', 'string', 'max:20'],
        ]);

        DB::transaction(function () use ($owner, $validated) {
            // Update FarmOwner scalar fields
            $ownerFields = array_filter([
                'name'      => $validated['name'] ?? null,
                'mobile'    => $validated['mobile'] ?? null,
                'is_active' => $validated['is_active'] ?? null,
            ], fn ($v) => $v !== null);

            if (!empty($ownerFields)) {
                $owner->update($ownerFields);
            }

            // PIN is hashed by the model cast; only update when explicitly sent
            if (isset($validated['new_pin'])) {
                $owner->update(['pin' => $validated['new_pin']]);
            }

            // Update Farm fields
            $farm = Farm::find($owner->farm_id);
            if ($farm) {
                $farmFields = array_filter([
                    'name'         => $validated['farm_name'] ?? null,
                    'address_line' => $validated['address_line'] ?? null,
                    'city'         => $validated['city'] ?? null,
                    'state'        => $validated['state'] ?? null,
                    'zip'          => $validated['zip'] ?? null,
                ], fn ($v) => $v !== null);

                if (!empty($farmFields)) {
                    $farm->update($farmFields);
                }

                // Always write gst_number when the key is present (even as null to allow clearing)
                if (array_key_exists('gst_number', $validated)) {
                    $settings = is_array($farm->document_settings) ? $farm->document_settings : [];
                    $settings['gst_number'] = $validated['gst_number'];
                    $farm->update(['document_settings' => $settings]);
                }
            }
        });

        $owner->refresh();

        return response()->json([
            'success' => true,
            'data'    => $this->buildTenantDetail($owner),
        ]);
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    /**
     * Builds the full tenant detail payload shared by show() and all plan-action
     * endpoints.  Kept in one place so all actions return an identical shape.
     */
    private function buildTenantDetail(FarmOwner $owner): array
    {
        $assignment = TenantPlanAssignment::with('subscriptionPlan')
            ->where('owner_id', $owner->id)
            ->first();

        $farm = Farm::find($owner->farm_id);

        // --- Usage counters (from existing tables, read-only) ----------------
        $customerCount     = $farm ? Customer::where('farm_id', $farm->id)->count() : 0;
        $subscriptionCount = $farm ? Subscription::where('farm_id', $farm->id)->count() : 0;

        // --- Payment summary -------------------------------------------------
        $payments = SaasPayment::where('owner_id', $owner->id)
            ->orderByDesc('payment_date')
            ->get();

        $totalPaid    = $payments->sum('amount');
        $lastPayment  = $payments->first();

        $outstandingBalance = $this->computeOutstandingBalance(
            $owner->id,
            $assignment?->start_date,
            (float) $totalPaid
        );

        // --- Payment history (last 10, not soft-deleted) ---------------------
        $paymentHistory = $payments->take(10)->map(fn ($p) => [
            'id'             => $p->id,
            'amount'         => $p->amount,
            'payment_date'   => $p->payment_date?->toDateString(),
            'due_date'       => $p->due_date?->toDateString(),
            'payment_method' => $p->payment_method,
            'paid_by_name'   => $p->paid_by_name,
            'reference'      => $p->reference,
            'notes'          => $p->notes,
            'created_at'     => $p->created_at,
        ]);

        // --- Activity trail from plan_change_log JSON -----------------------
        $activityTrail = collect($assignment?->plan_change_log ?? [])
            ->map(fn ($entry) => [
                'action'     => $entry['type'] ?? null,
                'from_plan'  => $entry['from_plan_name'] ?? null,
                'to_plan'    => $entry['to_plan_name'] ?? null,
                'changed_at' => $entry['changed_at'] ?? null,
                'reason'     => $entry['reason'] ?? null,
            ])
            ->values();

        // --- Days until renewal ----------------------------------------------
        $daysUntilRenewal = null;
        if ($assignment?->renewal_date) {
            $daysUntilRenewal = (int) now()->startOfDay()->diffInDays(
                $assignment->renewal_date->startOfDay(),
                false
            );
        }

        return [
            'profile' => [
                'id'           => $owner->id,
                'name'         => $owner->name,
                'phone'        => $owner->mobile,
                'email'        => null, // FarmOwner model does not store email
                'is_active'    => (bool) $owner->is_active,
                'farm_name'    => $farm?->name,
                'address_line' => $farm?->address_line,
                'city'         => $farm?->city,
                'state'        => $farm?->state,
                'zip'          => $farm?->zip,
                'gst_number'   => is_array($farm?->document_settings) ? ($farm->document_settings['gst_number'] ?? null) : null,
                'created_at'   => $owner->created_at,
            ],
            'current_plan' => $assignment ? [
                'plan_name'        => $assignment->subscriptionPlan?->name,
                'status'           => $assignment->status,
                'start_date'       => $assignment->start_date?->toDateString(),
                'renewal_date'     => $assignment->renewal_date?->toDateString(),
                'days_until_renewal' => $daysUntilRenewal,
                'paused_at'        => $assignment->paused_at?->toIso8601String(),
            ] : null,
            'usage' => [
                'customer_count'     => $customerCount,
                'subscription_count' => $subscriptionCount,
            ],
            'plan_limits' => $assignment?->subscriptionPlan ? [
                'max_customers'     => $assignment->subscriptionPlan->max_customers,
                'max_subscriptions' => $assignment->subscriptionPlan->max_subscriptions,
            ] : null,
            'payment_summary' => [
                'last_paid_date'      => $lastPayment?->payment_date?->toDateString(),
                'last_paid_amount'    => $lastPayment ? (float) $lastPayment->amount : null,
                'outstanding_balance' => $outstandingBalance,
                'total_paid_ever'     => (float) $totalPaid,
            ],
            'payment_history' => $paymentHistory,
            'activity_trail'  => $activityTrail,
        ];
    }

    /**
     * Computes outstanding balance for a tenant.
     *
     * Formula: sum of plan fees billed since start_date − total SaaS payments recorded.
     *
     * Billing cycles elapsed = floor(days_since_start / cycle_days).
     * We use plan price × cycles as the billed amount.
     * If no assignment exists the balance is 0.
     */
    private function computeOutstandingBalance(int $ownerId, mixed $startDate, float $totalPaid): float
    {
        if ($startDate === null) {
            return 0.0;
        }

        $assignment = TenantPlanAssignment::with('subscriptionPlan')
            ->where('owner_id', $ownerId)
            ->first();

        if ($assignment === null || $assignment->subscriptionPlan === null) {
            return 0.0;
        }

        $start     = $startDate instanceof Carbon ? $startDate : Carbon::parse($startDate);
        $cycledays = $this->billingCycleDays($assignment->subscriptionPlan->billing_cycle);
        $elapsed   = max(0, (int) $start->startOfDay()->diffInDays(now()->startOfDay(), false));
        $cycles    = $cycledays > 0 ? (int) floor($elapsed / $cycledays) + 1 : 1;
        $totalBilled = $cycles * (float) $assignment->subscriptionPlan->price;

        return max(0.0, round($totalBilled - $totalPaid, 2));
    }

    /**
     * Returns approximate days in the given billing cycle.
     * Used only for outstanding-balance approximation; not for exact date math.
     */
    private function billingCycleDays(string $cycle): int
    {
        return match ($cycle) {
            'monthly'     => 30,
            'quarterly'   => 90,
            'half_yearly' => 180,
            'yearly'      => 365,
            default       => 30,
        };
    }

    /**
     * Calculates the due/renewal date from a given start date and billing cycle.
     *
     * Uses Carbon's exact calendar arithmetic (addMonth, addMonths, addYear)
     * to avoid cumulative drift on repeated renewals.
     */
    private function calculateDueDate(Carbon $from, string $billingCycle): Carbon
    {
        return match ($billingCycle) {
            'monthly'     => $from->copy()->addMonth(),
            'quarterly'   => $from->copy()->addMonths(3),
            'half_yearly' => $from->copy()->addMonths(6),
            'yearly'      => $from->copy()->addYear(),
            default       => $from->copy()->addMonth(),
        };
    }

    /** Returns a standard 404 JSON response. */
    private function notFound(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'error'   => [
                'code'    => 'TENANT_NOT_FOUND',
                'message' => 'No tenant found with the given ID.',
            ],
        ], 404);
    }
}
