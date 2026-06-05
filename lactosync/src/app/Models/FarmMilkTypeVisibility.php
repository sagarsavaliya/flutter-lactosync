<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FarmMilkTypeVisibility extends Model
{
    protected $table = 'farm_milk_type_visibility';

    // No updated_at — hiding is a toggle (insert to hide, delete to unhide)
    public $timestamps = false;

    protected $fillable = [
        'farm_id',
        'milk_type_id',
    ];
}
