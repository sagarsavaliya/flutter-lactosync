<?php

namespace App\Models;

use App\Enums\OnboardingStep;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class FarmOwner extends Authenticatable
{
    use HasApiTokens, SoftDeletes;

    protected $fillable = [
        'farm_id',
        'name',
        'first_name',
        'last_name',
        'mobile',
        'pin',
        'is_active',
        'onboarding_step',
        'mobile_verified_at',
        'last_login_at',
    ];

    protected $hidden = [
        'pin',
    ];

    protected function casts(): array
    {
        return [
            'pin' => 'hashed',
            'is_active' => 'boolean',
            'onboarding_step' => OnboardingStep::class,
            'mobile_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function fullName(): string
    {
        if ($this->first_name || $this->last_name) {
            return trim("{$this->first_name} {$this->last_name}");
        }

        return (string) $this->name;
    }

    public function syncLegacyName(): void
    {
        $full = $this->fullName();
        if ($full !== '' && $this->name !== $full) {
            $this->forceFill(['name' => $full])->saveQuietly();
        }
    }
}
