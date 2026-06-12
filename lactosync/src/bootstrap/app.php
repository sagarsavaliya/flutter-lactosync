<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Http\Request;
use App\Jobs\Operations\CreateDailyOrderLogJob;
use App\Jobs\Operations\GenerateMonthlyBillsJob;
use Illuminate\Support\Carbon;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withSchedule(function (Schedule $schedule): void {
        $timezone = config('lactosync.schedule.timezone', 'Asia/Kolkata');

        $schedule->command('orders:dispatch-scheduled')
            ->everyMinute()
            ->timezone($timezone)
            ->name('dispatch-scheduled-orders');

        $schedule->command('billing:payment-due-reminders')
            ->dailyAt('09:00')
            ->timezone($timezone)
            ->name('billing-payment-due-reminders');

        $schedule->command('subscriptions:update-statuses')
            ->dailyAt('00:05')
            ->timezone($timezone)
            ->name('update-subscription-statuses');

        $schedule->command('customer:clear-ended-vacations')
            ->dailyAt('07:00')
            ->timezone($timezone)
            ->name('customer-clear-ended-vacations');

        $schedule->call(function (): void {
            dispatch(new GenerateMonthlyBillsJob(
                Carbon::now()->subMonth()->format('Y-m'),
            ));
        })
            ->monthlyOn(1, '06:00')
            ->timezone($timezone)
            ->name('generate-monthly-bills');
    })
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->trustProxies(at: '*');

        // Named alias so routes can reference 'check.subscription' cleanly.
        $middleware->alias([
            'check.subscription' => \App\Http\Middleware\CheckTenantSubscription::class,
            'module'             => \App\Http\Middleware\CheckModuleEnabled::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        $exceptions->render(function (\Illuminate\Http\Exceptions\ThrottleRequestsException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'error' => [
                        'code' => 'RATE_LIMITED',
                        'message' => 'Too many attempts. Please wait a few minutes and try again.',
                    ],
                ], 429);
            }
        });
    })->create();
