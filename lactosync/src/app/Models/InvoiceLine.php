<?php

namespace App\Models;

use App\Enums\DeliveryShift;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InvoiceLine extends Model
{
    protected $fillable = [
        'invoice_id',
        'subscription_id',
        'product_id',
        'product_name',
        'shift',
        'delivery_days',
        'total_quantity',
        'unit_rate',
        'line_total',
    ];

    protected function casts(): array
    {
        return [
            'shift' => DeliveryShift::class,
            'total_quantity' => 'decimal:2',
            'unit_rate' => 'decimal:2',
            'line_total' => 'decimal:2',
        ];
    }

    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class);
    }

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
