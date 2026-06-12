<?php

namespace App\Console\Commands;

use App\Models\Admin\TenantPlanAssignment;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Daily job that auto-transitions tenant subscription statuses:
 *
 *   active      + due_date < today          → grace_period  (sets grace_expires_at = due_date + 5 days)
 *   grace_period + grace_expires_at < today → suspended     (sets suspended_at = now())
 *
 * Run via scheduler: subscriptions:update-statuses (daily)
 */
class UpdateSubscriptionStatuses extends Command
{
    protected $signature = 'subscriptions:update-statuses';

    protected $description = 'Transition overdue tenant subscriptions: active → grace_period → suspended';

    public function handle(): int
    {
        $today = Carbon::today();

        // Pass 1: active → grace_period
        // Criteria: status = 'active' AND due_date < today
        $activeToPending = TenantPlanAssignment::where('status', 'active')
            ->whereDate('due_date', '<', $today)
            ->get();

        $gracedCount = 0;

        foreach ($activeToPending as $assignment) {
            $assignment->update([
                'status'           => 'grace_period',
                'grace_expires_at' => $assignment->due_date->addDays(5),
            ]);
            $gracedCount++;
        }

        // Pass 2: grace_period → suspended
        // Criteria: status = 'grace_period' AND grace_expires_at < today
        $graceToSuspended = TenantPlanAssignment::where('status', 'grace_period')
            ->whereDate('grace_expires_at', '<', $today)
            ->get();

        $suspendedCount = 0;

        foreach ($graceToSuspended as $assignment) {
            $assignment->update([
                'status'       => 'suspended',
                'suspended_at' => now(),
            ]);
            $suspendedCount++;
        }

        // Log outcomes.
        Log::channel('daily')->info('subscriptions:update-statuses completed', [
            'active_to_grace_period' => $gracedCount,
            'grace_period_to_suspended' => $suspendedCount,
            'run_date' => $today->toDateString(),
        ]);

        $this->info("Active → grace_period: {$gracedCount}");
        $this->info("Grace_period → suspended: {$suspendedCount}");

        return self::SUCCESS;
    }
}
