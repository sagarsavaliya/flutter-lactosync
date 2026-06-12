<?php

namespace App\Models\Admin;

use App\Models\FarmOwner;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A manually recorded SaaS subscription payment from a tenant to the platform.
 *
 * Completely separate from milk-delivery payments/invoices.
 * Soft-deleted records are excluded from outstanding-balance calculations
 * unless the caller explicitly uses withTrashed().
 * deleted_by must be populated by the controller before soft-deleting (FR-27).
 */
class SaasPayment extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'owner_id',
        'tenant_plan_assignment_id',
        'amount',
        'payment_date',
        'due_date',
        'payment_method',
        'paid_by_name',
        'reference',
        'notes',
        'recorded_by',
        'edited_by',
        'deleted_by',
    ];

    protected function casts(): array
    {
        return [
            'amount'       => 'decimal:2',
            'payment_date' => 'date',
            'due_date'     => 'date',
        ];
    }

    // -------------------------------------------------------------------------
    // Scopes
    // -------------------------------------------------------------------------

    /** Narrows the query to payments for a single tenant. */
    public function scopeForTenant(Builder $query, int $ownerId): Builder
    {
        return $query->where('owner_id', $ownerId);
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    /** Read-only reference to the existing farm_owners table. */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(FarmOwner::class, 'owner_id');
    }

    public function tenantPlanAssignment(): BelongsTo
    {
        return $this->belongsTo(TenantPlanAssignment::class);
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'recorded_by');
    }

    public function editedBy(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'edited_by');
    }

    public function deletedBy(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'deleted_by');
    }
}
