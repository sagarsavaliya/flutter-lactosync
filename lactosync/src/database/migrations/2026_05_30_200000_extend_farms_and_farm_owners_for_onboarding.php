<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('farms', function (Blueprint $table) {
            $table->string('address_line')->nullable()->after('name');
            $table->string('city')->nullable()->after('address_line');
            $table->string('state')->nullable()->after('city');
            $table->string('zip', 10)->nullable()->after('state');
            $table->timestamp('onboarding_completed_at')->nullable()->after('timezone');
        });

        Schema::table('farm_owners', function (Blueprint $table) {
            $table->string('first_name')->nullable()->after('farm_id');
            $table->string('last_name')->nullable()->after('first_name');
            $table->string('onboarding_step')->default('farm_profile')->after('is_active');
            $table->timestamp('mobile_verified_at')->nullable()->after('onboarding_step');
        });
    }

    public function down(): void
    {
        Schema::table('farm_owners', function (Blueprint $table) {
            $table->dropColumn(['first_name', 'last_name', 'onboarding_step', 'mobile_verified_at']);
        });

        Schema::table('farms', function (Blueprint $table) {
            $table->dropColumn([
                'address_line',
                'city',
                'state',
                'zip',
                'onboarding_completed_at',
            ]);
        });
    }
};
