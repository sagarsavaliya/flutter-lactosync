<?php

namespace App\Services\WhatsApp;

use App\Models\WhatsAppMessage;
use App\Support\WhatsAppRecipient;
use Illuminate\Support\Carbon;

class WhatsAppMessageRecorder
{
    public function recordOutbound(
        string $recipientMobile,
        string $messageType,
        ?string $wamid,
        string $status,
        ?WhatsAppLogContext $context = null,
        ?string $failureReason = null,
    ): WhatsAppMessage {
        $now = Carbon::now();

        return WhatsAppMessage::query()->create([
            'farm_id' => $context?->farmId,
            'customer_id' => $context?->customerId,
            'recipient_mobile' => WhatsAppRecipient::normalizeTenDigits($recipientMobile) ?? $recipientMobile,
            'message_type' => $messageType,
            'template_name' => $context?->templateName,
            'preview' => $context?->preview,
            'wamid' => $wamid,
            'status' => $status,
            'failure_reason' => $failureReason,
            'meta' => $context?->meta ?: null,
            'sent_at' => in_array($status, ['sent', 'delivered', 'read', 'simulated'], true) ? $now : null,
            'delivered_at' => in_array($status, ['delivered', 'read'], true) ? $now : null,
            'read_at' => $status === 'read' ? $now : null,
            'failed_at' => $status === 'failed' ? $now : null,
        ]);
    }

    public function applyStatusUpdate(string $wamid, string $status, ?string $failureReason = null): bool
    {
        $message = WhatsAppMessage::query()->where('wamid', $wamid)->first();
        if ($message === null) {
            return false;
        }

        $now = Carbon::now();
        $updates = ['status' => $status];

        if ($status === 'sent' && $message->sent_at === null) {
            $updates['sent_at'] = $now;
        }
        if ($status === 'delivered') {
            $updates['delivered_at'] = $message->delivered_at ?? $now;
            $updates['sent_at'] = $message->sent_at ?? $now;
        }
        if ($status === 'read') {
            $updates['read_at'] = $now;
            $updates['delivered_at'] = $message->delivered_at ?? $now;
            $updates['sent_at'] = $message->sent_at ?? $now;
        }
        if ($status === 'failed') {
            $updates['failed_at'] = $now;
            $updates['failure_reason'] = $failureReason;
        }

        $message->update($updates);

        return true;
    }
}
