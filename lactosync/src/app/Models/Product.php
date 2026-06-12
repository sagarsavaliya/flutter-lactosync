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
        'milk_type_id',
        'rate',
        'unit',
        'container_type_id',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'rate'      => 'decimal:2',
            'is_active' => 'boolean',
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

    public function offeredSizes(): HasMany
    {
        return $this->hasMany(ProductOfferedSize::class)->orderBy('size_liters');
    }

    public function subscriptionLines(): HasMany
    {
        return $this->hasMany(SubscriptionLine::class);
    }
}
