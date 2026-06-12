<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Demo seeders are opt-in only — run manually when needed:
        // php artisan db:seed --class=DemoProductsSeeder
        // php artisan db:seed --class=DemoCustomersSeeder
        // php artisan db:seed --class=DemoOperationsSeeder

        // AdminUserSeeder is safe to re-run on any environment — it uses
        // updateOrCreate so it never inserts a duplicate row.
        if (app()->environment('local', 'staging', 'production')) {
            $this->call(AdminUserSeeder::class);
        }

        // Reference data seeders — safe to re-run on any environment.
        // These use insertOrIgnore / skip-if-exists patterns and never
        // overwrite or delete existing rows.
        $this->call([
            MilkTypeSeeder::class,
            ContainerTypeSeeder::class,
        ]);
    }
}
