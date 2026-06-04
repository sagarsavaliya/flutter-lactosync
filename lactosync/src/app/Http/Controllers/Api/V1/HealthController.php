<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $checks = [
            'database' => $this->checkDatabase(),
            'redis' => $this->checkRedis(),
            'whatsapp' => $this->checkWhatsApp(),
        ];

        $healthy = ! in_array(false, $checks, true);

        return ApiResponse::success([
            'service' => 'lactosync-api',
            'status' => $healthy ? 'ok' : 'degraded',
            'checks' => $checks,
        ], null, $healthy ? 200 : 503);
    }

    private function checkDatabase(): bool
    {
        try {
            DB::connection()->getPdo();

            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    private function checkRedis(): bool
    {
        try {
            Redis::ping();

            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    private function checkWhatsApp(): bool
    {
        return ! empty(config('services.whatsapp.token'))
            && ! empty(config('services.whatsapp.phone_number_id'));
    }
}
