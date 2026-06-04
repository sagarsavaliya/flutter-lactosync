<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('farm_milk_type_visibility', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignId('milk_type_id')->constrained('milk_types')->cascadeOnDelete();
            // No updated_at — hiding is a toggle: insert to hide, delete to unhide.
            $table->timestamp('created_at')->useCurrent();

            // Serves visibility check; prevents duplicate hide rows per (farm, type).
            $table->unique(['farm_id', 'milk_type_id'], 'idx_fmtv_farm_milk');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('farm_milk_type_visibility');
    }
};
