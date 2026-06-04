<?php

namespace App\Services\Notifications;

use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Models\OwnerNotification;
use App\Models\Payment;
use Illuminate\Support\Carbon;

class OwnerNotificationService
{
    public function billSent(FarmOwner $owner, Invoice $invoice): OwnerNotification
    {
        $invoice->loadMissing('customer');
        $month = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');

        return $this->create($owner, 'bill_sent', 'Bill sent', sprintf(
            '%s — %s bill of ₹%s sent on WhatsApp.',
            $invoice->customer?->fullName() ?? 'Customer',
            $month,
            number_format((float) $invoice->total_amount, 0),
        ), [
            'invoice_id' => $invoice->id,
            'customer_id' => $invoice->customer_id,
            'billing_month' => $invoice->billing_month,
            'total_amount' => (float) $invoice->total_amount,
        ]);
    }

    public function billGenerated(FarmOwner $owner, Invoice $invoice): OwnerNotification
    {
        $invoice->loadMissing('customer');
        $month = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');

        return $this->create($owner, 'bill_generated', 'Monthly bill ready', sprintf(
            '%s — %s bill generated for ₹%s.',
            $invoice->customer?->fullName() ?? 'Customer',
            $month,
            number_format((float) $invoice->total_amount, 0),
        ), [
            'invoice_id' => $invoice->id,
            'customer_id' => $invoice->customer_id,
            'billing_month' => $invoice->billing_month,
            'total_amount' => (float) $invoice->total_amount,
        ]);
    }

    public function paymentReceived(FarmOwner $owner, Payment $payment): OwnerNotification
    {
        $payment->loadMissing(['customer', 'invoice']);
        $month = $payment->invoice?->billing_month
            ? Carbon::createFromFormat('Y-m', $payment->invoice->billing_month)->format('F Y')
            : '';

        return $this->create($owner, 'payment_received', 'Payment received', sprintf(
            '%s paid ₹%s%s.',
            $payment->customer?->fullName() ?? 'Customer',
            number_format((float) $payment->amount, 0),
            $month !== '' ? " for {$month}" : '',
        ), [
            'payment_id' => $payment->id,
            'invoice_id' => $payment->invoice_id,
            'customer_id' => $payment->customer_id,
            'amount' => (float) $payment->amount,
        ]);
    }

    public function paymentDueReminder(FarmOwner $owner, Invoice $invoice): OwnerNotification
    {
        $invoice->loadMissing('customer');
        $month = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');

        return $this->create($owner, 'payment_due_reminder', 'Payment overdue', sprintf(
            '%s has not paid the %s bill of ₹%s (due %s).',
            $invoice->customer?->fullName() ?? 'Customer',
            $month,
            number_format((float) $invoice->balance_due, 0),
            $invoice->due_date?->format('jS M') ?? '—',
        ), [
            'invoice_id' => $invoice->id,
            'customer_id' => $invoice->customer_id,
            'billing_month' => $invoice->billing_month,
            'balance_due' => (float) $invoice->balance_due,
        ]);
    }

    /**
     * @param  array<string, mixed>  $meta
     */
    private function create(FarmOwner $owner, string $type, string $title, string $body, array $meta = []): OwnerNotification
    {
        return OwnerNotification::query()->create([
            'farm_owner_id' => $owner->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'meta' => $meta,
        ]);
    }
}
