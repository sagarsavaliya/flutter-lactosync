<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Http\Controllers\Controller;
use App\Models\Admin\Coupon;
use App\Models\Admin\TenantCouponRedemption;
use App\Models\Admin\TenantPlanAssignment;
use App\Models\FarmOwner;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Admin Coupon Management API
 *
 * Endpoints:
 *   GET    /api/admin/v1/coupons                          — list all coupons
 *   POST   /api/admin/v1/coupons                          — create coupon
 *   PATCH  /api/admin/v1/coupons/{id}/toggle-active       — enable / disable
 *   POST   /api/admin/v1/tenants/{id}/apply-coupon        — apply coupon to tenant
 */
class CouponController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/v1/coupons
    // -------------------------------------------------------------------------

    public function index(): JsonResponse
    {
        $coupons = Coupon::with('creator:id,email')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (Coupon $c) => $this->formatCoupon($c));

        return response()->json([
            'success' => true,
            'data'    => $coupons,
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/coupons
    // -------------------------------------------------------------------------

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title'           => ['required', 'string', 'max:150'],
            'type'            => ['required', 'string', 'in:free_months'],
            'value'           => ['required', 'integer', 'min:1', 'max:12'],
            'max_redemptions' => ['nullable', 'integer', 'min:1'],
            'expires_at'      => ['nullable', 'date', 'after:today'],
            'notes'           => ['nullable', 'string', 'max:500'],
        ]);

        $coupon = Coupon::create([
            ...$validated,
            'code'       => strtoupper(Str::random(8)),
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatCoupon($coupon),
        ], 201);
    }

    // -------------------------------------------------------------------------
    // PATCH /api/admin/v1/coupons/{id}/toggle-active
    // -------------------------------------------------------------------------

    public function toggleActive(int $id): JsonResponse
    {
        $coupon = Coupon::find($id);

        if ($coupon === null) {
            return $this->notFoundCoupon();
        }

        $coupon->update(['is_active' => !$coupon->is_active]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatCoupon($coupon->fresh()),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/v1/tenants/{id}/apply-coupon
    // -------------------------------------------------------------------------

    /**
     * Apply a coupon to a tenant.
     *
     * For 'free_months' coupons this extends the tenant's plan renewal_date
     * by the coupon's value in months, then records the redemption.
     *
     * Request: { coupon_code: string, notes?: string }
     */
    public function applyToTenant(Request $request, int $tenantId): JsonResponse
    {
        $owner = FarmOwner::find($tenantId);

        if ($owner === null) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'TENANT_NOT_FOUND', 'message' => 'No tenant found with the given ID.'],
            ], 404);
        }

        $validated = $request->validate([
            'coupon_code' => ['required', 'string'],
            'notes'       => ['nullable', 'string', 'max:500'],
        ]);

        $coupon = Coupon::where('code', strtoupper(trim($validated['coupon_code'])))->first();

        if ($coupon === null) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'COUPON_NOT_FOUND', 'message' => 'No coupon found with that code.'],
            ], 404);
        }

        if (!$coupon->isRedeemable()) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'COUPON_NOT_REDEEMABLE', 'message' => 'This coupon is no longer active, has expired, or has reached its redemption limit.'],
            ], 422);
        }

        // One redemption per tenant per coupon
        $alreadyRedeemed = TenantCouponRedemption::where('coupon_id', $coupon->id)
            ->where('owner_id', $owner->id)
            ->exists();

        if ($alreadyRedeemed) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'ALREADY_REDEEMED', 'message' => 'This coupon has already been applied to this tenant.'],
            ], 409);
        }

        $assignment = TenantPlanAssignment::where('owner_id', $owner->id)->first();

        DB::transaction(function () use ($coupon, $owner, $assignment, $validated, $request) {
            if ($coupon->type === 'free_months' && $assignment !== null) {
                // Extend renewal_date and due_date by the coupon value (months)
                $newRenewal = Carbon::parse($assignment->renewal_date)->addMonths($coupon->value);
                $assignment->update([
                    'renewal_date'     => $newRenewal->toDateString(),
                    'due_date'         => $newRenewal->toDateString(),
                    'grace_expires_at' => $newRenewal->copy()->addDays(5)->toDateString(),
                ]);

                $assignment->logPlanChange([
                    'type'               => 'coupon_applied',
                    'from_plan_id'       => $assignment->subscription_plan_id,
                    'from_plan_name'     => $assignment->subscriptionPlan?->name,
                    'to_plan_id'         => $assignment->subscription_plan_id,
                    'to_plan_name'       => $assignment->subscriptionPlan?->name,
                    'changed_by_admin_id'=> $request->user()->id,
                    'reason'             => "Coupon '{$coupon->code}' applied — {$coupon->value} free month(s)",
                ]);
            }

            TenantCouponRedemption::create([
                'coupon_id'     => $coupon->id,
                'owner_id'      => $owner->id,
                'applied_months'=> $coupon->type === 'free_months' ? $coupon->value : 0,
                'notes'         => $validated['notes'] ?? null,
                'applied_by'    => $request->user()->id,
            ]);

            $coupon->increment('redemption_count');
        });

        return response()->json([
            'success' => true,
            'data'    => [
                'coupon'        => $this->formatCoupon($coupon->fresh()),
                'months_granted'=> $coupon->type === 'free_months' ? $coupon->value : 0,
                'new_renewal'   => $assignment?->fresh()->renewal_date?->toDateString(),
            ],
        ]);
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    private function formatCoupon(Coupon $c): array
    {
        return [
            'id'               => $c->id,
            'code'             => $c->code,
            'title'            => $c->title,
            'type'             => $c->type,
            'value'            => $c->value,
            'max_redemptions'  => $c->max_redemptions,
            'redemption_count' => $c->redemption_count,
            'is_active'        => $c->is_active,
            'is_redeemable'    => $c->isRedeemable(),
            'expires_at'       => $c->expires_at?->toDateString(),
            'notes'            => $c->notes,
            'created_by_email' => $c->creator?->email,
            'created_at'       => $c->created_at,
        ];
    }

    private function notFoundCoupon(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'error'   => ['code' => 'COUPON_NOT_FOUND', 'message' => 'No coupon found with the given ID.'],
        ], 404);
    }
}
