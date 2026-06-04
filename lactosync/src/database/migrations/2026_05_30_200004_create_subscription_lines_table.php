<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('subscription_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->decimal('quantity', 8, 2);
            $table->decimal('unit_rate', 10, 2);
            $table->decimal('coupon_amount', 10, 2)->default(0);
            $table->decimal('effective_rate', 10, 2);
            $table->string('shift');
            $table->timestamps();

            $table->index(['subscription_id', 'shift']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_lines');
    }
};
