<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'farm_id',
        'name',
        'milk_type',          // retained (nullable) for rollback safety; use milk_type_id going forward
        'milk_type_id',
        'rate',
        'unit',
        'container_type',     // retained (nullable) for rollback safety; use container_type_id going forward
        'container_type_id',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'rate'      => 'decimal:2',
            'is_active' => 'boolean',
            // milk_type and container_type are now plain nullable strings (enum casts removed)
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function milkType(): BelongsTo
    {
        return $this->belongsTo(MilkType::class, 'milk_type_id');
    }

    public function containerType(): BelongsTo
    {
        return $this->belongsTo(ContainerType::class, 'container_type_id');
    }

    public function subscriptionLines(): HasMany
    {
        return $this->hasMany(SubscriptionLine::class);
    }
}
