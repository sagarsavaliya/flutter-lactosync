<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FarmActivityLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'farm_id',
        'farm_owner_id',
        'action',
        'entity_type',
        'entity_id',
        'entity_label',
        'meta',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'meta' => 'array',
            'created_at' => 'datetime',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(FarmOwner::class, 'farm_owner_id');
    }
}
