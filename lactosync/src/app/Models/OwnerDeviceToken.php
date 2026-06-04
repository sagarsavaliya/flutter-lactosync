<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OwnerDeviceToken extends Model
{
    protected $fillable = [
        'farm_owner_id',
        'token',
        'platform',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(FarmOwner::class, 'farm_owner_id');
    }
}
