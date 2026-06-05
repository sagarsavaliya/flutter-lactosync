<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MilkType extends Model
{
    protected $table = 'milk_types';

    protected $fillable = [
        'farm_id',
        'name',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class, 'milk_type_id');
    }

    /**
     * Scope: return system defaults NOT hidden by this farm,
     * plus this farm's own custom entries.
     */
    public function scopeVisibleToFarm(Builder $query, int $farmId): Builder
    {
        return $query->where(function (Builder $q) use ($farmId) {
            // System defaults that this farm has NOT hidden
            $q->whereNull('farm_id')
              ->whereNotIn('id', function ($sub) use ($farmId) {
                  $sub->select('milk_type_id')
                      ->from('farm_milk_type_visibility')
                      ->where('farm_id', $farmId);
              });
        })->orWhere('farm_id', $farmId);
    }
}
