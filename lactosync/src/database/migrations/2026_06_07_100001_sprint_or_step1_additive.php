<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Sprint OR — Step 1: Additive only.
 *
 * Safe to run immediately on a live environment — no columns are dropped,
 * no existing data is modified, and all new columns are nullable or have
 * safe defaults.  The running APK version will simply ignore the new tables
 * and columns until the new APK is deployed.
 *
 * Tables touched:
 *   CREATE  container_type_sizes
 *   CREATE  product_offered_sizes
 *   CREATE  milk_quantities
 *   ALTER   farms          — ADD prefill_customer_address
 *   ALTER   subscription_lines — ADD container_size
 */
return new class extends Migration
{
    public function up(): void
    {
        // ----------------------------------------------------------------
        // 1. New table: container_type_sizes
        //    One row per (container_type, size) — replaces the flat model
        //    where container_types had one row per size.
        // ----------------------------------------------------------------
        Schema::create('container_type_sizes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('container_type_id')
                  ->constrained('container_types')
                  ->cascadeOnDelete();
            $table->decimal('size_liters', 8, 2);
            $table->timestamps();

            $table->unique(['container_type_id', 'size_liters'], 'uniq_container_type_size');
            $table->index('container_type_id', 'idx_container_type_sizes_container_id');
        });

        // ----------------------------------------------------------------
        // 2. New table: product_offered_sizes
        //    Replaces the old product_container_types pivot (deferred drop).
        //    Soft-deleted products are NOT auto-cleaned by FK cascade —
        //    the application layer must handle orphan cleanup on hard-delete.
        // ----------------------------------------------------------------
        Schema::create('product_offered_sizes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')
                  ->constrained('products')
                  ->cascadeOnDelete();
            $table->decimal('size_liters', 8, 2);
            $table->timestamps();

            $table->unique(['product_id', 'size_liters'], 'uniq_product_offered_size');
            $table->index('product_id', 'idx_product_offered_sizes_product_id');
        });

        // ----------------------------------------------------------------
        // 3. New table: milk_quantities
        //    System-wide reference table for the standard quantity list.
        //    No farm_id — not customisable per farm.
        // ----------------------------------------------------------------
        Schema::create('milk_quantities', function (Blueprint $table) {
            $table->id();
            $table->decimal('quantity_liters', 8, 2)->unique();
            $table->string('display_label', 20);
            $table->timestamps();
        });

        // ----------------------------------------------------------------
        // 4. farms: add prefill_customer_address
        //    Default 0 = off; existing rows default to 0 automatically.
        // ----------------------------------------------------------------
        if (! Schema::hasColumn('farms', 'prefill_customer_address')) {
            Schema::table('farms', function (Blueprint $table) {
                $table->tinyInteger('prefill_customer_address')->default(0)->after('upi_payee_name');
            });
        }

        // ----------------------------------------------------------------
        // 5. subscription_lines: add container_size
        //    Nullable — existing rows get NULL, no backfill required.
        // ----------------------------------------------------------------
        if (! Schema::hasColumn('subscription_lines', 'container_size')) {
            Schema::table('subscription_lines', function (Blueprint $table) {
                $table->decimal('container_size', 8, 2)->nullable()->after('shift');
            });
        }
    }

    public function down(): void
    {
        // Drop new tables first (no other tables reference them yet)
        Schema::dropIfExists('product_offered_sizes');
        Schema::dropIfExists('container_type_sizes');
        Schema::dropIfExists('milk_quantities');

        if (Schema::hasColumn('farms', 'prefill_customer_address')) {
            Schema::table('farms', function (Blueprint $table) {
                $table->dropColumn('prefill_customer_address');
            });
        }

        if (Schema::hasColumn('subscription_lines', 'container_size')) {
            Schema::table('subscription_lines', function (Blueprint $table) {
                $table->dropColumn('container_size');
            });
        }
    }
};
