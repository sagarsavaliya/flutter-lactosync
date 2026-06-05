<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('container_types', function (Blueprint $table) {
            $table->id();
            // NULL = system default visible to all farms; non-null = farm-specific custom entry
            $table->foreignId('farm_id')->nullable()->constrained()->cascadeOnDelete();
            $table->string('name', 100);
            $table->tinyInteger('is_active')->default(1);
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();

            // Serves per-farm lookup: WHERE farm_id IS NULL OR farm_id = ?
            $table->index('farm_id', 'idx_container_types_farm_id');
            // Serves filtered dropdown: WHERE (farm_id IS NULL OR farm_id = ?) AND is_active = 1
            $table->index(['farm_id', 'is_active'], 'idx_container_types_farm_active');

            // Unique per (farm_id, name) — MySQL treats NULLs as distinct in unique indexes,
            // so this only enforces farm-specific uniqueness. System-default uniqueness (farm_id NULL)
            // is enforced at the application layer (seeder checks).
            $table->unique(['farm_id', 'name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('container_types');
    }
};
