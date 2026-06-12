<?php

namespace App\Services\Billing;

use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Services\Notifications\OwnerNotificationService;
use App\Services\WhatsApp\WhatsAppService;
use Illuminate\Support\Carbon;
use RuntimeException;

class InvoiceDeliveryService
{
    public function __construct(
        private readonly BillImageService $billImages,
        private readonly WhatsAppService $whatsApp,
        private readonly OwnerNotificationService $notifications,
    ) {}

    /**
     * @return array{invoice_id: int, customer_name: string, sent_at: string, sent_label: string|null}
     */
    public function send(Invoice $invoice, FarmOwner $owner): array
    {
        if ($invoice->farm_id !== $owner->farm_id) {
            throw new RuntimeException('Bill not found.');
        }

        $invoice->loadMissing(['customer', 'farm']);
        $customer = $invoice->customer;

        if ($customer === null) {
            throw new RuntimeException('Customer not found for this bill.');
        }

        if (! $customer->whatsapp_enabled) {
            throw new RuntimeException('Customer does not have WhatsApp enabled.');
        }

        $monthLabel = Carbon::createFromFormat('Y-m', $invoice->billing_month)->format('F Y');
        $owner = $owner->fresh(['farm']);
        $dueDate = $invoice->due_date
            ? Carbon::parse($invoice->due_date)->format('d M Y')
            : 'N/A';

        $billImage = $this->billImages->generate($invoice, $owner);

        // Send bill image as the template header — one message instead of two
        $this->whatsApp->sendTemplateWithImageHeader(
            $customer->contact,
            config('services.whatsapp.template_bill', 'lacto_sync_monthly_bill'),
            $billImage,
            [
                $customer->fullName(),
                $monthLabel,
                '₹'.number_format((float) $invoice->total_amount, 0),
                (string) $invoice->invoice_number,
                $dueDate,
                $owner->farm->name,
            ],
        );

        $invoice->forceFill([
            'sent_at' => now(),
            'sent_via' => 'whatsapp',
        ])->save();

        $this->notifications->billSent($owner, $invoice->fresh(['customer']));

        return [
            'invoice_id' => $invoice->id,
            'customer_name' => $customer->fullName(),
            'sent_at' => $invoice->sent_at?->toIso8601String() ?? now()->toIso8601String(),
            'sent_label' => \App\Support\SentLabel::format($invoice->sent_at),
        ];
    }
}
