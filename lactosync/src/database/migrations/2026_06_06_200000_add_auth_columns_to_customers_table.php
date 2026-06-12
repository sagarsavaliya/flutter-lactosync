<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Add auth columns and a unique index on contact to the customers table.
     *
     * NOTE: Before running on production, verify that no two customers share
     * the same contact value. Duplicate contacts will cause this migration to
     * fail when adding the unique index. Resolve duplicates manually first.
     */
    public function up(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            // PIN is nullable so existing rows (no PIN yet) are not broken.
            // Enforcement that a PIN must exist before login is at the application layer.
            $table->string('pin')->nullable()->after('vacation_end');

            // VARCHAR(255) accommodates both a plain 6-digit code and a bcrypt hash,
            // keeping the column forward-compatible without a future ALTER.
            $table->string('otp')->nullable()->after('pin');

            $table->timestamp('otp_expires_at')->nullable()->after('otp');
            $table->timestamp('mobile_verified_at')->nullable()->after('otp_expires_at');
            $table->timestamp('last_login_at')->nullable()->after('mobile_verified_at');
            $table->timestamp('last_address_change_at')->nullable()->after('last_login_at');

            // Unique per farm — the same mobile can be a customer at multiple farms.
            // Application layer resolves which farm's record to authenticate against.
            $table->unique(['farm_id', 'contact'], 'customers_farm_contact_unique');
        });
    }

    public function down(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->dropUnique('customers_farm_contact_unique');
            $table->dropColumn([
                'pin',
                'otp',
                'otp_expires_at',
                'mobile_verified_at',
                'last_login_at',
                'last_address_change_at',
            ]);
        });
    }
};
