<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_plan_assignments', function (Blueprint $table): void {
            $table->id();

            // One live assignment row per tenant; unique enforced below
            $table->unsignedBigInteger('owner_id');
            $table->unsignedBigInteger('subscription_plan_id');

            // Lifecycle state — default 'active' per schema spec
            $table->string('status', 20)->default('active');

            // Billing dates
            $table->date('start_date');
            $table->date('renewal_date');
            $table->date('due_date');

            // Stored (not computed): due_date + 5 days; middleware reads one column, no arithmetic
            $table->date('grace_expires_at')->nullable();

            // Audit timestamps
            $table->timestamp('suspended_at')->nullable();
            $table->timestamp('paused_at')->nullable();
            $table->timestamp('resumed_at')->nullable();

            // Admin audit FKs (SET NULL on delete so the audit row survives admin removal)
            $table->unsignedBigInteger('paused_by')->nullable();
            $table->unsignedBigInteger('resumed_by')->nullable();
            $table->unsignedBigInteger('assigned_by')->nullable();

            // Ordered JSON array of plan-change events; see schema spec for entry format
            $table->json('plan_change_log')->nullable();

            $table->text('notes')->nullable();
            $table->timestamps();

            // ----------------------------------------------------------------
            // Foreign keys
            // ----------------------------------------------------------------

            // Tenant → RESTRICT: an assignment must not be orphaned
            $table->foreign('owner_id')
                ->references('id')->on('farm_owners')
                ->restrictOnDelete();

            // Plan → RESTRICT: a plan in use cannot be deleted; archiving is the correct route
            $table->foreign('subscription_plan_id')
                ->references('id')->on('subscription_plans')
                ->restrictOnDelete();

            // Admin audit FK — SET NULL so the audit row survives admin removal
            $table->foreign('paused_by')
                ->references('id')->on('admin_users')
                ->nullOnDelete();

            $table->foreign('resumed_by')
                ->references('id')->on('admin_users')
                ->nullOnDelete();

            $table->foreign('assigned_by')
                ->references('id')->on('admin_users')
                ->nullOnDelete();

            // ----------------------------------------------------------------
            // Unique — one live row per tenant
            // ----------------------------------------------------------------
            $table->unique('owner_id', 'uq_tenant_plan_assignments_owner');

            // ----------------------------------------------------------------
            // Indexes (named explicitly for the middleware / dashboard queries)
            // ----------------------------------------------------------------

            // Primary middleware lookup: WHERE owner_id = ? (status is also covered by uq)
            $table->index(['owner_id', 'status'], 'idx_tpa_owner_status');

            // Dashboard aggregate counts by status (FR-07, FR-08)
            $table->index('status', 'idx_tpa_status');

            // "Renewal within 7 days" dashboard flag (FR-09)
            $table->index('renewal_date', 'idx_tpa_renewal_date');

            // Grace-period detection: due_date < TODAY AND grace_expires_at >= TODAY
            $table->index(['due_date', 'grace_expires_at'], 'idx_tpa_due_date_grace');

            // Count of tenants on a given plan (FR-22)
            $table->index('subscription_plan_id', 'idx_tpa_subscription_plan_id');
        });

        // Check constraints — MySQL 8 enforces these at the DB level
        DB::statement("ALTER TABLE tenant_plan_assignments
            ADD CONSTRAINT chk_tpa_status
            CHECK (status IN ('active','grace_period','suspended','paused','expired','no_plan'))");

        DB::statement("ALTER TABLE tenant_plan_assignments
            ADD CONSTRAINT chk_tpa_grace_after_due
            CHECK (grace_expires_at IS NULL OR grace_expires_at >= due_date)");

        DB::statement("ALTER TABLE tenant_plan_assignments
            ADD CONSTRAINT chk_tpa_dates
            CHECK (renewal_date >= start_date)");
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_plan_assignments');
    }
};
