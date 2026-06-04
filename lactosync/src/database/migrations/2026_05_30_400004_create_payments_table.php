<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->foreignId('invoice_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('amount', 12, 2);
            $table->string('payment_type')->default('receipt');
            $table->string('payment_method')->default('cash');
            $table->date('payment_date');
            $table->string('handed_to')->nullable()->comment('Delivery boy or staff who collected cash');
            $table->text('notes')->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('farm_owners')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['farm_id', 'payment_date']);
            $table->index(['customer_id', 'payment_date']);
            $table->index(['invoice_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
