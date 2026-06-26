<?php

namespace App\Services\WhatsApp;

use App\Support\WhatsAppRecipient;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class WhatsAppService
{
    public function __construct(private readonly WhatsAppMessageRecorder $recorder) {}

    public function sendOtp(string $mobileTenDigits, string $otp, ?WhatsAppLogContext $context = null): void
    {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);
        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');

        if (empty($token) || empty($phoneNumberId)) {
            throw new RuntimeException('WhatsApp is not configured on the server.');
        }

        $version = config('services.whatsapp.graph_version', 'v21.0');
        $url = "https://graph.facebook.com/{$version}/{$phoneNumberId}/messages";
        $template = config('services.whatsapp.template_otp', 'lacto_sync_otp');

        $logContext = $context ?? new WhatsAppLogContext(null, null, 'otp', $template, 'OTP');

        $response = Http::withToken($token)
            ->timeout(8)
            ->connectTimeout(3)
            ->post($url, [
                'messaging_product' => 'whatsapp',
                'to' => $to,
                'type' => 'template',
                'template' => [
                    'name' => $template,
                    'language' => [
                        'code' => config('services.whatsapp.template_language', 'en'),
                    ],
                    'components' => $this->otpTemplateComponents($otp),
                ],
            ]);

        $this->handleApiResponse($response, $mobileTenDigits, $logContext, 'We could not send the OTP on WhatsApp. Please try again in a moment.');
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
        ?WhatsAppLogContext $context = null,
    ): void {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);

        if (! is_readable($absolutePath)) {
            throw new RuntimeException('Document file is missing.');
        }

        $logContext = $context ?? new WhatsAppLogContext(null, null, 'document', null, $filename);

        if ($this->isSimulateMode()) {
            $this->recordSimulated($mobileTenDigits, $logContext);
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

        $this->handleApiResponse($response, $mobileTenDigits, $logContext, 'Could not send bill on WhatsApp.');
    }

    public function sendText(string $mobileTenDigits, string $message, ?WhatsAppLogContext $context = null): void
    {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);
        $logContext = $context ?? new WhatsAppLogContext(null, null, 'text', null, mb_substr($message, 0, 120));

        if ($this->isSimulateMode()) {
            $this->recordSimulated($mobileTenDigits, $logContext);
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

        $this->handleApiResponse($response, $mobileTenDigits, $logContext, 'Could not send WhatsApp message.');
    }

    public function sendImage(
        string $mobileTenDigits,
        string $absolutePath,
        ?string $caption = null,
        ?WhatsAppLogContext $context = null,
    ): void {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);

        if (! is_readable($absolutePath)) {
            throw new RuntimeException('Image file is missing.');
        }

        $logContext = $context ?? new WhatsAppLogContext(null, null, 'image', null, basename($absolutePath));

        if ($this->isSimulateMode()) {
            $this->recordSimulated($mobileTenDigits, $logContext);
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

        $this->handleApiResponse($response, $mobileTenDigits, $logContext, 'Could not send image on WhatsApp.');
    }

    /**
     * Upload an image file to the WhatsApp media API and return the media ID.
     */
    private function uploadImageMedia(string $absolutePath): string
    {
        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');
        $version = config('services.whatsapp.graph_version', 'v21.0');
        $mediaUrl = "https://graph.facebook.com/{$version}/{$phoneNumberId}/media";

        $filename = basename($absolutePath);
        $upload = Http::withToken($token)
            ->attach('file', file_get_contents($absolutePath) ?: '', $filename, ['Content-Type' => 'image/png'])
            ->post($mediaUrl, ['messaging_product' => 'whatsapp']);

        if (! $upload->successful()) {
            Log::error('WhatsApp image media upload failed', ['body' => $upload->json()]);
            throw new RuntimeException($this->humanError($upload->json(), 'Could not upload image to WhatsApp.'));
        }

        return (string) $upload->json('id');
    }

    /**
     * Send a template that has an IMAGE header component.
     *
     * @param  list<string>  $bodyParams
     */
    public function sendTemplateWithImageHeader(
        string $mobileTenDigits,
        string $templateName,
        string $imageAbsolutePath,
        array $bodyParams,
        string $language = 'en',
        ?WhatsAppLogContext $context = null,
    ): void {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);
        $preview = implode(' · ', array_slice($bodyParams, 0, 3));
        $logContext = $context ?? new WhatsAppLogContext(null, null, 'template_image', $templateName, $preview);

        if ($this->isSimulateMode()) {
            $this->recordSimulated($mobileTenDigits, $logContext);
            Log::info('WhatsApp template+image simulated', [
                'mobile'   => $to,
                'template' => $templateName,
                'image'    => basename($imageAbsolutePath),
                'params'   => $bodyParams,
            ]);

            return;
        }

        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');

        if (empty($token) || empty($phoneNumberId)) {
            throw new RuntimeException('WhatsApp is not configured on the server.');
        }

        if (! is_readable($imageAbsolutePath)) {
            throw new RuntimeException('Image file is missing.');
        }

        $mediaId = $this->uploadImageMedia($imageAbsolutePath);

        $bodyParameters = array_map(
            fn (string $value) => ['type' => 'text', 'text' => $value],
            $bodyParams,
        );

        $version = config('services.whatsapp.graph_version', 'v21.0');
        $url = "https://graph.facebook.com/{$version}/{$phoneNumberId}/messages";

        $response = Http::withToken($token)
            ->timeout(12)
            ->connectTimeout(3)
            ->post($url, [
                'messaging_product' => 'whatsapp',
                'to' => $to,
                'type' => 'template',
                'template' => [
                    'name' => $templateName,
                    'language' => ['code' => $language],
                    'components' => [
                        [
                            'type' => 'header',
                            'parameters' => [
                                ['type' => 'image', 'image' => ['id' => $mediaId]],
                            ],
                        ],
                        [
                            'type' => 'body',
                            'parameters' => $bodyParameters,
                        ],
                    ],
                ],
            ]);

        $this->handleApiResponse($response, $mobileTenDigits, $logContext, 'Could not send WhatsApp notification.');
    }

    /**
     * @param  list<string>  $params
     */
    public function sendTemplate(
        string $mobileTenDigits,
        string $templateName,
        array $params,
        string $language = 'en',
        ?WhatsAppLogContext $context = null,
    ): void {
        $to = WhatsAppRecipient::toApiFormat($mobileTenDigits);
        $preview = implode(' · ', array_slice($params, 0, 3));
        $logContext = $context ?? new WhatsAppLogContext(null, null, 'template', $templateName, $preview);

        if ($this->isSimulateMode()) {
            $this->recordSimulated($mobileTenDigits, $logContext);
            Log::info('WhatsApp template simulated', [
                'mobile'   => $to,
                'template' => $templateName,
                'params'   => $params,
            ]);

            return;
        }

        $token = config('services.whatsapp.token');
        $phoneNumberId = config('services.whatsapp.phone_number_id');

        if (empty($token) || empty($phoneNumberId)) {
            throw new RuntimeException('WhatsApp is not configured on the server.');
        }

        $bodyParameters = array_map(
            fn (string $value) => ['type' => 'text', 'text' => $value],
            $params,
        );

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
                    'name' => $templateName,
                    'language' => ['code' => $language],
                    'components' => [
                        [
                            'type' => 'body',
                            'parameters' => $bodyParameters,
                        ],
                    ],
                ],
            ]);

        $this->handleApiResponse($response, $mobileTenDigits, $logContext, 'Could not send WhatsApp notification.');
    }

    private function isSimulateMode(): bool
    {
        return (bool) config('services.whatsapp.simulate_documents', false);
    }

    private function recordSimulated(string $mobileTenDigits, WhatsAppLogContext $context): void
    {
        $this->recorder->recordOutbound(
            $mobileTenDigits,
            $context->messageType,
            null,
            'simulated',
            $context,
        );
    }

    private function handleApiResponse(
        Response $response,
        string $mobileTenDigits,
        WhatsAppLogContext $context,
        string $fallbackError,
    ): void {
        if (! $response->successful()) {
            $body = $response->json();
            Log::error('WhatsApp send failed', [
                'mobile' => $mobileTenDigits,
                'type' => $context->messageType,
                'status' => $response->status(),
                'body' => $body,
            ]);

            $this->recorder->recordOutbound(
                $mobileTenDigits,
                $context->messageType,
                null,
                'failed',
                $context,
                $this->humanError(is_array($body) ? $body : null, $fallbackError),
            );

            throw new RuntimeException($this->humanError(is_array($body) ? $body : null, $fallbackError));
        }

        $wamid = $this->extractWamid($response);
        $this->recorder->recordOutbound(
            $mobileTenDigits,
            $context->messageType,
            $wamid,
            'sent',
            $context,
        );
    }

    private function extractWamid(Response $response): ?string
    {
        $id = $response->json('messages.0.id');

        return is_string($id) && $id !== '' ? $id : null;
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
