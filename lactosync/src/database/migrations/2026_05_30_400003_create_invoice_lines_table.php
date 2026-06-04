<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoice_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('invoice_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_id')->constrained()->restrictOnDelete();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->string('product_name');
            $table->string('shift');
            $table->unsignedInteger('delivery_days')->default(0);
            $table->decimal('total_quantity', 10, 2)->default(0);
            $table->decimal('unit_rate', 10, 2);
            $table->decimal('line_total', 12, 2);
            $table->timestamps();

            $table->index(['invoice_id', 'subscription_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoice_lines');
    }
};
