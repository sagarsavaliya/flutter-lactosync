<?php

namespace App\Http\Middleware;

use App\Models\FarmOwner;
use App\Services\Module\ModuleService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Usage in routes:  ->middleware('module:route_delivery')
 *
 * Returns 403 when the authenticated owner does not have the module enabled.
 */
class CheckModuleEnabled
{
    public function __construct(private readonly ModuleService $moduleService) {}

    public function handle(Request $request, Closure $next, string $moduleSlug): Response
    {
        /** @var FarmOwner|null $owner */
        $owner = $request->user();

        if (! $owner || ! $this->moduleService->isEnabled($owner->id, $moduleSlug)) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'MODULE_DISABLED',
                    'message' => 'This feature is not enabled for your account.',
                ],
            ], 403);
        }

        return $next($request);
    }
}
