<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Sprint 8 — Delivery schema (S8-06)
 *
 * Creates four tables:
 *   delivery_boys                  — staff belonging to a farm
 *   delivery_routes                — named morning/evening routes per farm
 *   route_customer_assignments     — which customers are on a route (with sort order)
 *   delivery_boy_route_assignments — which delivery boy covers a route on a given date
 */
return new class extends Migration
{
    public function up(): void
    {
        // -------------------------------------------------------------------
        // 1. delivery_boys
        // -------------------------------------------------------------------
        Schema::create('delivery_boys', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('farm_id')->constrained('farms')->cascadeOnDelete();
            $table->string('name', 100);
            $table->string('phone', 20)->nullable();
            $table->string('pin_hash', 255)->nullable();
            $table->string('salary_type', 20);
            $table->decimal('salary_amount', 10, 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('farm_id', 'idx_delivery_boys_farm');
        });

        DB::statement("ALTER TABLE delivery_boys
            ADD CONSTRAINT chk_delivery_boys_salary_type
            CHECK (salary_type IN ('monthly','per_delivery','hourly','part_time'))");

        // -------------------------------------------------------------------
        // 2. delivery_routes
        // -------------------------------------------------------------------
        Schema::create('delivery_routes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('farm_id')->constrained('farms')->cascadeOnDelete();
            $table->string('name', 100);
            $table->string('shift', 10);  // morning | evening
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['farm_id', 'name', 'shift'], 'uq_delivery_routes_farm_name_shift');
            $table->index(['farm_id', 'shift'], 'idx_delivery_routes_farm_shift');
        });

        DB::statement("ALTER TABLE delivery_routes
            ADD CONSTRAINT chk_delivery_routes_shift
            CHECK (shift IN ('morning','evening'))");

        // -------------------------------------------------------------------
        // 3. route_customer_assignments
        //
        // assigned_date sentinel: '1970-01-01' = permanent/standing assignment.
        // Any real date = one-day date override (e.g. substitute route for that day).
        // UNIQUE(route_id, customer_id, assigned_date) prevents duplicate standing
        // entries while allowing per-day overrides alongside the standing record.
        // -------------------------------------------------------------------
        Schema::create('route_customer_assignments', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('route_id')->constrained('delivery_routes')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->unsignedInteger('sort_order')->default(0);
            $table->date('assigned_date')->default('1970-01-01');
            $table->timestamps();

            $table->unique(['route_id', 'customer_id', 'assigned_date'], 'uq_rca_route_customer_date');
            $table->index(['route_id', 'assigned_date'], 'idx_rca_route_date');
        });

        // -------------------------------------------------------------------
        // 4. delivery_boy_route_assignments
        //
        // Records which delivery boy covers a route on a specific date.
        // UNIQUE(route_id, assigned_date): one delivery boy per route per day.
        // -------------------------------------------------------------------
        Schema::create('delivery_boy_route_assignments', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('route_id')->constrained('delivery_routes')->cascadeOnDelete();
            $table->foreignId('delivery_boy_id')->constrained('delivery_boys')->cascadeOnDelete();
            $table->date('assigned_date');
            $table->timestamps();

            $table->unique(['route_id', 'assigned_date'], 'uq_dbra_route_date');
            $table->index(['delivery_boy_id', 'assigned_date'], 'idx_dbra_boy_date');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_boy_route_assignments');
        Schema::dropIfExists('route_customer_assignments');
        Schema::dropIfExists('delivery_routes');
        Schema::dropIfExists('delivery_boys');
    }
};
