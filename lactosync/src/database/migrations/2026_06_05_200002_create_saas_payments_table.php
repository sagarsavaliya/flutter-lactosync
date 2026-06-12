<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('saas_payments', function (Blueprint $table): void {
            $table->id();

            // Tenant — RESTRICT: payment records are financial data; owner deletion is blocked
            $table->unsignedBigInteger('owner_id');

            // Assignment link — SET NULL if the assignment row is logically replaced
            $table->unsignedBigInteger('tenant_plan_assignment_id')->nullable();

            // Payment data
            $table->decimal('amount', 10, 2);
            $table->date('payment_date');
            // nullable: settling a specific cycle due date (ad-hoc partial payments allowed)
            $table->date('due_date')->nullable();
            $table->string('payment_method', 20);

            // Optional: who made the payment (free text)
            $table->string('paid_by_name', 150)->nullable();

            // Optional: UPI ref, bank transaction ID, cheque number, etc.
            $table->string('reference', 255)->nullable();
            $table->text('notes')->nullable();

            // Audit columns — all FK → admin_users
            $table->unsignedBigInteger('recorded_by');           // NOT NULL: who entered this record
            $table->unsignedBigInteger('edited_by')->nullable(); // last admin who edited; NULL if never edited
            $table->unsignedBigInteger('deleted_by')->nullable(); // admin who soft-deleted; NULL if not deleted

            $table->timestamps();

            // Laravel SoftDeletes column
            $table->softDeletes();

            // ----------------------------------------------------------------
            // Foreign keys
            // ----------------------------------------------------------------
            $table->foreign('owner_id')
                ->references('id')->on('farm_owners')
                ->restrictOnDelete();

            $table->foreign('tenant_plan_assignment_id')
                ->references('id')->on('tenant_plan_assignments')
                ->nullOnDelete();

            // recorded_by → RESTRICT: audit trail must reference a real admin row
            $table->foreign('recorded_by')
                ->references('id')->on('admin_users')
                ->restrictOnDelete();

            $table->foreign('edited_by')
                ->references('id')->on('admin_users')
                ->nullOnDelete();

            $table->foreign('deleted_by')
                ->references('id')->on('admin_users')
                ->nullOnDelete();

            // ----------------------------------------------------------------
            // Indexes
            // ----------------------------------------------------------------

            // Per-tenant payment history sorted by date DESC (FR-24); outstanding balance aggregate
            $table->index(['owner_id', 'payment_date'], 'idx_saas_payments_owner_date');

            // Global payment list date-range filter (FR-26)
            $table->index('payment_date', 'idx_saas_payments_payment_date');

            // SoftDeletes scope — every withTrashed / onlyTrashed query
            $table->index('deleted_at', 'idx_saas_payments_deleted_at');

            // Payments per assignment
            $table->index('tenant_plan_assignment_id', 'idx_saas_payments_assignment');

            // Audit queries: payments entered by admin X
            $table->index('recorded_by', 'idx_saas_payments_recorded_by');
        });

        // Check constraints
        DB::statement("ALTER TABLE saas_payments
            ADD CONSTRAINT chk_saas_payments_amount
            CHECK (amount > 0)");

        DB::statement("ALTER TABLE saas_payments
            ADD CONSTRAINT chk_saas_payments_method
            CHECK (payment_method IN ('upi','cash','credit','bank_transfer','other'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('saas_payments');
    }
};
