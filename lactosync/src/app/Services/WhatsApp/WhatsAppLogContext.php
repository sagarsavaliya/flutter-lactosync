<?php

namespace App\Services\WhatsApp;

/**
 * Optional metadata recorded with each outbound WhatsApp message.
 */
final class WhatsAppLogContext
{
    /**
     * @param  array<string, mixed>  $meta
     */
    public function __construct(
        public readonly ?int $farmId,
        public readonly ?int $customerId,
        public readonly string $messageType,
        public readonly ?string $templateName = null,
        public readonly ?string $preview = null,
        public readonly array $meta = [],
    ) {}

    public static function forCustomer(
        int $farmId,
        int $customerId,
        string $messageType,
        ?string $templateName = null,
        ?string $preview = null,
        array $meta = [],
    ): self {
        return new self($farmId, $customerId, $messageType, $templateName, $preview, $meta);
    }
}
