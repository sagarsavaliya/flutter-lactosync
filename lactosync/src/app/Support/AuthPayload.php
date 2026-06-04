<?php

namespace App\Support;

use App\Models\FarmOwner;
use App\Services\Onboarding\OnboardingService;

final class AuthPayload
{
    public static function ownerSession(FarmOwner $owner, string $token, OnboardingService $onboarding): array
    {
        $owner->loadMissing('farm');
        $status = $onboarding->status($owner);

        return [
            'token' => $token,
            'token_type' => 'Bearer',
            'owner' => [
                'id' => $owner->id,
                'first_name' => $owner->first_name,
                'last_name' => $owner->last_name,
                'name' => $owner->fullName(),
                'mobile' => $owner->mobile,
            ],
            'farm' => $status['farm'],
            'onboarding' => [
                'current_step' => $status['current_step'],
                'route' => $onboarding->routeForStep(
                    \App\Enums\OnboardingStep::from($status['current_step']),
                ),
                'is_completed' => $status['is_completed'],
                'checklist' => $status['checklist'],
            ],
        ];
    }
}
