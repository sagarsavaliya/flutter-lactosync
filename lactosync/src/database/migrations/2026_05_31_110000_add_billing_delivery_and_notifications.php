<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->timestamp('sent_at')->nullable()->after('due_date');
            $table->string('sent_via')->nullable()->after('sent_at');
        });

        Schema::table('farms', function (Blueprint $table) {
            $table->string('upi_vpa', 120)->nullable()->after('document_settings');
            $table->string('upi_payee_name', 120)->nullable()->after('upi_vpa');
        });

        Schema::create('owner_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farm_owner_id')->constrained('farm_owners')->cascadeOnDelete();
            $table->string('type');
            $table->string('title');
            $table->text('body');
            $table->json('meta')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index(['farm_owner_id', 'read_at']);
        });

        Schema::create('owner_device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farm_owner_id')->constrained('farm_owners')->cascadeOnDelete();
            $table->string('token', 512);
            $table->string('platform', 20)->default('android');
            $table->timestamps();

            $table->unique(['farm_owner_id', 'token']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('owner_device_tokens');
        Schema::dropIfExists('owner_notifications');
        Schema::table('farms', function (Blueprint $table) {
            $table->dropColumn(['upi_vpa', 'upi_payee_name']);
        });
        Schema::table('invoices', function (Blueprint $table) {
            $table->dropColumn(['sent_at', 'sent_via']);
        });
    }
};
