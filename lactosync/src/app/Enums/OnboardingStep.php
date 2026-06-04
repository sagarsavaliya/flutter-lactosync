<?php

namespace App\Enums;

enum OnboardingStep: string
{
    case FarmProfile = 'farm_profile';
    case ProductsSetup = 'products_setup';
    case FirstCustomer = 'first_customer';
    case FirstSubscription = 'first_subscription';
    case Completed = 'completed';

    public function label(): string
    {
        return match ($this) {
            self::FarmProfile => 'Farm details',
            self::ProductsSetup => 'Products',
            self::FirstCustomer => 'First customer',
            self::FirstSubscription => 'First subscription',
            self::Completed => 'Complete',
        };
    }
}
