<?php

namespace App\Services\WhatsApp;

use App\Models\Customer;
use App\Models\Farm;
use App\Models\Invoice;
use App\Models\SubscriptionLine;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Sends approved WhatsApp template notifications to customers.
 *
 * All methods are fire-and-forget: exceptions are caught and logged so that
 * a WhatsApp failure never blocks the owner's action (saving vacation dates,
 * recording payment, etc.).
 *
 * Template names are read from config/services.php (via env vars).
 * Language defaults to 'en' but can be overridden per-template via env.
 *
 * Template parameter mapping (must match approved template order on Meta):
 *
 *   lacto_sync_bill
 *     {{1}} customer name  {{2}} billing month  {{3}} amount  {{4}} bill no
 *     {{5}} due date  {{6}} farm name
 *
 *   lacto_sync_order_log
 *     {{1}} customer name  {{2}} billing month  {{3}} product  {{4}} shift
 *     {{5}} period  {{6}} farm name
 *
 *   lacto_sync_payment_receipt
 *     {{1}} customer name  {{2}} amount (no ₹ — template has it)
 *     {{3}} payment date  {{4}} invoice no  {{5}} payment method
 *     {{6}} balance due (no ₹ — template has it)
 *
 *   lacto_sync_delivery_paused
 *     {{1}} customer name  {{2}} stop date  {{3}} resume date  {{4}} farm name
 *
 *   lacto_sync_qty_change
 *     {{1}} customer name  {{2}} product  {{3}} qty  {{4}} shift  {{5}} rate
 *     {{6}} effective from  {{7}} farm name
 *
 *   lacto_sync_sub_resumed
 *     {{1}} customer name  {{2}} from date  {{3}} farm name
 */
class CustomerWhatsAppNotifier
{
    private const LANG = 'en';

    public function __construct(private readonly WhatsAppService $whatsApp) {}

    // -------------------------------------------------------------------------

    public function billReady(Customer $customer, Invoice $invoice, Farm $farm): void
    {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $monthLabel = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');
        $dueDate    = $invoice->due_date
            ? Carbon::parse($invoice->due_date)->format('d M Y')
            : 'N/A';

        $this->fire(
            $customer->contact,
            config('services.whatsapp.template_bill', 'lacto_sync_bill'),
            [
                $customer->fullName(),
                $monthLabel,
                '₹'.number_format((float) $invoice->total_amount, 0),
                (string) $invoice->invoice_number,
                $dueDate,
                $farm->name,
            ],
            'bill',
        );
    }

    // -------------------------------------------------------------------------

    public function orderLog(
        Customer $customer,
        string $billingMonth,
        string $productName,
        string $shiftLabel,
        string $periodLabel,
        Farm $farm,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $monthLabel = Carbon::createFromFormat('Y-m', $billingMonth)->format('F Y');

        $this->fire(
            $customer->contact,
            config('services.whatsapp.template_order_log', 'lacto_sync_order_log'),
            [
                $customer->fullName(),
                $monthLabel,
                $productName,
                $shiftLabel,
                $periodLabel,
                $farm->name,
            ],
            'order_log',
        );
    }

    // -------------------------------------------------------------------------

    public function paymentConfirmed(
        Customer $customer,
        Invoice $invoice,
        float $amount,
        string $paymentMethod,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $methodLabel = match (strtolower($paymentMethod)) {
            'upi'  => 'UPI',
            'cash' => 'Cash',
            default => ucfirst($paymentMethod),
        };

        $this->fire(
            $customer->contact,
            config('services.whatsapp.template_payment_confirmed', 'lacto_sync_payment_receipt'),
            [
                $customer->fullName(),
                number_format($amount, 0),
                Carbon::today()->format('d M Y'),
                (string) $invoice->invoice_number,
                $methodLabel,
                number_format((float) $invoice->balance_due, 0),
            ],
            'payment_confirmed',
        );
    }

    // -------------------------------------------------------------------------

    public function deliveryPaused(
        Customer $customer,
        string $stopDate,
        string $resumeDate,
        Farm $farm,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $this->fire(
            $customer->contact,
            config('services.whatsapp.template_delivery_paused', 'lacto_sync_delivery_paused'),
            [
                $customer->fullName(),
                Carbon::parse($stopDate)->format('d M Y'),
                Carbon::parse($resumeDate)->format('d M Y'),
                $farm->name,
            ],
            'delivery_paused',
        );
    }

    // -------------------------------------------------------------------------

    public function qtyChanged(
        Customer $customer,
        SubscriptionLine $line,
        string $effectiveFrom,
        Farm $farm,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $productName = $line->product?->name ?? 'Milk';
        $shift = $line->shift instanceof \BackedEnum ? $line->shift->label() : (string) $line->shift;
        $qty  = number_format((float) $line->quantity, 1);
        $rate = number_format((float) $line->unit_rate, 0);
        $date = Carbon::parse($effectiveFrom)->format('d M Y');

        $this->fire(
            $customer->contact,
            config('services.whatsapp.template_qty_change', 'lacto_sync_qty_change'),
            [
                $customer->fullName(),
                $productName,
                $qty,
                $shift,
                $rate,
                $date,
                $farm->name,
            ],
            'qty_change',
        );
    }

    // -------------------------------------------------------------------------

    public function subscriptionResumed(
        Customer $customer,
        string $fromDate,
        Farm $farm,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $this->fire(
            $customer->contact,
            config('services.whatsapp.template_sub_resumed', 'lacto_sync_sub_resumed'),
            [
                $customer->fullName(),
                Carbon::parse($fromDate)->format('d M Y'),
                $farm->name,
            ],
            'sub_resumed',
        );
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    /** @param list<string> $params */
    private function fire(string $mobile, string $template, array $params, string $label): void
    {
        try {
            $this->whatsApp->sendTemplate($mobile, $template, $params, self::LANG);
        } catch (RuntimeException $e) {
            Log::warning("WhatsApp {$label} notification failed", [
                'mobile'   => $mobile,
                'template' => $template,
                'error'    => $e->getMessage(),
            ]);
        }
    }
}
