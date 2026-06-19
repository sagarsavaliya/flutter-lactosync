<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Http\Controllers\Controller;
use App\Models\FarmOwner;
use App\Services\Admin\TenantBootstrapImporter;
use App\Services\Admin\TenantBootstrapTemplateService;
use App\Services\Admin\TenantBootstrapWorkbookSpec;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class TenantBootstrapImportController extends Controller
{
    public function __construct(
        private readonly TenantBootstrapImporter $importer,
        private readonly TenantBootstrapTemplateService $templateService,
    ) {}

    public function downloadTemplate(): StreamedResponse
    {
        $binary = $this->templateService->buildBinary();

        return response()->streamDownload(
            static function () use ($binary): void {
                echo $binary;
            },
            TenantBootstrapWorkbookSpec::FILE_NAME,
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Cache-Control' => 'no-store, no-cache, must-revalidate',
            ],
        );
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $owner = FarmOwner::query()->find($id);
        if (! $owner) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'TENANT_NOT_FOUND',
                    'message' => 'No tenant found with the given ID.',
                ],
            ], 404);
        }

        $validated = $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx', 'max:10240'],
        ]);

        try {
            $stats = $this->importer->importFromWorkbook($owner, $validated['file']);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'INVALID_WORKBOOK',
                    'message' => $e->getMessage(),
                ],
            ], 422);
        }

        return response()->json([
            'success' => true,
            'data' => $stats,
            'message' => 'Bootstrap import completed.',
        ]);
    }
}
