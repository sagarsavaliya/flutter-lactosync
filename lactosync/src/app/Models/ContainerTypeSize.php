<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ContainerTypeSize extends Model
{
    protected $table = 'container_type_sizes';

    protected $fillable = ['container_type_id', 'size_liters'];

    protected function casts(): array
    {
        return [
            'size_liters' => 'decimal:2',
        ];
    }

    public $timestamps = true;

    public function containerType(): BelongsTo
    {
        return $this->belongsTo(ContainerType::class);
    }
}
