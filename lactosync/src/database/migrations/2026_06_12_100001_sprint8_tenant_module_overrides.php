<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_module_overrides', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('owner_id')
                ->constrained('farm_owners')
                ->cascadeOnDelete();
            $table->string('module_slug', 50);
            $table->boolean('is_enabled');
            $table->foreignId('set_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['owner_id', 'module_slug'], 'uq_tenant_module_overrides');
            $table->index('module_slug', 'idx_tmo_slug');
        });

        DB::statement("ALTER TABLE tenant_module_overrides
            ADD CONSTRAINT chk_tmo_slug
            CHECK (module_slug IN ('route_delivery','customer_app','whatsapp_notifications','billing_invoices'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_module_overrides');
    }
};
