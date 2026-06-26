<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\WhatsApp\WhatsAppWebhookHandler;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;

class WhatsAppWebhookController extends Controller
{
    public function __construct(private readonly WhatsAppWebhookHandler $handler) {}

    public function verify(Request $request): Response
    {
        $challenge = $this->handler->verifySubscription($request);

        if ($challenge === null) {
            return response('Forbidden', 403);
        }

        return response($challenge, 200);
    }

    public function receive(Request $request): Response
    {
        $payload = $request->all();

        try {
            $this->handler->handlePayload(is_array($payload) ? $payload : []);
        } catch (\Throwable $e) {
            Log::error('WhatsApp webhook processing failed', [
                'error' => $e->getMessage(),
            ]);
        }

        return response('OK', 200);
    }
}
