<?php

namespace App\Console\Commands;

use App\Enums\OnboardingStep;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Services\Legacy\LegacyDugdhSetuImporter;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class ImportAllLegacyDugdhSetuCommand extends Command
{
    protected $signature = 'legacy:import-all-dugdhsetu
                            {--dir=/tmp/legacy-import : Directory with per-farm JSON exports}
                            {--default-pin=1234 : Initial PIN for newly provisioned farm owners}
                            {--skip-clear : Do not clear demo data on Shreeji farm before import}';

    protected $description = 'Provision farms and import all legacy DugdhSetuDB customer/subscription exports';

    /** @var array<string, array{owner_mobile: string, owner_name: string, clear_demo?: bool}> */
    private const FARM_OWNERS = [
        '8B31D463-47F3-4741-ACB1-65B9E2F3122A' => [
            'owner_mobile' => '9429040899',
            'owner_name' => 'Sagar Savaliya',
            'clear_demo' => true,
        ],
        '62E02C07-442F-4280-9EFD-3653F15B143E' => [
            'owner_mobile' => '9998866008',
            'owner_name' => 'Farenidham Admin',
        ],
        '12345678-1234-1234-1234-123456789012' => [
            'owner_mobile' => '9876543210',
            'owner_name' => 'Rajesh Kumar',
        ],
    ];

    public function handle(): int
    {
        $dir = (string) $this->option('dir');
        if (! is_dir($dir)) {
            $this->error("Import directory not found: {$dir}");

            return self::FAILURE;
        }

        $files = collect(File::glob(rtrim($dir, '/').'/*.json'))->sort()->values();
        if ($files->isEmpty()) {
            $this->error("No JSON files in {$dir}");

            return self::FAILURE;
        }

        $defaultPin = (string) $this->option('default-pin');
        $skipClear = (bool) $this->option('skip-clear');

        foreach ($files as $path) {
            $payload = json_decode(File::get($path), true);
            if (! is_array($payload)) {
                $this->warn("Skipping invalid JSON: {$path}");

                continue;
            }

            $masterId = strtoupper((string) ($payload['farm']['MasterId'] ?? ''));
            $farmName = (string) ($payload['farm']['Name'] ?? 'Unknown farm');
            $ownerConfig = self::FARM_OWNERS[$masterId] ?? null;

            if ($ownerConfig === null) {
                $this->warn("No owner mapping for {$farmName} ({$masterId}) — skipping.");

                continue;
            }

            $farm = $this->resolveFarm($farmName, $ownerConfig, $defaultPin);
            $this->info("Farm #{$farm->id}: {$farm->name} (owner {$ownerConfig['owner_mobile']})");

            if (($ownerConfig['clear_demo'] ?? false) && ! $skipClear) {
                $this->call('farm:clear-demo-data', [
                    '--farm' => (string) $farm->id,
                    '--keep-products' => true,
                    '--force' => true,
                ]);
            }

            $importer = new LegacyDugdhSetuImporter(dryRun: false, skipExisting: true);
            $stats = $importer->import($farm, $payload);

            $this->table(
                ['Metric', 'Count'],
                collect($stats)->map(fn ($value, $key) => [str_replace('_', ' ', $key), $value])->values(),
            );
            $this->newLine();
        }

        $this->info('All legacy imports complete.');
        $this->comment('New farm owners use PIN '.$defaultPin.' until they reset via WhatsApp OTP.');

        return self::SUCCESS;
    }

    /**
     * @param  array{owner_mobile: string, owner_name: string, clear_demo?: bool}  $ownerConfig
     */
    private function resolveFarm(string $farmName, array $ownerConfig, string $defaultPin): Farm
    {
        $existingOwner = FarmOwner::query()
            ->where('mobile', $ownerConfig['owner_mobile'])
            ->first();

        if ($existingOwner) {
            $farm = $existingOwner->farm;
            if ($farm && $farm->name !== $farmName) {
                $farm->update(['name' => $farmName]);
            }

            return $farm ?? Farm::query()->findOrFail($existingOwner->farm_id);
        }

        $farmByName = Farm::query()->where('name', $farmName)->first();
        if ($farmByName) {
            return $farmByName;
        }

        return DB::transaction(function () use ($farmName, $ownerConfig, $defaultPin): Farm {
            $parts = preg_split('/\s+/', trim($ownerConfig['owner_name']), 2) ?: ['Owner', ''];

            $farm = Farm::query()->create([
                'name' => $farmName,
                'subscription_status' => 'active',
                'timezone' => config('lactosync.schedule.timezone', 'Asia/Kolkata'),
                'morning_order_time' => '05:00',
                'evening_order_time' => '15:00',
                'onboarding_completed_at' => now(),
            ]);

            FarmOwner::query()->create([
                'farm_id' => $farm->id,
                'first_name' => $parts[0] ?? 'Owner',
                'last_name' => $parts[1] ?? '',
                'name' => $ownerConfig['owner_name'],
                'mobile' => $ownerConfig['owner_mobile'],
                'pin' => $defaultPin,
                'is_active' => true,
                'mobile_verified_at' => now(),
                'onboarding_step' => OnboardingStep::Completed,
            ]);

            $this->comment("Provisioned new farm #{$farm->id} for {$ownerConfig['owner_mobile']}.");

            return $farm;
        });
    }
}
