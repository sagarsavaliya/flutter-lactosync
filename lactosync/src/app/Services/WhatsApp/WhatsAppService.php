<?php

namespace App\Services\WhatsApp;

use App\Support\WhatsAppRecipient;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class WhatsAppService
{
    public function sendOtp(string $mobileTenDigits, string $otp): void
    {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);
        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');

        if (empty($token) || empty($phoneNumberId)) {
            throw new RuntimeException('WhatsApp is not configured on the server.');
        }

        $version = config('services.whatsapp.graph_version', 'v21.0');
        $url = "https://graph.facebook.com/{$version}/{$phoneNumberId}/messages";

        $response = Http::withToken($token)
            ->timeout(8)
            ->connectTimeout(3)
            ->post($url, [
                'messaging_product' => 'whatsapp',
                'to' => $to,
                'type' => 'template',
                'template' => [
                    'name' => config('services.whatsapp.template_otp', 'lacto_sync_otp'),
                    'language' => [
                        'code' => config('services.whatsapp.template_language', 'en'),
                    ],
                    'components' => $this->otpTemplateComponents($otp),
                ],
            ]);

        if (! $response->successful()) {
            $body = $response->json();
            Log::error('WhatsApp OTP send failed', [
                'mobile' => $mobileTenDigits,
                'status' => $response->status(),
                'body' => $body,
            ]);

            throw new RuntimeException('We could not send the OTP on WhatsApp. Please try again in a moment.');
        }
    }

    /**
     * lacto_sync_otp template uses body {{1}} and a URL button with dynamic suffix.
     *
     * @return list<array<string, mixed>>
     */
    private function otpTemplateComponents(string $otp): array
    {
        $buttonType = config('services.whatsapp.otp_button_type', 'url');

        $components = [
            [
                'type' => 'body',
                'parameters' => [
                    ['type' => 'text', 'text' => $otp],
                ],
            ],
        ];

        if ($buttonType === 'copy_code') {
            $components[] = [
                'type' => 'button',
                'sub_type' => 'copy_code',
                'index' => '0',
                'parameters' => [
                    ['type' => 'coupon_code', 'coupon_code' => $otp],
                ],
            ];
        } else {
            $components[] = [
                'type' => 'button',
                'sub_type' => 'url',
                'index' => '0',
                'parameters' => [
                    ['type' => 'text', 'text' => $otp],
                ],
            ];
        }

        return $components;
    }

    public function sendDocument(
        string $mobileTenDigits,
        string $absolutePath,
        string $filename,
        ?string $caption = null,
    ): void {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);

        if (! is_readable($absolutePath)) {
            throw new RuntimeException('Document file is missing.');
        }

        if (config('services.whatsapp.simulate_documents', false)) {
            Log::info('WhatsApp document simulated', [
                'mobile' => $to,
                'filename' => $filename,
                'caption' => $caption,
            ]);

            return;
        }

        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');

        if (empty($token) || empty($phoneNumberId)) {
            throw new RuntimeException('WhatsApp is not configured on the server.');
        }

        $version = config('services.whatsapp.graph_version', 'v21.0');
        $mediaUrl = "https://graph.facebook.com/{$version}/{$phoneNumberId}/media";

        $upload = Http::withToken($token)
            ->attach(
                'file',
                file_get_contents($absolutePath) ?: '',
                $filename,
                ['Content-Type' => 'application/pdf'],
            )
            ->post($mediaUrl, [
                'messaging_product' => 'whatsapp',
            ]);

        if (! $upload->successful()) {
            Log::error('WhatsApp media upload failed', ['body' => $upload->json()]);
            throw new RuntimeException($this->humanError($upload->json(), 'Could not upload bill to WhatsApp.'));
        }

        $mediaId = $upload->json('id');
        $messageUrl = "https://graph.facebook.com/{$version}/{$phoneNumberId}/messages";

        $payload = [
            'messaging_product' => 'whatsapp',
            'to' => $to,
            'type' => 'document',
            'document' => [
                'id' => $mediaId,
                'filename' => $filename,
            ],
        ];

        if ($caption) {
            $payload['document']['caption'] = $caption;
        }

        $response = Http::withToken($token)->timeout(12)->post($messageUrl, $payload);

        if (! $response->successful()) {
            Log::error('WhatsApp document send failed', ['body' => $response->json()]);
            throw new RuntimeException($this->humanError($response->json(), 'Could not send bill on WhatsApp.'));
        }
    }

    public function sendText(string $mobileTenDigits, string $message): void
    {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);

        if (config('services.whatsapp.simulate_documents', false)) {
            Log::info('WhatsApp text simulated', [
                'mobile' => $to,
                'message' => $message,
            ]);

            return;
        }

        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');

        if (empty($token) || empty($phoneNumberId)) {
            throw new RuntimeException('WhatsApp is not configured on the server.');
        }

        $version = config('services.whatsapp.graph_version', 'v21.0');
        $messageUrl = "https://graph.facebook.com/{$version}/{$phoneNumberId}/messages";

        $response = Http::withToken($token)->timeout(12)->post($messageUrl, [
            'messaging_product' => 'whatsapp',
            'to' => $to,
            'type' => 'text',
            'text' => [
                'preview_url' => false,
                'body' => $message,
            ],
        ]);

        if (! $response->successful()) {
            Log::error('WhatsApp text send failed', ['body' => $response->json()]);
            throw new RuntimeException($this->humanError($response->json(), 'Could not send WhatsApp message.'));
        }
    }

    public function sendImage(
        string $mobileTenDigits,
        string $absolutePath,
        ?string $caption = null,
    ): void {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);

        if (! is_readable($absolutePath)) {
            throw new RuntimeException('Image file is missing.');
        }

        if (config('services.whatsapp.simulate_documents', false)) {
            Log::info('WhatsApp image simulated', [
                'mobile' => $to,
                'path' => $absolutePath,
                'caption' => $caption,
            ]);

            return;
        }

        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');

        if (empty($token) || empty($phoneNumberId)) {
            throw new RuntimeException('WhatsApp is not configured on the server.');
        }

        $version = config('services.whatsapp.graph_version', 'v21.0');
        $mediaUrl = "https://graph.facebook.com/{$version}/{$phoneNumberId}/media";

        $filename = basename($absolutePath);

        $upload = Http::withToken($token)
            ->attach(
                'file',
                file_get_contents($absolutePath) ?: '',
                $filename,
                ['Content-Type' => 'image/png'],
            )
            ->post($mediaUrl, [
                'messaging_product' => 'whatsapp',
            ]);

        if (! $upload->successful()) {
            Log::error('WhatsApp image upload failed', ['body' => $upload->json()]);
            throw new RuntimeException($this->humanError($upload->json(), 'Could not upload image to WhatsApp.'));
        }

        $mediaId = $upload->json('id');
        $messageUrl = "https://graph.facebook.com/{$version}/{$phoneNumberId}/messages";

        $payload = [
            'messaging_product' => 'whatsapp',
            'to' => $to,
            'type' => 'image',
            'image' => [
                'id' => $mediaId,
            ],
        ];

        if ($caption) {
            $payload['image']['caption'] = $caption;
        }

        $response = Http::withToken($token)->timeout(12)->post($messageUrl, $payload);

        if (! $response->successful()) {
            Log::error('WhatsApp image send failed', ['body' => $response->json()]);
            throw new RuntimeException($this->humanError($response->json(), 'Could not send image on WhatsApp.'));
        }
    }

    /**
     * @param  array<string, mixed>|null  $body
     */
    private function humanError(?array $body, string $fallback): string
    {
        $message = $body['error']['message'] ?? null;

        return is_string($message) && $message !== '' ? $message : $fallback;
    }
}
