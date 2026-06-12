<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;

class DeliveryRoute extends Model
{
    protected $fillable = [
        'farm_id',
        'name',
        'shift',
        'sort_order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active'  => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function customerAssignments(): HasMany
    {
        return $this->hasMany(RouteCustomerAssignment::class, 'route_id');
    }

    public function deliveryBoyAssignments(): HasMany
    {
        return $this->hasMany(DeliveryBoyRouteAssignment::class, 'route_id');
    }
}
