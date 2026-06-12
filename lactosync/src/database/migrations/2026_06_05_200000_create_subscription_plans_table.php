<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table): void {
            $table->id();
            $table->string('name', 100)->unique();
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2);
            $table->string('billing_cycle', 20);
            $table->unsignedInteger('max_customers');
            $table->unsignedInteger('max_subscriptions');
            // 0 = active, 1 = archived; archived plans cannot be assigned to new tenants
            $table->boolean('is_archived')->default(false);
            $table->timestamps();

            // Serves plan-list query filtered by active/archived status (FR-22)
            $table->index('is_archived', 'idx_subscription_plans_is_archived');
        });

        // Check constraints — billing cycle enum, positive price, positive limits
        DB::statement("ALTER TABLE subscription_plans
            ADD CONSTRAINT chk_subscription_plans_billing_cycle
            CHECK (billing_cycle IN ('monthly','quarterly','half_yearly','yearly'))");

        DB::statement("ALTER TABLE subscription_plans
            ADD CONSTRAINT chk_subscription_plans_price
            CHECK (price > 0)");

        DB::statement("ALTER TABLE subscription_plans
            ADD CONSTRAINT chk_subscription_plans_max_customers
            CHECK (max_customers > 0)");

        DB::statement("ALTER TABLE subscription_plans
            ADD CONSTRAINT chk_subscription_plans_max_subscriptions
            CHECK (max_subscriptions > 0)");
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_plans');
    }
};
