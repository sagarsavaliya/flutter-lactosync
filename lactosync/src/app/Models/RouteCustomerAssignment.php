<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RouteCustomerAssignment extends Model
{
    public const STANDING_DATE = '1970-01-01';

    protected $fillable = [
        'route_id',
        'customer_id',
        'sort_order',
        'assigned_date',
    ];

    protected function casts(): array
    {
        return [
            'assigned_date' => 'date',
            'sort_order'    => 'integer',
        ];
    }

    public function isStanding(): bool
    {
        return $this->assigned_date?->toDateString() === self::STANDING_DATE;
    }

    public function route(): BelongsTo
    {
        return $this->belongsTo(DeliveryRoute::class, 'route_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
