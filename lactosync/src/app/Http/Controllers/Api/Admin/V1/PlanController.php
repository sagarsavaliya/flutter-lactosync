<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StorePlanRequest;
use App\Http\Requests\Admin\UpdatePlanRequest;
use App\Models\Admin\SubscriptionPlan;
use Illuminate\Http\JsonResponse;

/**
 * Admin plan management endpoints (T1-11).
 *
 * All routes are prefixed /api/admin/v1/plans and protected by auth:admin.
 *
 * Business rule (FR-20): price, max_customers, and max_subscriptions are
 * frozen on a plan once at least one active/grace_period/suspended assignment
 * exists. The SubscriptionPlan::isEditable() method is the single source of
 * truth for this check; this controller delegates to it.
 */
class PlanController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/v1/plans
    // -------------------------------------------------------------------------

    /**
     * Returns all plans (including archived), ordered so non-archived plans
     * come first, then by created_at descending within each group.
     *
     * Each plan includes an active_tenant_count: the number of
     * TenantPlanAssignment rows for this plan whose status is one of
     * active, grace_period, or suspended.
     */
    public function index(): JsonResponse
    {
        $plans = SubscriptionPlan::query()
            ->withCount([
                'assignments as active_tenant_count' => function ($query): void {
                    $query->whereIn('status', ['active', 'grace_period', 'suspended']);
                },
            ])
            ->orderBy('is_archived', 'asc')      // non-archived (0) first
            ->orderBy('created_at', 'desc')
            ->get();

        // Batch-load module slugs so we don't N+1.
        $planIds = $plans->pluck('id')->all();
        $modulesByPlan = \Illuminate\Support\Facades\DB::table('plan_modules')
            ->whereIn('subscription_plan_id', $planIds)
            ->get(['subscription_plan_id', 'module_slug'])
            ->groupBy('subscription_plan_id')
            ->map(fn ($rows) => $rows->pluck('module_slug')->all());

        $formatted = $plans->map(fn (SubscriptionPlan $plan) =>
            $this->formatPlan($plan, $modulesByPlan->get($plan->id, []))
        );

        return response()->json([
            'success' => true,
            'data'    => $formatted,
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/plans
    // -------------------------------------------------------------------------

    /**
     * Creates a new subscription plan.
     *
     * Returns 201 on success, 422 on validation failure (handled by FormRequest).
     */
    public function store(StorePlanRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $modules   = $validated['modules'] ?? [];
        unset($validated['modules']);

        $plan = SubscriptionPlan::create($validated);
        $plan->syncModules($modules);

        $plan->loadCount([
            'assignments as active_tenant_count' => function ($query): void {
                $query->whereIn('status', ['active', 'grace_period', 'suspended']);
            },
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatPlan($plan, $modules),
        ], 201);
    }

    // -------------------------------------------------------------------------
    // PUT /api/admin/v1/plans/{plan}
    // -------------------------------------------------------------------------

    /**
     * Updates a plan.
     *
     * name and description are always editable.
     * price, max_customers, max_subscriptions are only editable when
     * isEditable() is true (no active/grace/suspended assignments).
     *
     * Returns 422 with a clear message if frozen fields are sent on a plan
     * that has active assignments.
     */
    public function update(UpdatePlanRequest $request, SubscriptionPlan $plan): JsonResponse
    {
        if ($request->hasFrozenFields() && ! $plan->isEditable()) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'PLAN_NOT_EDITABLE',
                    'message' => 'Cannot change price or limits while this plan has active tenant assignments.',
                ],
            ], 422);
        }

        $validated = $request->validated();
        $modules   = array_key_exists('modules', $validated) ? $validated['modules'] : null;
        unset($validated['modules']);

        // When the plan is not editable, silently strip frozen fields even if
        // the caller somehow passed validation (belt-and-suspenders guard).
        if (! $plan->isEditable()) {
            unset($validated['price'], $validated['max_customers'], $validated['max_subscriptions']);
        }

        $plan->update($validated);

        if ($modules !== null) {
            $plan->syncModules($modules);
        }

        $plan->loadCount([
            'assignments as active_tenant_count' => function ($query): void {
                $query->whereIn('status', ['active', 'grace_period', 'suspended']);
            },
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatPlan($plan, $plan->moduleSlugList()),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/plans/{plan}/archive
    // -------------------------------------------------------------------------

    /**
     * Archives a plan so it can no longer be assigned to new tenants.
     *
     * Existing tenant assignments are NOT modified — tenants on this plan
     * keep their assignment until renewal (FR-21).
     *
     * Returns 422 if the plan is already archived.
     */
    public function archive(SubscriptionPlan $plan): JsonResponse
    {
        if ($plan->is_archived) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'ALREADY_ARCHIVED',
                    'message' => 'This plan is already archived.',
                ],
            ], 422);
        }

        $plan->update(['is_archived' => true]);

        $plan->loadCount([
            'assignments as active_tenant_count' => function ($query): void {
                $query->whereIn('status', ['active', 'grace_period', 'suspended']);
            },
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatPlan($plan, $plan->moduleSlugList()),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/plans/{plan}/unarchive
    // -------------------------------------------------------------------------

    /**
     * Restores an archived plan so it can be assigned to new tenants again.
     *
     * Returns 422 if the plan is not currently archived.
     */
    public function unarchive(SubscriptionPlan $plan): JsonResponse
    {
        if (! $plan->is_archived) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'NOT_ARCHIVED',
                    'message' => 'This plan is not archived.',
                ],
            ], 422);
        }

        $plan->update(['is_archived' => false]);

        $plan->loadCount([
            'assignments as active_tenant_count' => function ($query): void {
                $query->whereIn('status', ['active', 'grace_period', 'suspended']);
            },
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatPlan($plan, $plan->moduleSlugList()),
        ]);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Formats a SubscriptionPlan (with active_tenant_count loaded) into
     * the canonical API shape defined by the T1-11 spec.
     *
     * Expects $plan->active_tenant_count to have been loaded via loadCount()
     * or withCount() before this method is called.
     */
    private function formatPlan(SubscriptionPlan $plan, array $modules = []): array
    {
        return [
            'id'                  => $plan->id,
            'name'                => $plan->name,
            'description'         => $plan->description,
            'price'               => $plan->price,
            'billing_cycle'       => $plan->billing_cycle,
            'max_customers'       => $plan->max_customers,
            'max_subscriptions'   => $plan->max_subscriptions,
            'is_archived'         => $plan->is_archived,
            'modules'             => $modules,
            'active_tenant_count' => (int) ($plan->active_tenant_count ?? 0),
            'created_at'          => $plan->created_at?->toIso8601String(),
        ];
    }
}
