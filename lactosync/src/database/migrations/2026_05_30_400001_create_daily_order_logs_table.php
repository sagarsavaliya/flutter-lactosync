<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_order_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_line_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->string('product_name');
            $table->decimal('quantity', 8, 2);
            $table->decimal('unit_rate', 10, 2);
            $table->decimal('line_total', 12, 2);
            $table->string('shift');
            $table->string('status')->default('pending');
            $table->date('delivery_date');
            $table->char('billing_month', 7)->comment('YYYY-MM for filtering and billing');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(
                ['farm_id', 'customer_id', 'subscription_id', 'product_id', 'shift', 'delivery_date'],
                'daily_order_logs_idempotent',
            );
            $table->index(['farm_id', 'delivery_date']);
            $table->index(['farm_id', 'billing_month']);
            $table->index(['customer_id', 'billing_month']);
            $table->index(['farm_id', 'status', 'delivery_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_order_logs');
    }
};
