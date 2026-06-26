<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Models\OwnerDeviceToken;
use App\Models\OwnerNotification;
use App\Models\Payment;
use App\Enums\PaymentMethod;
use App\Enums\PaymentType;
use App\Services\Billing\InvoiceDeliveryService;
use App\Services\Billing\MonthlyInvoiceGenerator;
use App\Services\Billing\UpiQrImageService;
use App\Services\Activity\FarmActivityLogger;
use App\Services\WhatsApp\CustomerWhatsAppNotifier;
use App\Services\WhatsApp\WhatsAppLogContext;
use App\Services\WhatsApp\WhatsAppService;
use App\Support\ApiResponse;
use App\Support\SentLabel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;
use RuntimeException;

class OwnerBillingController extends Controller
{
    public function __construct(
        private readonly InvoiceDeliveryService $delivery,
        private readonly MonthlyInvoiceGenerator $invoiceGenerator,
        private readonly FarmActivityLogger $activityLogger,
    ) {}

    public function generateInvoice(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $validated = $request->validate([
            'customer_id' => ['required', 'integer'],
            'billing_month' => ['required', 'date_format:Y-m'],
            'send' => ['sometimes', 'boolean'],
        ]);

        $customer = Customer::query()
            ->where('farm_id', $owner->farm_id)
            ->whereKey($validated['customer_id'])
            ->first();

        if ($customer === null) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        try {
            $invoice = $this->invoiceGenerator->regenerateForCustomer(
                $owner->farm,
                $customer->id,
                $validated['billing_month'],
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('BILL_RECALC_BLOCKED', $e->getMessage(), 422);
        }

        if ($invoice === null) {
            return ApiResponse::error(
                'NO_BILLABLE_ORDERS',
                'No delivered orders found for this customer in the selected month.',
                422,
            );
        }

        $result = ['invoice' => $this->invoicePayload($invoice)];

        if ($request->boolean('send')) {
            try {
                $result['send'] = $this->delivery->send($invoice->fresh(['customer']), $owner);
            } catch (RuntimeException $e) {
                return ApiResponse::error('SEND_FAILED', $e->getMessage(), 422);
            }
        }

        return ApiResponse::success($result);
    }

    public function recordPayment(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $validated = $request->validate([
            'invoice_id' => ['required', 'integer'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'payment_method' => ['required', Rule::enum(PaymentMethod::class)],
            'send_receipt' => ['sometimes', 'boolean'],
        ]);

        $invoice = Invoice::query()
            ->where('farm_id', $owner->farm_id)
            ->whereKey($validated['invoice_id'])
            ->with('customer')
            ->first();

        if ($invoice === null) {
            return ApiResponse::error('NOT_FOUND', 'Bill not found.', 404);
        }

        $amount = round((float) $validated['amount'], 2);
        if ($amount > (float) $invoice->balance_due) {
            return ApiResponse::error('INVALID_AMOUNT', 'Amount exceeds balance due.', 422);
        }

        $payment = Payment::query()->create([
            'farm_id' => $owner->farm_id,
            'customer_id' => $invoice->customer_id,
            'invoice_id' => $invoice->id,
            'amount' => $amount,
            'payment_type' => PaymentType::Receipt,
            'payment_method' => $validated['payment_method'],
            'payment_date' => Carbon::today(),
            'recorded_by' => $owner->id,
        ]);

        $invoice->refreshPaymentTotals();
        $invoice->refresh();
        $customer = $invoice->customer;

        $receiptSent = false;
        $receiptError = null;

        if ($request->boolean('send_receipt', true)
            && $customer !== null
            && $customer->whatsapp_enabled) {
            try {
                $owner->loadMissing('farm');
                app(CustomerWhatsAppNotifier::class)->paymentConfirmed(
                    $customer,
                    $invoice,
                    $amount,
                    $validated['payment_method'],
                    $owner->farm,
                );
                $receiptSent = true;
            } catch (RuntimeException $e) {
                $receiptError = $e->getMessage();
                \Illuminate\Support\Facades\Log::warning('WhatsApp payment receipt failed', [
                    'customer_id' => $customer->id,
                    'invoice_id'  => $invoice->id,
                    'error'       => $receiptError,
                ]);
            }
        }

        $this->activityLogger->logCreated(
            $owner,
            'payment',
            $payment->id,
            $customer?->fullName() ?? 'Customer',
            [
                'invoice_id' => $invoice->id,
                'amount' => $amount,
                'payment_method' => $validated['payment_method'],
            ],
        );

        $payload = [
            'payment_id' => $payment->id,
            'invoice_id' => $invoice->id,
            'balance_due' => (float) $invoice->balance_due,
            'receipt_sent' => $receiptSent,
        ];

        if ($receiptError !== null) {
            $payload['receipt_error'] = $receiptError;
        }

        return ApiResponse::success($payload);
    }

    public function shareUpiQr(Request $request, UpiQrImageService $qrImages, WhatsAppService $whatsApp): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $owner->loadMissing('farm');

        $validated = $request->validate([
            'customer_id' => ['required', 'integer'],
            'invoice_id' => ['sometimes', 'integer'],
        ]);

        $customer = Customer::query()
            ->where('farm_id', $owner->farm_id)
            ->whereKey($validated['customer_id'])
            ->first();

        if ($customer === null) {
            return ApiResponse::error('NOT_FOUND', 'Customer not found.', 404);
        }

        if (! $customer->whatsapp_enabled) {
            return ApiResponse::error('WHATSAPP_DISABLED', 'Customer does not have WhatsApp enabled.', 422);
        }

        $amount = null;
        if (isset($validated['invoice_id'])) {
            $invoice = Invoice::query()
                ->where('farm_id', $owner->farm_id)
                ->whereKey($validated['invoice_id'])
                ->where('customer_id', $customer->id)
                ->first();

            if ($invoice === null) {
                return ApiResponse::error('NOT_FOUND', 'Bill not found.', 404);
            }

            $amount = (float) $invoice->balance_due > 0
                ? (float) $invoice->balance_due
                : (float) $invoice->total_amount;
        }

        try {
            $imagePath = $qrImages->generateForFarm($owner->farm, $amount);
            $context = WhatsAppLogContext::forCustomer(
                $owner->farm_id,
                $customer->id,
                'upi_qr',
                null,
                'UPI QR code',
                isset($validated['invoice_id']) ? ['invoice_id' => $validated['invoice_id']] : [],
            );
            $whatsApp->sendImage(
                $customer->contact,
                $imagePath,
                'Pay '.$owner->farm->name.' via UPI. Scan this QR code.',
                $context,
            );
        } catch (RuntimeException $e) {
            return ApiResponse::error('SEND_FAILED', $e->getMessage(), 422);
        }

        return ApiResponse::success(['sent' => true]);
    }

    private function invoicePayload(Invoice $invoice): array
    {
        return [
            'id' => $invoice->id,
            'customer_id' => $invoice->customer_id,
            'customer_name' => $invoice->customer?->fullName() ?? '',
            'billing_month' => $invoice->billing_month,
            'invoice_number' => $invoice->invoice_number,
            'total_amount' => (float) $invoice->total_amount,
            'balance_due' => (float) $invoice->balance_due,
            'status' => $invoice->status instanceof \BackedEnum ? $invoice->status->value : $invoice->status,
        ];
    }

    public function sendInvoice(Request $request, Invoice $invoice): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        try {
            $result = $this->delivery->send($invoice, $owner);
        } catch (RuntimeException $e) {
            return ApiResponse::error('SEND_FAILED', $e->getMessage(), 422);
        }

        return ApiResponse::success($result);
    }

