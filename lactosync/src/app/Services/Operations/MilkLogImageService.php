<?php

namespace App\Services\Operations;

use App\Models\Customer;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Models\SubscriptionLine;
use App\Support\DeliveryLogPresenter;
use App\Support\ImageDocumentCanvas;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MilkLogImageService
{
    /**
     * @param  Collection<int, \App\Models\DailyOrderLog>  $logs
     */
    public function generate(
        Customer $customer,
        Farm $farm,
        FarmOwner $owner,
        string $billingMonth,
        Collection $logs,
        ?SubscriptionLine $line = null,
    ): string {
        $rows = DeliveryLogPresenter::fullMonthDailyOrdersTable(
            $logs,
            $billingMonth,
            Carbon::today(),
        );

        $productName = $line?->product?->name ?? 'Milk delivery';
        $rate = $line !== null
            ? (float) $line->effective_rate
            : (float) ($logs->first()?->unit_rate ?? 0);

        $rowHeight = 30;
        $padding = 32;
        $tableTop = 210;
        $footerHeight = 72;
        $width = 800;
        $height = $tableTop + $rowHeight + ($rowHeight * count($rows)) + $rowHeight + $footerHeight + $padding;

        $canvas = new ImageDocumentCanvas($width, $height);
        $monthLabel = Carbon::createFromFormat('Y-m', $billingMonth)->format('F Y');

        $this->drawHeader($canvas, $customer, $farm, $owner, $productName, $rate, $monthLabel, $padding, $width);
        $y = $this->drawTable($canvas, $rows, $padding, $width, $tableTop, $rowHeight);
        $canvas->drawText(
            'Thank you for choosing '.($farm->name ?? 'us').'.',
            $padding,
            $y + 24,
            13,
            'primary',
            true,
            'center',
            $width - ($padding * 2),
        );

        $relative = 'milk-logs/'.Str::uuid().'-milk-log.png';
        $absolute = Storage::disk('local')->path($relative);
        $canvas->savePng($absolute);

        return $absolute;
    }

    private function drawHeader(
        ImageDocumentCanvas $canvas,
        Customer $customer,
        Farm $farm,
        FarmOwner $owner,
        string $productName,
        float $rate,
        string $monthLabel,
        int $padding,
        int $width,
    ): void {
        $leftX = $padding;
        $rightX = (int) ($width * 0.52);

        $canvas->drawText($customer->fullName(), $leftX, 28, 16, 'ink', true);
        $canvas->drawText($customer->contact, $leftX, 58, 12, 'muted');
        $y = 84;
        foreach ($canvas->wrapText($customer->shortAddress(), (int) ($width * 0.42), 11) as $line) {
            $canvas->drawText($line, $leftX, $y, 11, 'muted');
            $y += 16;
        }

        $farmName = $farm->name ?? 'Dairy farm';
        $canvas->drawText($farmName, $rightX, 28, 16, 'primary', true, 'right', $width - $rightX - $padding);
        $canvas->drawText('Mob: '.$owner->mobile, $rightX, 58, 12, 'muted', false, 'right', $width - $rightX - $padding);

        $farmAddress = collect([$farm->address_line, $farm->city, $farm->state, $farm->zip])
            ->filter()
            ->implode(', ');
        $fy = 84;
        foreach ($canvas->wrapText($farmAddress, $width - $rightX - $padding, 11) as $line) {
            $canvas->drawText($line, $rightX, $fy, 11, 'muted', false, 'right', $width - $rightX - $padding);
            $fy += 16;
        }

        $centerText = "{$productName}  |  Rs ".number_format($rate, 0).'/ltr  |  '.$monthLabel;
        $canvas->drawText(
            $centerText,
            $padding,
            max($y, $fy) + 28,
            13,
            'ink',
            true,
            'center',
            $width - ($padding * 2),
        );

        $canvas->drawLine($padding, max($y, $fy) + 52, $width - $padding, max($y, $fy) + 52, 'border');
    }

    /**
     * @param  list<array{date: string, morning: ?float, evening: ?float, has_delivery: bool}>  $rows
     */
    private function drawTable(
        ImageDocumentCanvas $canvas,
        array $rows,
        int $padding,
        int $width,
        int $tableTop,
        int $rowHeight,
    ): int {
        $dateCol = $padding + 12;
        $morningCol = (int) ($width * 0.48);
        $eveningCol = (int) ($width * 0.72);
        $colMorningWidth = (int) ($width * 0.22);
        $colEveningWidth = (int) ($width * 0.22);

        $canvas->drawFilledRect($padding, $tableTop, $width - $padding, $tableTop + $rowHeight, 'headerBg');
        $canvas->drawText('Date', $dateCol, $tableTop + 8, 12, 'ink', true);
        $canvas->drawText('Morning', $morningCol, $tableTop + 8, 12, 'ink', true, 'center', $colMorningWidth);
        $canvas->drawText('Evening', $eveningCol, $tableTop + 8, 12, 'ink', true, 'center', $colEveningWidth);

        $y = $tableTop + $rowHeight;
        foreach ($rows as $row) {
            if (! $row['has_delivery']) {
                $canvas->drawFilledRect($padding, $y, $width - $padding, $y + $rowHeight, 'grayRow');
            }

            $dateLabel = Carbon::parse($row['date'])->format('d, l');
            $color = $row['has_delivery'] ? 'ink' : 'muted';
            $canvas->drawText($dateLabel, $dateCol, $y + 8, 11, $color);
            $canvas->drawText(
                $this->qtyLabel($row['morning']),
                $morningCol,
                $y + 8,
                11,
                $color,
                false,
                'center',
                $colMorningWidth,
            );
            $canvas->drawText(
                $this->qtyLabel($row['evening']),
                $eveningCol,
                $y + 8,
                11,
                $color,
                false,
                'center',
                $colEveningWidth,
            );

            $canvas->drawLine($padding, $y + $rowHeight, $width - $padding, $y + $rowHeight, 'border');
            $y += $rowHeight;
        }

        $canvas->drawFilledRect($padding, $y, $width - $padding, $y + $rowHeight, 'headerBg');
        $canvas->drawText('Total ltr', $dateCol, $y + 8, 11, 'ink', true);
        $canvas->drawText(
            $this->shiftTotal($rows, 'morning'),
            $morningCol,
            $y + 8,
            11,
            'ink',
            true,
            'center',
            $colMorningWidth,
        );
        $canvas->drawText(
            $this->shiftTotal($rows, 'evening'),
            $eveningCol,
            $y + 8,
            11,
            'ink',
            true,
            'center',
            $colEveningWidth,
        );
        $y += $rowHeight;

        $canvas->drawRect($padding, $tableTop, $width - $padding, $y, 'border');

        return $y;
    }

    /**
     * @param  list<array{date: string, morning: ?float, evening: ?float, has_delivery: bool}>  $rows
     */
    private function shiftTotal(array $rows, string $key): string
    {
        $sum = 0.0;
        $hasQty = false;

        foreach ($rows as $row) {
            $value = $row[$key];
            if ($value !== null && $value > 0) {
                $sum += $value;
                $hasQty = true;
            }
        }

        if (! $hasQty) {
            return '-';
        }

        return rtrim(rtrim(number_format($sum, 2, '.', ''), '0'), '.');
    }

    private function qtyLabel(?float $value): string
    {
        if ($value === null || $value <= 0) {
            return '-';
        }

        return rtrim(rtrim(number_format($value, 2, '.', ''), '0'), '.');
    }
}
