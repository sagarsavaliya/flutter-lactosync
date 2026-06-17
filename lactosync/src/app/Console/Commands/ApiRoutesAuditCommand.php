<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Route;

/**
 * Lists every API route grouped by app surface (owner / customer / delivery-boy / admin).
 * Run after deploy: php artisan api:routes-audit
 */
class ApiRoutesAuditCommand extends Command
{
    protected $signature = 'api:routes-audit {--json : Output machine-readable JSON}';

    protected $description = 'Audit registered API routes grouped by app module';

    public function handle(): int
    {
        $groups = [
            'health' => [],
            'auth_owner' => [],
            'onboarding' => [],
            'owner' => [],
            'customer' => [],
            'delivery_boy' => [],
            'admin' => [],
            'other' => [],
        ];

        foreach (Route::getRoutes() as $route) {
            $uri = $route->uri();
            if (! str_starts_with($uri, 'api/')) {
                continue;
            }

            $methods = collect($route->methods())
                ->reject(fn (string $m) => $m === 'HEAD')
                ->values()
                ->all();

            $entry = [
                'methods' => $methods,
                'uri' => $uri,
                'name' => $route->getName(),
                'middleware' => $route->gatherMiddleware(),
            ];

            $bucket = match (true) {
                $uri === 'api/v1/health' || $uri === 'up' => 'health',
                str_contains($uri, 'api/admin/') => 'admin',
                str_contains($uri, 'api/customer/') => 'customer',
                str_contains($uri, 'api/delivery-boy/') => 'delivery_boy',
                str_contains($uri, 'api/v1/onboarding/') => 'onboarding',
                str_contains($uri, 'api/v1/auth/') => 'auth_owner',
                str_contains($uri, 'api/v1/owner/') => 'owner',
                default => 'other',
            };

            $groups[$bucket][] = $entry;
        }

        $summary = collect($groups)->map(fn (array $routes, string $key) => [
            'group' => $key,
            'count' => count($routes),
        ])->values()->all();

        if ($this->option('json')) {
            $this->line(json_encode([
                'summary' => $summary,
                'routes' => $groups,
            ], JSON_PRETTY_PRINT));

            return self::SUCCESS;
        }

        $this->info('LactoSync API route audit');
        $this->newLine();

        foreach ($summary as $row) {
            $this->line(sprintf('  %-16s %d routes', $row['group'].':', $row['count']));
        }

        $this->newLine();
        $this->comment('Critical owner flows:');
        foreach ([
            'POST api/v1/onboarding/customers',
            'GET api/v1/owner/customers',
            'POST api/v1/owner/subscriptions',
            'GET api/v1/owner/dashboard',
            'GET api/v1/owner/settings',
        ] as $needle) {
            $found = collect($groups)->flatten(1)->contains(
                fn (array $r) => in_array(explode(' ', $needle)[0], $r['methods'], true)
                    && $r['uri'] === explode(' ', $needle, 2)[1],
            );
            $this->line('  '.($found ? '✓' : '✗').' '.$needle);
        }

        $this->newLine();
        $this->comment('Critical customer flows:');
        foreach ([
            'GET api/customer/v1/dashboard',
            'GET api/customer/v1/orders',
            'PUT api/customer/v1/orders/{date}/qty',
            'POST api/customer/v1/orders/{date}/skip',
            'GET api/customer/v1/profile',
        ] as $needle) {
            $found = collect($groups)->flatten(1)->contains(
                fn (array $r) => in_array(explode(' ', $needle)[0], $r['methods'], true)
                    && $r['uri'] === explode(' ', $needle, 2)[1],
            );
            $this->line('  '.($found ? '✓' : '✗').' '.$needle);
        }

        return self::SUCCESS;
    }
}
