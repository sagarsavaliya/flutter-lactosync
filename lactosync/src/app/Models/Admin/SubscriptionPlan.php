<?php

namespace App\Models\Admin;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A SaaS pricing tier that the operator creates and assigns to tenants.
 *
 * Immutable constraint (FR-20): price, max_customers, and max_subscriptions
 * must not be edited when at least one active assignment exists. Enforced by
 * isEditable() — controllers must check this before updating those fields.
 */
class SubscriptionPlan extends Model
{
    protected $fillable = [
        'name',
        'description',
        'price',
        'billing_cycle',
        'max_customers',
        'max_subscriptions',
        'is_archived',
    ];

    protected function casts(): array
    {
        return [
            'price'       => 'decimal:2',
            'is_archived' => 'boolean',
        ];
    }

    // -------------------------------------------------------------------------
    // Scopes
    // -------------------------------------------------------------------------

    /** Returns only plans that have not been archived. */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_archived', false);
    }

    // -------------------------------------------------------------------------
    // Business rules
    // -------------------------------------------------------------------------

    /**
     * Returns false when any tenant is on this plan in an active, grace-period,
     * or suspended state — meaning price and feature limits are frozen (FR-20).
     */
    public function isEditable(): bool
    {
        return ! TenantPlanAssignment::where('subscription_plan_id', $this->id)
            ->whereIn('status', ['active', 'grace_period', 'suspended'])
            ->exists();
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function assignments(): HasMany
    {
        return $this->hasMany(TenantPlanAssignment::class);
    }
}
