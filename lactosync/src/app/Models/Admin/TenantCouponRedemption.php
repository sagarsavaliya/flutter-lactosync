<?php

namespace App\Models\Admin;

use App\Models\FarmOwner;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TenantCouponRedemption extends Model
{
    protected $fillable = [
        'coupon_id',
        'owner_id',
        'applied_months',
        'notes',
        'applied_by',
    ];

    protected $casts = [
        'applied_months' => 'integer',
    ];

    public function coupon(): BelongsTo
    {
        return $this->belongsTo(Coupon::class);
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(FarmOwner::class, 'owner_id');
    }

    public function appliedByAdmin(): BelongsTo
    {
        return $this->belongsTo(AdminUser::class, 'applied_by');
    }
}
