<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('whatsapp_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farm_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained()->nullOnDelete();
            $table->string('recipient_mobile', 20);
            $table->string('message_type', 64);
            $table->string('template_name', 128)->nullable();
            $table->string('preview', 500)->nullable();
            $table->string('wamid', 128)->nullable()->unique();
            $table->string('status', 32)->default('pending');
            $table->string('failure_reason', 500)->nullable();
            $table->json('meta')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamp('failed_at')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'created_at']);
            $table->index(['customer_id', 'created_at']);
            $table->index(['status', 'created_at']);
            $table->index('recipient_mobile');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('whatsapp_messages');
    }
};
