<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FarmContainerTypeVisibility extends Model
{
    protected $table = 'farm_container_type_visibility';

    // No updated_at — hiding is a toggle (insert to hide, delete to unhide)
    public $timestamps = false;

    protected $fillable = [
        'farm_id',
        'container_type_id',
    ];
}
