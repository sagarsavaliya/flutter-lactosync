<?php

namespace App\Models;

use App\Enums\DeliveryShift;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubscriptionLine extends Model
{
    protected $fillable = [
        'subscription_id',
        'product_id',
        'quantity',
        'unit_rate',
        'coupon_amount',
        'effective_rate',
        'shift',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'decimal:2',
            'unit_rate' => 'decimal:2',
            'coupon_amount' => 'decimal:2',
            'effective_rate' => 'decimal:2',
            'shift' => DeliveryShift::class,
        ];
    }

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public static function computeEffectiveRate(float $unitRate, float $couponAmount): float
    {
        return max(0, round($unitRate - $couponAmount, 2));
    }
}
