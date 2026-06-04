<?php

namespace App\Services\Billing;

use App\Enums\OrderLogStatus;
use App\Models\DailyOrderLog;
use App\Models\Invoice;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class BillDocumentService
{
    /**
     * @return array{bill_pdf: string, milk_log_pdf: string}
     */
    public function generateBundle(Invoice $invoice): array
    {
        $invoice->loadMissing(['customer', 'lines', 'farm']);

        $billPdf = $this->generateBillPdf($invoice);
        $milkLogPdf = $this->generateMilkLogPdf($invoice);

        return [
            'bill_pdf' => $billPdf,
            'milk_log_pdf' => $milkLogPdf,
        ];
    }

    public function generateBillPdf(Invoice $invoice): string
    {
        $invoice->loadMissing(['customer', 'lines', 'farm']);
        $customer = $invoice->customer;
        $farm = $invoice->farm;

        $totalQty = round((float) $invoice->lines->sum('total_quantity'), 2);
        $avgRate = $totalQty > 0
            ? round((float) $invoice->subtotal / $totalQty, 2)
            : 0.0;

        $monthLabel = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');
        $qrBase64 = $this->buildUpiQrBase64($invoice, $farm?->upi_vpa, $farm?->upi_payee_name ?? $farm?->name);

        $html = view('bills.receipt', [
            'farmName' => $farm?->name ?? 'LactoSync',
            'customerName' => $customer?->fullName() ?? '',
            'customerAddress' => $customer?->shortAddress() ?? '',
            'billingMonth' => $monthLabel,
            'invoiceNumber' => $invoice->invoice_number,
            'totalQuantity' => $totalQty,
            'averageRate' => $avgRate,
            'previousBalance' => max(0, round((float) $invoice->total_amount - (float) $invoice->balance_due - (float) $invoice->amount_paid, 2)),
            'amountPaid' => (float) $invoice->amount_paid,
            'totalAmount' => (float) $invoice->total_amount,
            'balanceDue' => (float) $invoice->balance_due,
            'dueDate' => $invoice->due_date?->format('d M Y') ?? '—',
            'lines' => $invoice->lines,
            'qrBase64' => $qrBase64,
        ])->render();

        $relative = $this->storePdf($html, "bill-{$invoice->id}.pdf");

        return Storage::disk('local')->path($relative);
    }

    public function generateMilkLogPdf(Invoice $invoice): string
    {
        $invoice->loadMissing(['customer']);
        $customer = $invoice->customer;

        $logs = DailyOrderLog::query()
            ->where('customer_id', $invoice->customer_id)
            ->where('billing_month', $invoice->billing_month)
            ->where('status', OrderLogStatus::Delivered)
            ->orderBy('delivery_date')
            ->orderBy('shift')
            ->get();

        $rows = $logs
            ->groupBy(fn (DailyOrderLog $log) => $log->delivery_date->toDateString())
            ->map(function ($dayLogs, $date) {
                $morning = round((float) $dayLogs->where('shift', 'morning')->sum('quantity'), 2);
                $evening = round((float) $dayLogs->where('shift', 'evening')->sum('quantity'), 2);

                return [
                    'date' => Carbon::parse($date)->format('d M'),
                    'morning' => $morning > 0 ? $morning : null,
                    'evening' => $evening > 0 ? $evening : null,
                    'products' => $dayLogs->pluck('product_name')->unique()->implode(', '),
                ];
            })
            ->values();

        $monthLabel = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');

        $html = view('bills.milk-log', [
            'farmName' => $invoice->farm?->name ?? 'LactoSync',
            'customerName' => $customer?->fullName() ?? '',
            'billingMonth' => $monthLabel,
            'rows' => $rows,
        ])->render();

        $relative = $this->storePdf($html, "milk-log-{$invoice->id}.pdf");

        return Storage::disk('local')->path($relative);
    }

    private function storePdf(string $html, string $filename): string
    {
        $pdf = Pdf::loadHTML($html)->setPaper([0, 0, 226.77, 841.89], 'portrait');

        $relative = 'bills/'.Str::uuid().'-'.$filename;
        Storage::disk('local')->put($relative, $pdf->output());

        return $relative;
    }

    private function buildUpiQrBase64(Invoice $invoice, ?string $vpa, ?string $payeeName): ?string
    {
        if (empty($vpa)) {
            return null;
        }

        $amount = number_format((float) $invoice->balance_due, 2, '.', '');
        if ((float) $amount <= 0) {
            $amount = number_format((float) $invoice->total_amount, 2, '.', '');
        }

        $monthLabel = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('M Y');
        $upiUrl = 'upi://pay?'.http_build_query([
            'pa' => $vpa,
            'pn' => $payeeName ?? 'Milk Bill',
            'am' => $amount,
            'cu' => 'INR',
            'tn' => "Milk bill {$monthLabel}",
        ], '', '&', PHP_QUERY_RFC3986);

        $png = QrCode::format('png')->size(220)->margin(1)->generate($upiUrl);

        return base64_encode($png);
    }
}
