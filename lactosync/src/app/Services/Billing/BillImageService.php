<?php

namespace App\Services\Billing;

use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Support\ImageDocumentCanvas;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class BillImageService
{
    public function __construct(
        private readonly UpiQrImageService $qrImages,
    ) {}

    public function generate(Invoice $invoice, FarmOwner $owner): string
    {
        $invoice->loadMissing(['customer', 'lines', 'farm']);
        $customer = $invoice->customer;
        $farm = $invoice->farm;

        if ($customer === null || $farm === null) {
            throw new \RuntimeException('Bill data is incomplete.');
        }

        $monthLabel = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');
        $padding = 32;
        $width = 800;
        $lineHeight = 28;
        $lines = $invoice->lines;
        $rows = max(1, $lines->count());
        $hasUpi = ! empty($farm->upi_vpa);
        $showDueNotice = $invoice->due_date !== null && (float) $invoice->balance_due > 0;

        $height = 360 + ($rows * $lineHeight) + ($showDueNotice ? 28 : 0) + ($hasUpi ? 220 : 0) + 80;
        $canvas = new ImageDocumentCanvas($width, $height);

        $leftX = $padding;
        $rightX = (int) ($width * 0.52);

        $canvas->drawText('MILK BILL', $padding, 24, 20, 'primary', true, 'center', $width - ($padding * 2));
        $canvas->drawText($invoice->invoice_number, $padding, 52, 11, 'muted', false, 'center', $width - ($padding * 2));

        $canvas->drawText($customer->fullName(), $leftX, 88, 15, 'ink', true);
        $canvas->drawText($customer->contact, $leftX, 118, 11, 'muted');
        $y = 144;
        foreach ($canvas->wrapText($customer->shortAddress(), (int) ($width * 0.42), 11) as $line) {
            $canvas->drawText($line, $leftX, $y, 11, 'muted');
            $y += 16;
        }

        $canvas->drawText($farm->name ?? 'Dairy farm', $rightX, 88, 15, 'primary', true, 'right', $width - $rightX - $padding);
        $canvas->drawText('Mob: '.$owner->mobile, $rightX, 118, 11, 'muted', false, 'right', $width - $rightX - $padding);
        $farmAddress = collect([$farm->address_line, $farm->city, $farm->state])->filter()->implode(', ');
        $fy = 144;
        foreach ($canvas->wrapText($farmAddress, $width - $rightX - $padding, 11) as $line) {
            $canvas->drawText($line, $rightX, $fy, 11, 'muted', false, 'right', $width - $rightX - $padding);
            $fy += 16;
        }

        $canvas->drawText(
            'Billing month: '.$monthLabel,
            $padding,
            max($y, $fy) + 24,
            13,
            'ink',
            true,
            'center',
            $width - ($padding * 2),
        );

        $tableTop = max($y, $fy) + 56;
        $canvas->drawFilledRect($padding, $tableTop, $width - $padding, $tableTop + $lineHeight, 'headerBg');
        $canvas->drawText('Product', $padding + 12, $tableTop + 7, 11, 'ink', true);
        $canvas->drawText('Qty', (int) ($width * 0.45), $tableTop + 7, 11, 'ink', true, 'center', 80);
        $canvas->drawText('Rate', (int) ($width * 0.58), $tableTop + 7, 11, 'ink', true, 'center', 80);
        $canvas->drawText('Amount', (int) ($width * 0.76), $tableTop + 7, 11, 'ink', true, 'center', 120);

        $rowY = $tableTop + $lineHeight;
        foreach ($lines as $line) {
            $canvas->drawText(
                $line->product_name.' ('.($line->shift instanceof \BackedEnum ? $line->shift->label() : (string) $line->shift).')',
                $padding + 12,
                $rowY + 7,
                11,
                'ink',
            );
            $canvas->drawText(
                number_format((float) $line->total_quantity, 2).' ltr',
                (int) ($width * 0.45),
                $rowY + 7,
                11,
                'ink',
                false,
                'center',
                80,
            );
            $canvas->drawText(
                'Rs '.number_format((float) $line->unit_rate, 0),
                (int) ($width * 0.58),
                $rowY + 7,
                11,
                'ink',
                false,
                'center',
                80,
            );
            $canvas->drawText(
                'Rs '.number_format((float) $line->line_total, 0),
                (int) ($width * 0.76),
                $rowY + 7,
                11,
                'ink',
                false,
                'center',
                120,
            );
            $canvas->drawLine($padding, $rowY + $lineHeight, $width - $padding, $rowY + $lineHeight, 'border');
            $rowY += $lineHeight;
        }

        $canvas->drawRect($padding, $tableTop, $width - $padding, $rowY, 'border');

        $summaryY = $rowY + 16;
        $canvas->drawText('Bill amount', $padding + 12, $summaryY, 12, 'muted');
        $canvas->drawText(
            'Rs '.number_format((float) $invoice->total_amount, 0),
            (int) ($width * 0.55),
            $summaryY,
            14,
            'ink',
            true,
            'right',
            $width - $padding - (int) ($width * 0.55),
        );
        $summaryY += 24;
        $canvas->drawText('Paid', $padding + 12, $summaryY, 12, 'muted');
        $canvas->drawText(
            'Rs '.number_format((float) $invoice->amount_paid, 0),
            (int) ($width * 0.55),
            $summaryY,
            12,
            'ink',
            false,
            'right',
            $width - $padding - (int) ($width * 0.55),
        );
        $summaryY += 22;
        $canvas->drawText('Balance due', $padding + 12, $summaryY, 12, 'muted');
        $canvas->drawText(
            'Rs '.number_format((float) $invoice->balance_due, 0),
            (int) ($width * 0.55),
            $summaryY,
            14,
            'primary',
            true,
            'right',
            $width - $padding - (int) ($width * 0.55),
        );

        $summaryY += 30;

        if ($showDueNotice) {
            $dueDate = $invoice->due_date instanceof Carbon
                ? $invoice->due_date->format('d M Y')
                : Carbon::parse((string) $invoice->due_date)->format('d M Y');
            $canvas->drawText(
                'Please clear the due payment before '.$dueDate.'.',
                $padding,
                $summaryY,
                12,
                'danger',
                true,
                'center',
                $width - ($padding * 2),
            );
            $summaryY += 28;
        }

        if ($hasUpi) {
            $amount = (float) $invoice->balance_due > 0
                ? (float) $invoice->balance_due
                : (float) $invoice->total_amount;
            $qrPath = $this->qrImages->generateForFarm($farm, $amount);
            $qrSize = 168;
            $qrX = (int) (($width - $qrSize) / 2);
            $canvas->drawText(
                'Scan to pay via UPI',
                $padding,
                $summaryY,
                11,
                'muted',
                false,
                'center',
                $width - ($padding * 2),
            );
            $canvas->drawPngImage($qrPath, $qrX, $summaryY + 18, $qrSize, $qrSize);
            $canvas->drawText(
                'UPI: '.$farm->upi_vpa,
                $padding,
                $summaryY + $qrSize + 28,
                10,
                'muted',
                false,
                'center',
                $width - ($padding * 2),
            );
            $summaryY += $qrSize + 52;
        }

        $canvas->drawText(
            'Thank you for your business.',
            $padding,
            $summaryY + 12,
            13,
            'primary',
            true,
            'center',
            $width - ($padding * 2),
        );

        $relative = 'bills/'.Str::uuid().'-bill.png';
        $absolute = Storage::disk('local')->path($relative);
        $canvas->savePng($absolute);

        return $absolute;
    }
}
