<?php

namespace App\Services\Activity;

use App\Models\FarmActivityLog;

final class FarmActivityPresenter
{
    public static function describe(FarmActivityLog $log): string
    {
        $label = $log->entity_label;
        $meta = $log->meta ?? [];

        return match ($log->action) {
            'created' => match ($log->entity_type) {
                'customer' => "Added customer {$label}",
                'subscription' => "Added subscription for {$label}",
                'payment' => "Recorded payment for {$label}",
                'product' => "Added product {$label}",
                default => "Created {$log->entity_type} {$label}",
            },
            'updated' => self::describeUpdated($log->entity_type, $label, $meta),
            'deleted' => match ($log->entity_type) {
                'customer' => "Removed customer {$label}",
                'subscription' => "Removed subscription for {$label}",
                'subscription_line' => "Removed subscription line for {$label}",
                default => "Deleted {$log->entity_type} {$label}",
            },
            'restored' => "Restored {$log->entity_type} {$label}",
            'sent' => match ($log->entity_type) {
                'invoice' => "Sent bill to {$label}",
                default => "Sent {$log->entity_type} to {$label}",
            },
            default => ucfirst($log->action).' '.$log->entity_type.' '.$label,
        };
    }

    /**
     * @param  array<string, mixed>  $meta
     */
    private static function describeUpdated(string $entityType, string $label, array $meta): string
    {
        $fields = $meta['fields'] ?? [];
        if (is_array($fields) && $fields !== []) {
            $fieldList = implode(', ', array_map(
                fn ($f) => str_replace('_', ' ', (string) $f),
                $fields,
            ));

            return match ($entityType) {
                'customer' => "Updated {$label} ({$fieldList})",
                'subscription_line' => "Updated subscription for {$label} ({$fieldList})",
                default => "Updated {$entityType} {$label}",
            };
        }

        return match ($entityType) {
            'customer' => "Updated customer {$label}",
            default => "Updated {$entityType} {$label}",
        };
    }
}
