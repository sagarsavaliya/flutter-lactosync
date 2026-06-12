<?php

namespace App\Services\Module;

use App\Models\Admin\TenantPlanAssignment;
use Illuminate\Support\Facades\DB;

/**
 * Three-layer module entitlement resolver:
 *   1. tenant_module_overrides  — explicit admin override wins
 *   2. plan_modules             — module included in the active plan
 *   3. default                  — disabled
 */
class ModuleService
{
    private const ALL_MODULES = [
        'route_delivery',
        'customer_app',
        'whatsapp_notifications',
        'billing_invoices',
    ];

    /**
     * Returns true when the given owner has access to the module.
     */
    public function isEnabled(int $ownerId, string $moduleSlug): bool
    {
        // Layer 1: explicit tenant override
        $override = DB::table('tenant_module_overrides')
            ->where('owner_id', $ownerId)
            ->where('module_slug', $moduleSlug)
            ->first(['is_enabled']);

        if ($override !== null) {
            return (bool) $override->is_enabled;
        }

        // Layer 2: plan includes module
        return $this->planIncludesModule($ownerId, $moduleSlug);
    }

    /**
     * Returns all four modules with enabled/disabled status for a given owner.
     *
     * @return array<string, bool>
     */
    public function allModulesForOwner(int $ownerId): array
    {
        $overrides = DB::table('tenant_module_overrides')
            ->where('owner_id', $ownerId)
            ->pluck('is_enabled', 'module_slug');

        $planModules = $this->planModuleSlugSet($ownerId);

        $result = [];
        foreach (self::ALL_MODULES as $slug) {
            if (isset($overrides[$slug])) {
                $result[$slug] = (bool) $overrides[$slug];
            } else {
                $result[$slug] = in_array($slug, $planModules, true);
            }
        }

        return $result;
    }

    // -------------------------------------------------------------------------

    private function planIncludesModule(int $ownerId, string $moduleSlug): bool
    {
        return in_array($moduleSlug, $this->planModuleSlugSet($ownerId), true);
    }

    /** Returns the set of module slugs granted by the owner's active plan. */
    private function planModuleSlugSet(int $ownerId): array
    {
        $assignment = TenantPlanAssignment::where('owner_id', $ownerId)
            ->whereIn('status', ['active', 'grace_period'])
            ->first(['subscription_plan_id']);

        if (! $assignment) {
            return [];
        }

        return DB::table('plan_modules')
            ->where('subscription_plan_id', $assignment->subscription_plan_id)
            ->pluck('module_slug')
            ->all();
    }
}
