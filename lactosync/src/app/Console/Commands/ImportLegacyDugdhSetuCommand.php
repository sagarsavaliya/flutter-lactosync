<?php

namespace App\Console\Commands;

use App\Models\Farm;
use App\Services\Legacy\LegacyDugdhSetuImporter;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class ImportLegacyDugdhSetuCommand extends Command
{
    protected $signature = 'legacy:import-dugdhsetu
                            {file : Path to JSON export from old DugdhSetuDB}
                            {--farm= : Target farm ID in the new app}
                            {--dry-run : Validate mapping without writing}
                            {--force-existing : Import even when contact already exists}';

    protected $description = 'Import customers and subscriptions from legacy LactoSync SQL Server export (DugdhSetuDB)';

    public function handle(): int
    {
        $path = $this->argument('file');
        if (! File::exists($path)) {
            $this->error("Export file not found: {$path}");

            return self::FAILURE;
        }

        $payload = json_decode(File::get($path), true);
        if (! is_array($payload)) {
            $this->error('Invalid JSON export file.');

            return self::FAILURE;
        }

        foreach (['farm', 'customers', 'products', 'subscriptions'] as $key) {
            if (! array_key_exists($key, $payload)) {
                $this->error("Export file missing required key: {$key}");

                return self::FAILURE;
            }
        }

        $farmId = $this->option('farm');
        $farm = $farmId
            ? Farm::query()->find($farmId)
            : Farm::query()->where('name', $payload['farm']['Name'] ?? '')->first();

        if (! $farm) {
            $this->error('Target farm not found. Pass --farm=<id>.');

            return self::FAILURE;
        }

        $dryRun = (bool) $this->option('dry-run');
        $importer = new LegacyDugdhSetuImporter(
            dryRun: $dryRun,
            skipExisting: ! $this->option('force-existing'),
        );

        $this->info(sprintf(
            '%s legacy data into farm #%d (%s)',
            $dryRun ? 'Dry-run importing' : 'Importing',
            $farm->id,
            $farm->name,
        ));

        $this->line(sprintf(
            'Source: %s (%d customers, %d subscription rows, %d products)',
            $payload['farm']['Name'] ?? 'Unknown',
            count($payload['customers']),
            count($payload['subscriptions']),
            count($payload['products']),
        ));

        $stats = $importer->import($farm, $payload);

        $this->newLine();
        $this->table(
            ['Metric', 'Count'],
            collect($stats)->map(fn ($value, $key) => [str_replace('_', ' ', $key), $value])->values(),
        );

        if ($dryRun) {
            $this->comment('Dry run complete — no database changes were made.');
        } else {
            $this->info('Import complete.');
        }

        return self::SUCCESS;
    }
}
