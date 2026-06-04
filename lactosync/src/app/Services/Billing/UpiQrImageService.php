<?php

namespace App\Services\Billing;

use App\Models\Farm;
use App\Models\Invoice;
use App\Support\GdQrCodeGenerator;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UpiQrImageService
{
    public function generateForFarm(Farm $farm, ?float $amount = null): string
    {
        if (empty($farm->upi_vpa)) {
            throw new \RuntimeException('UPI ID is not configured for this farm.');
        }

        $payee = $farm->upi_payee_name ?? $farm->name ?? 'Milk payment';
        $query = [
            'pa' => $farm->upi_vpa,
            'pn' => $payee,
            'cu' => 'INR',
        ];

        if ($amount !== null && $amount > 0) {
            $query['am'] = number_format($amount, 2, '.', '');
        }

        $upiUrl = 'upi://pay?'.http_build_query($query, '', '&', PHP_QUERY_RFC3986);

        $relative = 'qr/'.Str::uuid().'-upi.png';
        $absolute = Storage::disk('local')->path($relative);
        GdQrCodeGenerator::savePng($upiUrl, $absolute, 480, 2);

        return $absolute;
    }

    public function generateForInvoice(Invoice $invoice): string
    {
        $invoice->loadMissing('farm');

        if ($invoice->farm === null) {
            throw new \RuntimeException('Farm not found.');
        }

        $amount = (float) $invoice->balance_due > 0
            ? (float) $invoice->balance_due
            : (float) $invoice->total_amount;

        return $this->generateForFarm($invoice->farm, $amount);
    }
}
