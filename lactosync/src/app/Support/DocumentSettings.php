<?php

namespace App\Support;

abstract class DocumentSettings
{
    /** @return array<string, mixed> */
    public static function defaults(): array
    {
        return [
            'milk_log_format' => 'image',
            'billing_format' => 'image',
            'payment_receipt_format' => 'image',
            'include_farm_header' => true,
        ];
    }

    /** @param  array<string, mixed>|null  $stored */
    public static function merge(?array $stored): array
    {
        return array_merge(self::defaults(), $stored ?? []);
    }

    /** @return array<string, mixed> */
    public static function validate(array $input): array
    {
        $normalize = static function (mixed $value): string {
            if ($value === 'text') {
                return 'text';
            }
            if (in_array($value, ['image', 'pdf'], true)) {
                return 'image';
            }

            return 'image';
        };

        return [
            'milk_log_format' => $normalize($input['milk_log_format'] ?? null),
            'billing_format' => $normalize($input['billing_format'] ?? null),
            'payment_receipt_format' => $normalize($input['payment_receipt_format'] ?? null),
            'include_farm_header' => (bool) ($input['include_farm_header'] ?? true),
        ];
    }
}
