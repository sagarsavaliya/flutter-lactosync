<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\FarmOwner;
use App\Services\Module\ModuleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * GET /api/v1/owner/modules
 *
 * Returns the effective module entitlements for the authenticated owner.
 * Used by the Flutter app to show/hide nav items at login.
 */
class OwnerModuleController extends Controller
{
    public function __construct(private readonly ModuleService $moduleService) {}

    public function index(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner   = $request->user();
        $modules = $this->moduleService->allModulesForOwner($owner->id);

        return response()->json([
            'success' => true,
            'data'    => $modules,
        ]);
    }
}
