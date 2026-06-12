<?php

namespace App\Models\Admin;

use App\Models\FarmOwner;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Live contract linking one tenant (farm_owners row) to one subscription_plan.
 *
 * One row per tenant — updated in place as the contract evolves.
 * Plan-change history is appended to plan_change_log (JSON array).
 *
 * The subscription-enforcement middleware reads this row to decide
 * active / grace_period / suspended / paused / expired / no_plan.
 */
class TenantPlanAssignment extends Model
{
    protected $fillable = [
        'owner_id',
        'subscription_plan_id',
        'status',
        'start_date',
        'renewal_date',
        'due_date',
        'grace_expires_at',
        'suspended_at',
        'paused_at',
        'resumed_at',
        'paused_by',
        'resumed_by',
        'assigned_by',
        'plan_change_log',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'start_date'       => 'date',
            'renewal_date'     => 'date',
            'due_date'         => 'date',
            'grace_expires_at' => 'date',
            'suspended_at'     => 'datetime',
            'paused_at'        => 'datetime',
            'resumed_at'       => 'datetime',
            'plan_change_log'  => 'array',
        ];
    }

    // -------------------------------------------------------------------------
    // Status helpers
    // -------------------------------------------------------------------------

    public function isInGrace(): bool
    {
        return $this->status === 'grace_period';
    }

    public function isSuspended(): bool
    {
        return $this->status === 'suspended';
    }

    // -------------------------------------------------------------------------
    // Plan-change audit log
    // -------------------------------------------------------------------------

    /**
     * Appends one entry to the plan_change_log JSON array and persists the row.
     *
     * Expected entry keys:
     *   from_plan_id, to_plan_id, from_plan_name, to_plan_name,
     *   changed_by_admin_id, reason, type
     *   (changed_at is added automatically as ISO 8601 UTC)
     */
    public function logPlanChange(array $entry): void
    {
        $entry['changed_at'] = now()->toIso8601String();

        $log   = $this->plan_change_log ?? [];
        $log[] = $entry;

        $this->plan_change_log = $log;
        $this->save();
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function subscriptionPlan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class);
    }

    /** Read-only relationship back to the existing farm_owners table. */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(FarmOwner::class, 'owner_id');
    }

    public function pausedBy(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'paused_by');
    }

    public function resumedBy(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'resumed_by');
    }

    public function assignedBy(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'assigned_by');
    }
}
