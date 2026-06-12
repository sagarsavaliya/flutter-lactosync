<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class DeliveryBoy extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = [
        'farm_id',
        'name',
        'phone',
        'pin_hash',
        'salary_type',
        'salary_amount',
        'is_active',
    ];

    protected $hidden = ['pin_hash'];

    protected function casts(): array
    {
        return [
            'is_active'     => 'boolean',
            'salary_amount' => 'decimal:2',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function routeAssignments(): HasMany
    {
        return $this->hasMany(DeliveryBoyRouteAssignment::class);
    }
}
