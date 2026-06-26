<?php

namespace Tests\Unit;

use App\Models\FarmActivityLog;
use App\Services\Activity\FarmActivityPresenter;
use Tests\TestCase;

class FarmActivityPresenterTest extends TestCase
{
    public function test_describes_customer_creation(): void
    {
        $log = new FarmActivityLog([
            'action' => 'created',
            'entity_type' => 'customer',
            'entity_label' => 'Ramesh Patel',
        ]);

        $this->assertSame('Added customer Ramesh Patel', FarmActivityPresenter::describe($log));
    }

    public function test_describes_customer_update_with_fields(): void
    {
        $log = new FarmActivityLog([
            'action' => 'updated',
            'entity_type' => 'customer',
            'entity_label' => 'Ramesh Patel',
            'meta' => ['fields' => ['address_line', 'contact']],
        ]);

        $this->assertSame(
            'Updated Ramesh Patel (address line, contact)',
            FarmActivityPresenter::describe($log),
        );
    }

    public function test_describes_invoice_sent(): void
    {
        $log = new FarmActivityLog([
            'action' => 'sent',
            'entity_type' => 'invoice',
            'entity_label' => 'Ramesh Patel',
        ]);

        $this->assertSame('Sent bill to Ramesh Patel', FarmActivityPresenter::describe($log));
    }
}
