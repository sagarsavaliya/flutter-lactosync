<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductOfferedSize extends Model
{
    protected $table = 'product_offered_sizes';

    protected $fillable = ['product_id', 'size_liters'];

    protected function casts(): array
    {
        return [
            'size_liters' => 'decimal:4',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
