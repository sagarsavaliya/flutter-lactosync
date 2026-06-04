<?php

namespace App\Enums;

enum ContainerType: string
{
    case GlassBottle = 'glass_bottle';
    case PlasticBag = 'plastic_bag';

    public function label(): string
    {
        return match ($this) {
            self::GlassBottle => 'Glass Bottle',
            self::PlasticBag => 'Plastic Bag',
        };
    }
}
