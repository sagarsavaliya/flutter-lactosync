<?php

namespace App\Models;

use App\Enums\DeliveryShift;
use App\Enums\OrderLogStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class DailyOrderLog extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'farm_id',
        'customer_id',
        'subscription_id',
        'subscription_line_id',
        'product_id',
        'product_name',
        'quantity',
        'unit_rate',
        'line_total',
        'shift',
        'status',
        'delivery_date',
        'billing_month',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'decimal:2',
            'unit_rate' => 'decimal:2',
            'line_total' => 'decimal:2',
            'shift' => DeliveryShift::class,
            'status' => OrderLogStatus::class,
            'delivery_date' => 'date',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class);
    }

    public function subscriptionLine(): BelongsTo
    {
        return $this->belongsTo(SubscriptionLine::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public static function billingMonthFor(\DateTimeInterface $date): string
    {
        return $date->format('Y-m');
    }

    public static function computeLineTotal(float $quantity, float $unitRate): float
    {
        return round($quantity * $unitRate, 2);
    }
}
