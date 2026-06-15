<?php

namespace Tests\Unit;

use App\Enums\OrderLogStatus;
use App\Models\DailyOrderLog;
use App\Services\Billing\ConsumptionAggregator;
use App\Support\DeliveryLogPresenter;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class DeliveryLogPresenterTest extends TestCase
{
    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_logs_through_date_stops_at_today_for_current_month(): void
    {
        Carbon::setTestNow('2026-06-14 10:00:00');

        $logs = collect([
            $this->logOn('2026-06-13', 2.0, 160.0),
            $this->logOn('2026-06-14', 2.0, 160.0),
            $this->logOn('2026-06-15', 2.0, 160.0),
        ]);

        $filtered = DeliveryLogPresenter::logsThroughDate($logs, '2026-06', Carbon::today());

        $this->assertCount(2, $filtered);
        $this->assertSame(4.0, round((float) $filtered->sum('quantity'), 2));
    }

    public function test_consumption_mtd_matches_user_example_14_days_at_2l_80(): void
    {
        Carbon::setTestNow('2026-06-14 10:00:00');

        $logs = collect();
        for ($day = 1; $day <= 14; $day++) {
            $logs->push($this->logOn(sprintf('2026-06-%02d', $day), 2.0, 160.0));
        }

        $filtered = DeliveryLogPresenter::logsThroughDate($logs, '2026-06', Carbon::today());
        $rows = (new ConsumptionAggregator)->aggregate($filtered);

        $this->assertCount(1, $rows);
        $this->assertSame(28.0, $rows->first()['total_quantity']);
        $this->assertSame(2240.0, $rows->first()['line_total']);
    }

    private function logOn(string $date, float $qty, float $total): DailyOrderLog
    {
        return new DailyOrderLog([
            'delivery_date' => Carbon::parse($date),
            'billing_month' => '2026-06',
            'status' => OrderLogStatus::Pending,
            'subscription_line_id' => 1,
            'product_id' => 1,
            'product_name' => 'Cow Milk',
            'unit_rate' => 80,
            'quantity' => $qty,
            'line_total' => $total,
        ]);
    }
}
