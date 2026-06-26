<?php

namespace App\Services\WhatsApp;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WhatsAppWebhookHandler
{
    public function __construct(private readonly WhatsAppMessageRecorder $recorder) {}

    public function verifySubscription(Request $request): ?string
    {
        $mode = (string) $request->query('hub_mode', '');
        $token = (string) $request->query('hub_verify_token', '');
        $challenge = (string) $request->query('hub_challenge', '');

        $expected = (string) config('services.whatsapp.webhook_verify_token', '');

        if ($mode === 'subscribe' && $expected !== '' && hash_equals($expected, $token)) {
            return $challenge;
        }

        return null;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function handlePayload(array $payload): int
    {
        $updated = 0;

        foreach ($payload['entry'] ?? [] as $entry) {
            foreach ($entry['changes'] ?? [] as $change) {
                $value = $change['value'] ?? [];
                foreach ($value['statuses'] ?? [] as $status) {
                    $wamid = $status['id'] ?? null;
                    $state = $status['status'] ?? null;

                    if (! is_string($wamid) || $wamid === '' || ! is_string($state) || $state === '') {
                        continue;
                    }

                    $failure = null;
                    if ($state === 'failed') {
                        $errors = $status['errors'] ?? [];
                        $failure = is_array($errors) && isset($errors[0]['title'])
                            ? (string) $errors[0]['title']
                            : 'Delivery failed';
                    }

                    if ($this->recorder->applyStatusUpdate($wamid, $state, $failure)) {
                        $updated++;
                    } else {
                        Log::info('WhatsApp webhook status for unknown message', [
                            'wamid' => $wamid,
                            'status' => $state,
                        ]);
                    }
                }
            }
        }

        return $updated;
    }
}
