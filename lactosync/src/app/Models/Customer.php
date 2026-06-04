<?php

namespace App\Models;

use App\Models\SubscriptionLine;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\SoftDeletes;

class Customer extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'farm_id',
        'first_name',
        'last_name',
        'address_line',
        'area',
        'landmark',
        'city',
        'state',
        'zip',
        'contact',
        'whatsapp_enabled',
        'secondary_contact',
        'is_active',
        'vacation_start',
        'vacation_end',
    ];

    protected function casts(): array
    {
        return [
            'whatsapp_enabled' => 'boolean',
            'is_active' => 'boolean',
            'vacation_start' => 'date',
            'vacation_end' => 'date',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function subscriptionLines(): HasManyThrough
    {
        return $this->hasManyThrough(
            SubscriptionLine::class,
            Subscription::class,
            'customer_id',
            'subscription_id',
        );
    }

    public function dailyOrderLogs(): HasMany
    {
        return $this->hasMany(DailyOrderLog::class);
    }

    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function fullName(): string
    {
        return trim("{$this->first_name} {$this->last_name}");
    }

    public function isOnVacation(): bool
    {
        if ($this->vacation_start === null || $this->vacation_end === null) {
            return false;
        }

        $today = now()->startOfDay();

        return $today->between(
            $this->vacation_start->startOfDay(),
            $this->vacation_end->startOfDay(),
        );
    }

    public function displayStatus(): string
    {
        if ($this->isOnVacation()) {
            return 'vacation';
        }

        return $this->is_active ? 'active' : 'inactive';
    }

    public function shortAddress(): string
    {
        $parts = array_filter([
            $this->address_line,
            $this->area,
            $this->city,
        ]);

        return implode(', ', $parts);
    }
}
