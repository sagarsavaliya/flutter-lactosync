<?php

namespace App\Http\Middleware;

use App\Models\Admin\TenantPlanAssignment;
use App\Models\Customer;
use App\Models\FarmOwner;
use App\Models\Subscription;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Enforces SaaS subscription rules on every owner API request.
 *
 * Decision table (matches spec — briefs/specs/schema-tenant-admin.md):
 *
 *   active       → pass through; check plan limits on write requests
 *   grace_period → pass through + inject subscription_warning into JSON body
 *   suspended    → 403 SUBSCRIPTION_SUSPENDED
 *   paused       → 403 SUBSCRIPTION_PAUSED
 *   expired      → 403 SUBSCRIPTION_SUSPENDED
 *   no_plan      → pass through (tenant not yet provisioned)
 *   row missing  → pass through (same as no_plan — unprovisioned)
 *
 * Plan-limit checks fire only on POST/PUT/PATCH when the assignment is active.
 * Customer count is scoped to farm_id; Subscription count is scoped to farm_id.
 */
class CheckTenantSubscription
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        // Single indexed read — idx_tpa_owner_status covers this lookup.
        $assignment = TenantPlanAssignment::where('owner_id', $owner->id)
            ->select(['status', 'due_date', 'grace_expires_at', 'suspended_at', 'subscription_plan_id'])
            ->first();

        // No row or no_plan — tenant not yet provisioned; let them through.
        if (! $assignment || $assignment->status === 'no_plan') {
            return $next($request);
        }

        // Suspended or expired — block completely.
        if (in_array($assignment->status, ['suspended', 'expired'], true)) {
            return response()->json([
                'error'        => 'SUBSCRIPTION_SUSPENDED',
                'message'      => 'Your subscription has been suspended due to overdue payment. Please contact support.',
                'due_since'    => $assignment->due_date?->toDateString(),
                'suspended_at' => $assignment->suspended_at?->toISOString(),
            ], 403);
        }

        // Paused — block with a distinct error code.
        if ($assignment->status === 'paused') {
            return response()->json([
                'error'   => 'SUBSCRIPTION_PAUSED',
                'message' => 'Your subscription is currently paused.',
            ], 403);
        }

        // Grace period — allow through but inject a warning into the response body.
        if ($assignment->status === 'grace_period') {
            $daysOverdue        = (int) max(0, now()->diffInDays($assignment->due_date, false) * -1);
            $graceDaysRemaining = (int) max(0, now()->diffInDays($assignment->grace_expires_at, false));

            $response = $next($request);

            return $this->injectSubscriptionWarning($response, [
                'status'               => 'PAYMENT_OVERDUE',
                'days_overdue'         => $daysOverdue,
                'grace_days_remaining' => $graceDaysRemaining,
                'due_date'             => $assignment->due_date?->toDateString(),
            ]);
        }

        // Active — enforce plan feature limits on write operations.
        if ($assignment->status === 'active' && in_array($request->method(), ['POST', 'PUT', 'PATCH'], true)) {
            $limitResponse = $this->checkPlanLimits($request, $owner, $assignment);
            if ($limitResponse !== null) {
                return $limitResponse;
            }
        }

        return $next($request);
    }

    // -------------------------------------------------------------------------
    // Plan-limit enforcement
    // -------------------------------------------------------------------------

    /**
     * Checks max_customers and max_subscriptions plan limits.
     * Returns a 402 response when a limit would be exceeded, null otherwise.
     */
    private function checkPlanLimits(Request $request, FarmOwner $owner, TenantPlanAssignment $assignment): ?Response
    {
        // Load the plan only once and only when needed.
        $plan = $assignment->subscriptionPlan;
        if (! $plan) {
            return null;
        }

        if ($this->isCreateCustomerRequest($request)) {
            $currentCount = Customer::where('farm_id', $owner->farm_id)->count();
            if ($currentCount >= $plan->max_customers) {
                return response()->json([
                    'error'    => 'PLAN_LIMIT_EXCEEDED',
                    'message'  => "Your plan allows a maximum of {$plan->max_customers} customers.",
                    'limit'    => $plan->max_customers,
                    'current'  => $currentCount,
                    'resource' => 'customers',
                ], 402);
            }
        }

        if ($this->isCreateSubscriptionRequest($request)) {
            $currentCount = Subscription::where('farm_id', $owner->farm_id)->count();
            if ($currentCount >= $plan->max_subscriptions) {
                return response()->json([
                    'error'    => 'PLAN_LIMIT_EXCEEDED',
                    'message'  => "Your plan allows a maximum of {$plan->max_subscriptions} milk subscriptions.",
                    'limit'    => $plan->max_subscriptions,
                    'current'  => $currentCount,
                    'resource' => 'subscriptions',
                ], 402);
            }
        }

        return null;
    }

    // -------------------------------------------------------------------------
    // Route-shape helpers
    // -------------------------------------------------------------------------

    /** Matches POST to any path containing "customers" (e.g. /v1/owner/customers). */
    private function isCreateCustomerRequest(Request $request): bool
    {
        return $request->isMethod('POST') && str_contains($request->path(), 'customers');
    }

    /** Matches POST to any path containing "subscriptions". */
    private function isCreateSubscriptionRequest(Request $request): bool
    {
        return $request->isMethod('POST') && str_contains($request->path(), 'subscriptions');
    }

    // -------------------------------------------------------------------------
    // Response helpers
    // -------------------------------------------------------------------------

    /**
     * Merges a subscription_warning key into the JSON response body.
     * Falls back to a plain pass-through if the response is not JSON.
     */
    private function injectSubscriptionWarning(Response $response, array $warning): Response
    {
        if (! $response instanceof JsonResponse) {
            return $response;
        }

        $data = $response->getData(true) ?? [];
        $data['subscription_warning'] = $warning;

        return $response->setData($data);
    }
}
