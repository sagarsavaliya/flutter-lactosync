<?php

namespace App\Enums;

enum OrderLogStatus: string
{
    case Pending = 'pending';
    case Delivered = 'delivered';
    case Skipped = 'skipped';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'Pending',
            self::Delivered => 'Delivered',
            self::Skipped => 'Skipped',
            self::Cancelled => 'Cancelled',
        };
    }
}
