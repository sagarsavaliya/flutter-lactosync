<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('farm_container_type_visibility', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignId('container_type_id')->constrained('container_types')->cascadeOnDelete();
            // No updated_at — hiding is a toggle: insert to hide, delete to unhide.
            $table->timestamp('created_at')->useCurrent();

            // Serves visibility check; prevents duplicate hide rows per (farm, container).
            $table->unique(['farm_id', 'container_type_id'], 'idx_fctv_farm_container');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('farm_container_type_visibility');
    }
};
