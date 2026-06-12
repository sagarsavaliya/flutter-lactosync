<?php

namespace App\Models\Admin;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\HasApiTokens;

/**
 * Super-admin account for the Tenant Admin Web App.
 * Guard: 'admin' (separate from the owner 'sanctum' guard).
 * PIN is stored as a bcrypt hash and never returned in responses.
 */
class AdminUser extends Authenticatable
{
    use HasApiTokens;

    protected $table = 'admin_users';

    protected $fillable = [
        'name',
        'email',
        'pin_hash',
        'failed_attempts',
        'locked_until',
        'last_login_at',
        'is_active',
    ];

    /** PIN hash is always excluded from serialisation and API responses. */
    protected $hidden = ['pin_hash'];

    protected $casts = [
        'failed_attempts' => 'integer',
        'locked_until'    => 'datetime',
        'last_login_at'   => 'datetime',
        'is_active'       => 'boolean',
    ];

    // -------------------------------------------------------------------------
    // Auth helpers
    // -------------------------------------------------------------------------

    /**
     * Verify a plain-text PIN against the stored bcrypt hash.
     * The raw PIN is never stored or logged.
     */
    public function verifyPin(string $pin): bool
    {
        return Hash::check($pin, $this->pin_hash);
    }

    /**
     * Returns true when the account is currently locked out (locked_until is
     * non-null and still in the future).
     */
    public function isLocked(): bool
    {
        return $this->locked_until !== null
            && $this->locked_until->isFuture();
    }

    /**
     * Record a single failed PIN attempt.
     * After 5 consecutive failures the account is locked for 15 minutes and
     * the counter resets so the window starts fresh after the lockout expires.
     */
    public function recordFailedAttempt(): void
    {
        $this->increment('failed_attempts');
        $this->refresh();

        if ($this->failed_attempts >= 5) {
            $this->update([
                'locked_until'    => now()->addMinutes(15),
                'failed_attempts' => 0,
            ]);
        }
    }

    /**
     * Clear lockout state after a successful login.
     */
    public function clearLockout(): void
    {
        $this->update([
            'failed_attempts' => 0,
            'locked_until'    => null,
        ]);
    }
}
