<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('farms', function (Blueprint $table) {
            $table->string('morning_order_time', 5)->default('05:00')->after('document_settings');
            $table->string('evening_order_time', 5)->default('15:00')->after('morning_order_time');
        });
    }

    public function down(): void
    {
        Schema::table('farms', function (Blueprint $table) {
            $table->dropColumn(['morning_order_time', 'evening_order_time']);
        });
    }
};
