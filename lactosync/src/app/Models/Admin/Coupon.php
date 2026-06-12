<?php

namespace App\Models\Admin;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Coupon extends Model
{
    protected $fillable = [
        'code',
        'title',
        'type',
        'value',
        'max_redemptions',
        'redemption_count',
        'is_active',
        'expires_at',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'is_active'       => 'boolean',
        'expires_at'      => 'date',
        'value'           => 'integer',
        'max_redemptions' => 'integer',
        'redemption_count'=> 'integer',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'created_by');
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(TenantCouponRedemption::class, 'coupon_id');
    }

    /** True if this coupon can still be redeemed. */
    public function isRedeemable(): bool
    {
        if (!$this->is_active) {
            return false;
        }
        if ($this->expires_at && $this->expires_at->isPast()) {
            return false;
        }
        if ($this->max_redemptions !== null && $this->redemption_count >= $this->max_redemptions) {
            return false;
        }
        return true;
    }
}
