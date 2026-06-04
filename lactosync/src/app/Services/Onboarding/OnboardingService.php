<?php

namespace App\Services\Onboarding;

use App\Enums\OnboardingStep;
use App\Models\Farm;
use App\Models\FarmOwner;

class OnboardingService
{
    public function status(FarmOwner $owner): array
    {
        $owner->loadMissing('farm');
        $farm = $owner->farm;

        $productCount = $farm->products()->where('is_active', true)->count();
        $customerCount = $farm->customers()->where('is_active', true)->count();
        $subscriptionCount = $farm->subscriptions()->count();

        $step = $this->resolveStep($owner, $farm, $productCount, $customerCount, $subscriptionCount);

        if ($owner->onboarding_step !== $step) {
            $owner->forceFill(['onboarding_step' => $step])->save();
        }

        return [
            'current_step' => $step->value,
            'current_step_label' => $step->label(),
            'is_completed' => $step === OnboardingStep::Completed,
            'checklist' => [
                'farm_profile' => $this->farmProfileComplete($farm),
                'products_setup' => $productCount >= 1,
                'first_customer' => $customerCount >= 1,
                'first_subscription' => $subscriptionCount >= 1,
            ],
            'counts' => [
                'products' => $productCount,
                'customers' => $customerCount,
                'subscriptions' => $subscriptionCount,
            ],
            'farm' => $this->farmPayload($farm),
            'owner' => [
                'first_name' => $owner->first_name,
                'last_name' => $owner->last_name,
                'full_name' => $owner->fullName(),
                'mobile' => $owner->mobile,
            ],
        ];
    }

    public function advanceAfterFarmProfile(FarmOwner $owner): void
    {
        $owner->forceFill(['onboarding_step' => OnboardingStep::ProductsSetup])->save();
    }

    public function advanceAfterProducts(FarmOwner $owner): void
    {
        $owner->forceFill(['onboarding_step' => OnboardingStep::FirstCustomer])->save();
    }

    public function advanceAfterCustomer(FarmOwner $owner): void
    {
        $owner->forceFill(['onboarding_step' => OnboardingStep::FirstSubscription])->save();
    }

    public function markCompleted(FarmOwner $owner): void
    {
        $owner->loadMissing('farm');
        $owner->farm->forceFill(['onboarding_completed_at' => now()])->save();
        $owner->forceFill(['onboarding_step' => OnboardingStep::Completed])->save();
    }

    public function routeForStep(OnboardingStep $step): string
    {
        return match ($step) {
            OnboardingStep::FarmProfile => '/onboarding/farm',
            OnboardingStep::ProductsSetup => '/onboarding/products',
            OnboardingStep::FirstCustomer => '/onboarding/customer',
            OnboardingStep::FirstSubscription => '/onboarding/dashboard',
            OnboardingStep::Completed => '/dashboard',
        };
    }

    private function resolveStep(
        FarmOwner $owner,
        Farm $farm,
        int $productCount,
        int $customerCount,
        int $subscriptionCount,
    ): OnboardingStep {
        if ($owner->onboarding_step === OnboardingStep::Completed) {
            return OnboardingStep::Completed;
        }

        if (! $this->farmProfileComplete($farm)) {
            return OnboardingStep::FarmProfile;
        }

        if ($productCount < 1) {
            return OnboardingStep::ProductsSetup;
        }

        if ($customerCount < 1) {
            return OnboardingStep::FirstCustomer;
        }

        if ($subscriptionCount < 1 && $owner->onboarding_step !== OnboardingStep::Completed) {
            return OnboardingStep::FirstSubscription;
        }

        return OnboardingStep::Completed;
    }

    private function farmProfileComplete(Farm $farm): bool
    {
        return filled($farm->name)
            && $farm->name !== 'Setup pending'
            && filled($farm->address_line)
            && filled($farm->city)
            && filled($farm->state)
            && filled($farm->zip);
    }

    private function farmPayload(Farm $farm): array
    {
        return [
            'id' => $farm->id,
            'name' => $farm->name,
            'address_line' => $farm->address_line,
            'city' => $farm->city,
            'state' => $farm->state,
            'zip' => $farm->zip,
            'timezone' => $farm->timezone,
        ];
    }
}
