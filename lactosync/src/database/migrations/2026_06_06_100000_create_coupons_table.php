<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coupons', function (Blueprint $table) {
            $table->id();

            // Human-readable code used when applying the coupon (auto-generated or manual)
            $table->string('code', 50)->unique();

            // Display name shown in the admin UI
            $table->string('title', 150);

            // 'free_months' — grants N free billing months to a tenant
            $table->string('type', 30)->default('free_months');

            // Meaning depends on type: for free_months this is the number of months (e.g. 1)
            $table->unsignedSmallInteger('value')->default(1);

            // Max number of tenants this coupon can be applied to (null = unlimited)
            $table->unsignedSmallInteger('max_redemptions')->nullable();

            // Running count incremented on each successful redemption
            $table->unsignedSmallInteger('redemption_count')->default(0);

            $table->boolean('is_active')->default(true);

            // Optional expiry; null means never expires
            $table->date('expires_at')->nullable();

            $table->text('notes')->nullable();

            // Admin who created this coupon
            $table->foreignId('created_by')->constrained('admin_users')->restrictOnDelete();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coupons');
    }
};
