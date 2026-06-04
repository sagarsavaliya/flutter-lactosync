<?php

namespace App\Models;

use App\Enums\ContainerType;
use App\Enums\MilkType;
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
        'milk_type',
        'rate',
        'unit',
        'container_type',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'milk_type' => MilkType::class,
            'container_type' => ContainerType::class,
            'rate' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function subscriptionLines(): HasMany
    {
        return $this->hasMany(SubscriptionLine::class);
    }
}
