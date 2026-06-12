<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Http\Controllers\Controller;
use App\Models\Admin\AdminUser;
use App\Models\FarmOwner;
use App\Services\Module\ModuleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Admin endpoints for per-tenant module overrides.
 *
 * GET  /api/admin/v1/tenants/{id}/modules
 * PUT  /api/admin/v1/tenants/{id}/modules
 */
class TenantModuleController extends Controller
{
    public function __construct(private readonly ModuleService $moduleService) {}

    /**
     * GET /api/admin/v1/tenants/{id}/modules
     *
     * Returns the effective module state (resolved through all three layers)
     * plus the raw override row for each module so the UI knows which are
     * explicitly overridden vs inherited from the plan.
     */
    public function show(int $id): JsonResponse
    {
        $owner = FarmOwner::findOrFail($id);

        $overrides = DB::table('tenant_module_overrides')
            ->where('owner_id', $owner->id)
            ->pluck('is_enabled', 'module_slug');

        $effective = $this->moduleService->allModulesForOwner($owner->id);

        $data = [];
        foreach ($effective as $slug => $enabled) {
            $data[] = [
                'module_slug'      => $slug,
                'is_enabled'       => $enabled,
                'has_override'     => isset($overrides[$slug]),
                'override_enabled' => isset($overrides[$slug]) ? (bool) $overrides[$slug] : null,
            ];
        }

        return response()->json(['success' => true, 'data' => $data]);
    }

    /**
     * PUT /api/admin/v1/tenants/{id}/modules
     *
     * Body: { "modules": { "route_delivery": true, "customer_app": false } }
     *
     * Accepts a partial map — only the provided slugs are updated.
     * Pass null to clear the override and fall back to the plan default.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::findOrFail($id);

        $request->validate([
            'modules'   => ['required', 'array'],
            'modules.*' => ['nullable', 'boolean'],
        ]);

        /** @var AdminUser $admin */
        $admin   = $request->user();
        $modules = $request->input('modules', []);
        $now     = now()->toDateTimeString();

        $validSlugs = [
            'route_delivery',
            'customer_app',
            'whatsapp_notifications',
            'billing_invoices',
        ];

        DB::beginTransaction();

        try {
            foreach ($modules as $slug => $enabled) {
                if (! in_array($slug, $validSlugs, true)) {
                    continue;
                }

                if ($enabled === null) {
                    // Clear the override — fall back to plan default.
                    DB::table('tenant_module_overrides')
                        ->where('owner_id', $owner->id)
                        ->where('module_slug', $slug)
                        ->delete();
                } else {
                    DB::table('tenant_module_overrides')->upsert(
                        [
                            'owner_id'   => $owner->id,
                            'module_slug' => $slug,
                            'is_enabled' => (bool) $enabled,
                            'set_by'     => $admin->id,
                            'created_at' => $now,
                            'updated_at' => $now,
                        ],
                        ['owner_id', 'module_slug'],
                        ['is_enabled', 'set_by', 'updated_at'],
                    );
                }
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return $this->show($id);
    }
}
