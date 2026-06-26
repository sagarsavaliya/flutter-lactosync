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
 */
class CustomerWhatsAppNotifier
{
    private const LANG = 'en';

    public function __construct(private readonly WhatsAppService $whatsApp) {}

    public function billReady(Customer $customer, Invoice $invoice, Farm $farm): void
    {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $monthLabel = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');
        $dueDate    = $invoice->due_date
            ? Carbon::parse($invoice->due_date)->format('d M Y')
            : 'N/A';
        $template = config('services.whatsapp.template_bill', 'lacto_sync_bill');

        $this->fire(
            $customer,
            $farm,
            $template,
            [
                $customer->fullName(),
                $monthLabel,
                '₹'.number_format((float) $invoice->total_amount, 0),
                (string) $invoice->invoice_number,
                $dueDate,
                $farm->name,
            ],
            'bill',
            "{$monthLabel} bill",
            ['invoice_id' => $invoice->id],
        );
    }

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
        $template = config('services.whatsapp.template_order_log', 'lacto_sync_order_log');

        $this->fire(
            $customer,
            $farm,
            $template,
            [
                $customer->fullName(),
                $monthLabel,
                $productName,
                $shiftLabel,
                $periodLabel,
                $farm->name,
            ],
            'order_log',
            "{$monthLabel} order log",
        );
    }

    public function paymentConfirmed(
        Customer $customer,
        Invoice $invoice,
        float $amount,
        string $paymentMethod,
        Farm $farm,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $methodLabel = match (strtolower($paymentMethod)) {
            'upi'  => 'UPI',
            'cash' => 'Cash',
            default => ucfirst($paymentMethod),
        };
        $template = config('services.whatsapp.template_payment_confirmed', 'lacto_sync_payment_receipt');

        $this->fire(
            $customer,
            $farm,
            $template,
            [
                $customer->fullName(),
                number_format($amount, 0),
                Carbon::today()->format('d M Y'),
                (string) $invoice->invoice_number,
                $methodLabel,
                number_format((float) $invoice->balance_due, 0),
            ],
            'payment_confirmed',
            'Payment receipt',
            ['invoice_id' => $invoice->id, 'amount' => $amount],
        );
    }

    public function deliveryPaused(
        Customer $customer,
        string $vacationStart,
        string $vacationEnd,
        Farm $farm,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $resumeDate = Carbon::parse($vacationEnd)->addDay();
        $template = config('services.whatsapp.template_delivery_paused', 'lacto_sync_delivery_paused');

        $this->fire(
            $customer,
            $farm,
            $template,
            [
                $customer->fullName(),
                Carbon::parse($vacationStart)->format('d M Y'),
                $resumeDate->format('d M Y'),
                $farm->name,
            ],
            'delivery_paused',
            'Vacation set',
        );
    }

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
        $template = config('services.whatsapp.template_qty_change', 'lacto_sync_qty_change');

        $this->fire(
            $customer,
            $farm,
            $template,
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
            "{$productName} qty {$qty}",
            ['subscription_line_id' => $line->id],
        );
    }

    public function subscriptionResumed(
        Customer $customer,
        string $fromDate,
        Farm $farm,
    ): void {
        if (! $customer->whatsapp_enabled) {
            return;
        }

        $template = config('services.whatsapp.template_sub_resumed', 'lacto_sync_sub_resumed');

        $this->fire(
            $customer,
            $farm,
            $template,
            [
                $customer->fullName(),
                Carbon::parse($fromDate)->format('d M Y'),
                $farm->name,
            ],
            'sub_resumed',
            'Subscription resumed',
        );
    }

    /** @param list<string> $params @param array<string, mixed> $meta */
    private function fire(
        Customer $customer,
        Farm $farm,
        string $template,
        array $params,
        string $messageType,
        ?string $preview = null,
        array $meta = [],
    ): void {
        $context = WhatsAppLogContext::forCustomer(
            $farm->id,
            $customer->id,
            $messageType,
            $template,
            $preview,
            $meta,
        );

        try {
            $this->whatsApp->sendTemplate($customer->contact, $template, $params, self::LANG, $context);
        } catch (RuntimeException $e) {
            Log::warning("WhatsApp {$messageType} notification failed", [
                'mobile'   => $customer->contact,
                'template' => $template,
                'error'    => $e->getMessage(),
            ]);
        }
    }
}
