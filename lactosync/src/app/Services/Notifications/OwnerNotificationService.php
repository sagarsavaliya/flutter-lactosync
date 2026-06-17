<?php

namespace App\Services\Notifications;

use App\Models\Customer;
use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Models\OwnerNotification;
use App\Models\Payment;
use App\Models\SubscriptionLine;
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

    public function customerVacationSet(
        FarmOwner $owner,
        Customer $customer,
        string $vacationStart,
        string $vacationEnd,
        string $resumeLabel,
    ): OwnerNotification {
        $start = Carbon::parse($vacationStart)->format('d M Y');
        $end = Carbon::parse($vacationEnd)->format('d M Y');

        return $this->create($owner, 'customer_vacation_set', 'Customer vacation', sprintf(
            '%s paused delivery from %s to %s. Resumes %s.',
            $customer->fullName(),
            $start,
            $end,
            $resumeLabel,
        ), [
            'customer_id' => $customer->id,
            'vacation_start' => $vacationStart,
            'vacation_end' => $vacationEnd,
        ]);
    }

    public function customerVacationCleared(FarmOwner $owner, Customer $customer): OwnerNotification
    {
        return $this->create($owner, 'customer_vacation_cleared', 'Vacation cleared', sprintf(
            '%s cleared their vacation. Regular delivery continues.',
            $customer->fullName(),
        ), [
            'customer_id' => $customer->id,
        ]);
    }

    public function customerQtyChanged(
        FarmOwner $owner,
        Customer $customer,
        string $deliveryDate,
        SubscriptionLine $line,
        int $qty,
    ): OwnerNotification {
        $line->loadMissing('product');
        $productName = $line->product?->name ?? 'Milk';
        $dateLabel = Carbon::parse($deliveryDate)->format('d M Y');

        return $this->create($owner, 'customer_qty_changed', 'Qty changed', sprintf(
            '%s changed %s to %s L for %s (%s).',
            $customer->fullName(),
            $productName,
            $qty,
            $dateLabel,
            $line->shift instanceof \BackedEnum ? $line->shift->label() : (string) $line->shift,
        ), [
            'customer_id' => $customer->id,
            'delivery_date' => $deliveryDate,
            'subscription_line_id' => $line->id,
            'qty' => $qty,
        ]);
    }

    public function customerDaySkipped(FarmOwner $owner, Customer $customer, string $deliveryDate): OwnerNotification
    {
        $dateLabel = Carbon::parse($deliveryDate)->format('d M Y');

        return $this->create($owner, 'customer_day_skipped', 'Delivery skipped', sprintf(
            '%s skipped delivery for %s.',
            $customer->fullName(),
            $dateLabel,
        ), [
            'customer_id' => $customer->id,
            'delivery_date' => $deliveryDate,
        ]);
    }

    public function customerAddressUpdated(
        FarmOwner $owner,
        Customer $customer,
        string $addressSummary,
    ): OwnerNotification {
        return $this->create($owner, 'customer_address_updated', 'Address updated', sprintf(
            '%s updated delivery address to %s.',
            $customer->fullName(),
            $addressSummary,
        ), [
            'customer_id' => $customer->id,
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
