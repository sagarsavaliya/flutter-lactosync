<?php

namespace App\Enums;

enum MilkType: string
{
    case GirCow = 'gir_cow';
    case Cow = 'cow';
    case Buffalo = 'buffalo';

    public function label(): string
    {
        return match ($this) {
            self::GirCow => 'Gir Cow',
            self::Cow => 'Cow',
            self::Buffalo => 'Buffalo',
        };
    }
}
