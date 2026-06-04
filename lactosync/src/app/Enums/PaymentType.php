<?php

namespace App\Enums;

enum PaymentType: string
{
    case Receipt = 'receipt';
    case Adjustment = 'adjustment';

    /** Money received from customer (jama). */
    case Jama = 'jama';

    /** Amount owed / credit extended (udhar). */
    case Udhar = 'udhar';

    public function label(): string
    {
        return match ($this) {
            self::Receipt => 'Payment received',
            self::Adjustment => 'Adjustment',
            self::Jama => 'Jama',
            self::Udhar => 'Udhar',
        };
    }
}
