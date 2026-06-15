<?php

namespace Tests\Unit;

use App\Models\DailyOrderLog;
use App\Services\Billing\ConsumptionAggregator;
use Tests\TestCase;

class ConsumptionAggregatorTest extends TestCase
{
    public function test_groups_by_subscription_line_despite_product_name_changes(): void
    {
        $aggregator = new ConsumptionAggregator;

        $logs = collect([
            $this->makeLog(['subscription_line_id' => 10, 'product_id' => 1, 'product_name' => 'Cow Milk', 'unit_rate' => 63, 'quantity' => 9, 'line_total' => 567]),
            $this->makeLog(['subscription_line_id' => 10, 'product_id' => 1, 'product_name' => 'Cow - ₹63', 'unit_rate' => 63, 'quantity' => 10.5, 'line_total' => 661.5]),
        ]);

        $rows = $aggregator->aggregate($logs);

        $this->assertCount(1, $rows);
        $this->assertSame(19.5, $rows->first()['total_quantity']);
        $this->assertSame(1228.5, $rows->first()['line_total']);
    }

    public function test_groups_by_product_and_rate_when_line_id_missing(): void
    {
        $aggregator = new ConsumptionAggregator;

        $logs = collect([
            $this->makeLog(['subscription_line_id' => null, 'product_id' => 2, 'product_name' => 'Buffalo Regular', 'unit_rate' => 80, 'quantity' => 1.5, 'line_total' => 120]),
            $this->makeLog(['subscription_line_id' => null, 'product_id' => 2, 'product_name' => 'Buffalo - ₹80', 'unit_rate' => 80, 'quantity' => 3.5, 'line_total' => 280]),
        ]);

        $rows = $aggregator->aggregate($logs);

        $this->assertCount(1, $rows);
        $this->assertSame(5.0, $rows->first()['total_quantity']);
    }

    /** @param array<string, mixed> $attrs */
    private function makeLog(array $attrs): DailyOrderLog
    {
        $log = new DailyOrderLog($attrs);

        return $log;
    }
}
