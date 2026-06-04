<?php

use App\Jobs\Operations\CreateDailyOrderLogJob;
use App\Jobs\Operations\ExpireVacationSubscriptionsJob;
use App\Jobs\Operations\GenerateMonthlyBillsJob;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

$morningOrderTime = env('LACTOSYNC_MORNING_ORDER_TIME', '06:00');
$eveningOrderTime = env('LACTOSYNC_EVENING_ORDER_TIME', '19:00');
$timezone = env('LACTOSYNC_SCHEDULE_TIMEZONE', 'Asia/Kolkata');

Schedule::job(new CreateDailyOrderLogJob('morning'))
    ->dailyAt($morningOrderTime)
    ->timezone($timezone)
    ->withoutOverlapping()
    ->onOneServer();

Schedule::job(new CreateDailyOrderLogJob('evening'))
    ->dailyAt($eveningOrderTime)
    ->timezone($timezone)
    ->withoutOverlapping()
    ->onOneServer();

Schedule::job(new ExpireVacationSubscriptionsJob())
    ->dailyAt('00:30')
    ->timezone($timezone)
    ->withoutOverlapping()
    ->onOneServer();

Schedule::call(function () use ($timezone) {
    GenerateMonthlyBillsJob::dispatch(now($timezone)->format('Y-m'));
})
    ->monthlyOn(1, '01:00')
    ->timezone($timezone)
    ->withoutOverlapping()
    ->onOneServer();
