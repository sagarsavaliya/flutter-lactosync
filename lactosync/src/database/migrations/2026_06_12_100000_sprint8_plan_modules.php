<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plan_modules', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('subscription_plan_id')
                ->constrained('subscription_plans')
                ->cascadeOnDelete();
            $table->string('module_slug', 50);
            $table->timestamps();

            $table->unique(['subscription_plan_id', 'module_slug'], 'uq_plan_modules');
            $table->index('module_slug', 'idx_plan_modules_slug');
        });

        DB::statement("ALTER TABLE plan_modules
            ADD CONSTRAINT chk_plan_modules_slug
            CHECK (module_slug IN ('route_delivery','customer_app','whatsapp_notifications','billing_invoices'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('plan_modules');
    }
};