    public function sendBulk(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $billingMonth = (string) $request->query(
            'billing_month',
            Carbon::now()->format('Y-m'),
        );

        $invoices = Invoice::query()
            ->where('farm_id', $owner->farm_id)
            ->where('billing_month', $billingMonth)
            ->with('customer')
            ->orderBy('id')
            ->get();

        $sent = [];
        $failed = [];
        $skipped = [];

        foreach ($invoices as $invoice) {
            if ((float) $invoice->balance_due <= 0 && $invoice->status->value === 'paid') {
                $skipped[] = [
                    'invoice_id' => $invoice->id,
                    'customer_name' => $invoice->customer?->fullName() ?? '',
                    'reason' => 'Already paid',
                ];
                continue;
            }

            if ($invoice->customer !== null && ! $invoice->customer->whatsapp_enabled) {
                $skipped[] = [
                    'invoice_id' => $invoice->id,
                    'customer_name' => $invoice->customer->fullName(),
                    'reason' => 'WhatsApp not enabled',
                ];
                continue;
            }

            try {
                $sent[] = $this->delivery->send($invoice, $owner);
            } catch (RuntimeException $e) {
                $failed[] = [
                    'invoice_id' => $invoice->id,
                    'customer_name' => $invoice->customer?->fullName() ?? '',
                    'error' => $e->getMessage(),
                ];
            }
        }

        return ApiResponse::success([
            'billing_month' => $billingMonth,
            'sent_count' => count($sent),
            'failed_count' => count($failed),
            'skipped_count' => count($skipped),
            'sent' => $sent,
            'failed' => $failed,
            'skipped' => $skipped,
        ]);
    }

    public function notifications(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $items = OwnerNotification::query()
            ->where('farm_owner_id', $owner->id)
            ->orderByDesc('created_at')
            ->limit(50)
            ->get()
            ->map(fn (OwnerNotification $n) => [
                'id' => $n->id,
                'type' => $n->type,
                'title' => $n->title,
                'body' => $n->body,
                'meta' => $n->meta,
                'read_at' => $n->read_at?->toIso8601String(),
                'created_at' => $n->created_at?->toIso8601String(),
            ]);

        $unread = OwnerNotification::query()
            ->where('farm_owner_id', $owner->id)
            ->whereNull('read_at')
            ->count();

        return ApiResponse::success([
            'unread_count' => $unread,
            'notifications' => $items,
        ]);
    }

    public function registerDeviceToken(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['sometimes', 'string', 'in:android,ios'],
        ]);

        OwnerDeviceToken::query()->updateOrCreate(
            [
                'farm_owner_id' => $owner->id,
                'token' => $validated['token'],
            ],
            ['platform' => $validated['platform'] ?? 'android'],
        );

        return ApiResponse::success(['registered' => true]);
    }

    public function markNotificationsRead(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        OwnerNotification::query()
            ->where('farm_owner_id', $owner->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return ApiResponse::success(['read' => true]);
    }
}
