<?php

namespace Tests\Feature;

use App\Services\WhatsApp\WhatsAppWebhookHandler;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WhatsAppWebhookTest extends TestCase
{
    use RefreshDatabase;

    public function test_verifies_subscription_challenge(): void
    {
        config(['services.whatsapp.webhook_verify_token' => 'test-token']);

        $response = $this->get('/api/v1/webhooks/whatsapp?hub_mode=subscribe&hub_verify_token=test-token&hub_challenge=12345');

        $response->assertOk();
        $response->assertSee('12345');
    }

    public function test_rejects_invalid_verify_token(): void
    {
        config(['services.whatsapp.webhook_verify_token' => 'test-token']);

        $response = $this->get('/api/v1/webhooks/whatsapp?hub_mode=subscribe&hub_verify_token=wrong&hub_challenge=12345');

        $response->assertForbidden();
    }

    public function test_processes_status_webhook_payload(): void
    {
        $handler = app(WhatsAppWebhookHandler::class);
        $recorder = app(\App\Services\WhatsApp\WhatsAppMessageRecorder::class);

        $recorder->recordOutbound('9998866008', 'bill', 'wamid.WEBHOOK1', 'sent');

        $updated = $handler->handlePayload([
            'entry' => [[
                'changes' => [[
                    'value' => [
                        'statuses' => [[
                            'id' => 'wamid.WEBHOOK1',
                            'status' => 'delivered',
                        ]],
                    ],
                ]],
            ]],
        ]);

        $this->assertSame(1, $updated);
        $this->assertDatabaseHas('whatsapp_messages', [
            'wamid' => 'wamid.WEBHOOK1',
            'status' => 'delivered',
        ]);
    }
}
