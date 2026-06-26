<?php

namespace Tests\Unit;

use App\Models\WhatsAppMessage;
use App\Services\WhatsApp\WhatsAppLogContext;
use App\Services\WhatsApp\WhatsAppMessageRecorder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WhatsAppMessageRecorderTest extends TestCase
{
    use RefreshDatabase;

    public function test_records_outbound_message_with_context(): void
    {
        $recorder = new WhatsAppMessageRecorder();

        $context = new WhatsAppLogContext(
            farmId: null,
            customerId: null,
            messageType: 'bill',
            templateName: 'lacto_sync_bill',
            preview: 'June 2026 bill',
            meta: ['invoice_id' => 99],
        );

        $message = $recorder->recordOutbound(
            '9998866008',
            'bill',
            'wamid.TEST123',
            'sent',
            $context,
        );

        $this->assertDatabaseHas('whatsapp_messages', [
            'id' => $message->id,
            'farm_id' => null,
            'customer_id' => null,
            'recipient_mobile' => '9998866008',
            'wamid' => 'wamid.TEST123',
            'status' => 'sent',
            'message_type' => 'bill',
        ]);
    }

    public function test_applies_delivery_status_updates(): void
    {
        $recorder = new WhatsAppMessageRecorder();

        $message = WhatsAppMessage::query()->create([
            'recipient_mobile' => '9998866008',
            'message_type' => 'bill',
            'wamid' => 'wamid.STATUS1',
            'status' => 'sent',
            'sent_at' => now(),
        ]);

        $this->assertTrue($recorder->applyStatusUpdate('wamid.STATUS1', 'delivered'));

        $message->refresh();
        $this->assertSame('delivered', $message->status);
        $this->assertNotNull($message->delivered_at);

        $this->assertTrue($recorder->applyStatusUpdate('wamid.STATUS1', 'read'));

        $message->refresh();
        $this->assertSame('read', $message->status);
        $this->assertNotNull($message->read_at);
    }

    public function test_returns_false_for_unknown_wamid(): void
    {
        $recorder = new WhatsAppMessageRecorder();

        $this->assertFalse($recorder->applyStatusUpdate('wamid.MISSING', 'delivered'));
    }
}
