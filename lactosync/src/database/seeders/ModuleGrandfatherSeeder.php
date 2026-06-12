<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Enables all four modules for every tenant that already has any plan assignment.
 * Safe to re-run: uses insertOrIgnore so existing rows are never overwritten.
 * Never modifies operational data (orders, deliveries, etc.).
 */
class ModuleGrandfatherSeeder extends Seeder
{
    private const MODULES = [
        'route_delivery',
        'customer_app',
        'whatsapp_notifications',
        'billing_invoices',
    ];

    public function run(): void
    {
        $ownerIds = DB::table('tenant_plan_assignments')
            ->distinct()
            ->pluck('owner_id');

        if ($ownerIds->isEmpty()) {
            $this->command->info('ModuleGrandfatherSeeder: no tenant plan assignments found, nothing to do.');
            return;
        }

        $rows = [];
        $now  = now()->toDateTimeString();

        foreach ($ownerIds as $ownerId) {
            foreach (self::MODULES as $slug) {
                $rows[] = [
                    'owner_id'   => $ownerId,
                    'module_slug' => $slug,
                    'is_enabled' => true,
                    'set_by'     => null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        DB::table('tenant_module_overrides')->insertOrIgnore($rows);

        $this->command->info("ModuleGrandfatherSeeder: granted all modules to {$ownerIds->count()} tenant(s).");
    }
}
