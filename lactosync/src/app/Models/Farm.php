<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Farm extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'name',
        'address_line',
        'city',
        'state',
        'zip',
        'subscription_plan',
        'subscription_status',
        'timezone',
        'onboarding_completed_at',
        'document_settings',
        'morning_order_time',
        'evening_order_time',
        'upi_vpa',
        'upi_payee_name',
        'prefill_customer_address',
    ];

    protected function casts(): array
    {
        return [
            'onboarding_completed_at' => 'datetime',
            'document_settings' => 'array',
            'prefill_customer_address' => 'boolean',
        ];
    }

    public function owner(): HasOne
    {
        return $this->hasOne(FarmOwner::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(Customer::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }
}
