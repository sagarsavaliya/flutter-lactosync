<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_coupon_redemptions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('coupon_id')->constrained('coupons')->restrictOnDelete();

            // The farm_owners row that received the benefit
            $table->foreignId('owner_id')->constrained('farm_owners')->restrictOnDelete();

            // For free_months coupons: how many months were credited
            $table->unsignedSmallInteger('applied_months')->default(0);

            $table->text('notes')->nullable();

            // Admin who applied the coupon
            $table->foreignId('applied_by')->constrained('admin_users')->restrictOnDelete();

            $table->timestamps();

            // One coupon per tenant (a tenant cannot redeem the same coupon twice)
            $table->unique(['coupon_id', 'owner_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_coupon_redemptions');
    }
};
