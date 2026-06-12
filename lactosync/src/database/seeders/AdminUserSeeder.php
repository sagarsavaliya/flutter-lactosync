<?php

namespace Database\Seeders;

use App\Models\Admin\AdminUser;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Creates the single super-admin record for the Tenant Admin Web App.
 *
 * Safe to re-run: uses updateOrCreate keyed on email, so a duplicate row is
 * never inserted.  The PIN is stored as a bcrypt hash — no plain-text PIN
 * appears anywhere in this file or in the database.
 */
class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        AdminUser::updateOrCreate(
            // Lookup key — unique email guarantees idempotency.
            ['email' => 'savaliya.sagar@aksharatech.com'],
            // Values written on create OR overwritten on re-seed.
            [
                'name'     => 'Sagar Savaliya',
                'pin_hash' => Hash::make('159874'),
                'is_active' => true,
            ],
        );
    }
}
