<?php

namespace App\Support;

use RuntimeException;

final class WhatsAppRecipient
{
    /** WhatsApp Cloud API expects country code + 10-digit mobile (e.g. 918141302341). */
    public static function toApiFormat(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone) ?? '';

        if (strlen($digits) === 12 && str_starts_with($digits, '91')) {
            $digits = substr($digits, 2);
        }

        if (strlen($digits) !== 10) {
            throw new RuntimeException('Customer WhatsApp number must be a valid 10-digit mobile.');
        }

        return '91'.$digits;
    }

    /** Store 10-digit mobile for logs (strips country code when present). */
    public static function normalizeTenDigits(string $phone): ?string
    {
        $digits = preg_replace('/\D/', '', $phone) ?? '';

        if (strlen($digits) === 12 && str_starts_with($digits, '91')) {
            $digits = substr($digits, 2);
        }

        return strlen($digits) === 10 ? $digits : null;
    }
}
