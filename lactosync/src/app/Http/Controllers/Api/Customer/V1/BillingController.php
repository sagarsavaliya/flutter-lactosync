<?php

namespace App\Http\Controllers\Api\Customer\V1;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use App\Services\Billing\BillImageService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class BillingController extends Controller
{
    public function __construct(
        private readonly BillImageService $billImages,
    ) {}

    public function bills(Request $request): JsonResponse
    {
        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        $rows = Invoice::query()
            ->where('customer_id', $customer->id)
            ->orderByDesc('billing_month')
            ->get()
            ->map(fn (Invoice $invoice) => [
                'id'           => $invoice->id,
                'billing_month' => $invoice->billing_month,
                'total_amount' => (float) $invoice->total_amount,
                'balance_due'  => (float) $invoice->balance_due,
                'status'       => $invoice->status instanceof \BackedEnum
                    ? $invoice->status->value
                    : (string) $invoice->status,
            ]);

        return ApiResponse::success(['bills' => $rows]);
    }

    public function billImage(Request $request, int $id): JsonResponse
    {
        $invoice = Invoice::query()->find($id);

        if ($invoice === null) {
            return ApiResponse::error('NOT_FOUND', 'Bill not found.', 404);
        }

        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        if ((int) $invoice->customer_id !== (int) $customer->id) {
            return ApiResponse::error('FORBIDDEN', 'This bill does not belong to you.', 403);
        }

        // Scan the local disk for an existing bill image for this invoice.
        // BillImageService stores files under bills/{uuid}-bill.png on the local disk.
        // Images are generated on send; if none exists yet, generate on demand.
        $relative = $this->findOrGenerateBillImage($invoice);

        if ($relative === null) {
            return ApiResponse::error('NOT_FOUND', 'Bill image not available.', 404);
        }

        // The local disk has serve=true; use temporaryUrl for a signed expiring link.
        $url = Storage::disk('local')->temporaryUrl($relative, now()->addMinutes(30));

        return ApiResponse::success(['url' => $url]);
    }

    public function payments(Request $request): JsonResponse
    {
        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        $rows = Payment::query()
            ->where('customer_id', $customer->id)
            ->orderByDesc('payment_date')
            ->get()
            ->map(fn (Payment $payment) => [
                'id'           => $payment->id,
                'amount'       => (float) $payment->amount,
                'payment_date' => $payment->payment_date?->format('Y-m-d'),
                'method'       => $payment->payment_method instanceof \BackedEnum
                    ? $payment->payment_method->value
                    : (string) $payment->payment_method,
                'note'         => $payment->notes,
            ]);

        return ApiResponse::success(['payments' => $rows]);
    }

    /**
     * Look for an already-generated bill image on the local disk.
     * If none is found, generate one on demand using the invoice's farm owner.
     * Returns the relative path (e.g. "bills/uuid-bill.png") or null on failure.
     */
    private function findOrGenerateBillImage(Invoice $invoice): ?string
    {
        // Try to find an existing image file in the bills/ directory.
        // Files are named bills/{uuid}-bill.png — there is no stored path per invoice,
        // so we cannot look one up by invoice ID directly. Generate fresh instead.
        $invoice->loadMissing(['farm']);

        $farm = $invoice->farm;
        if ($farm === null) {
            return null;
        }

        // Load the farm owner to satisfy BillImageService::generate().
        $farm->loadMissing('owner');
        $owner = $farm->owner;

        if ($owner === null) {
            return null;
        }

        try {
            $absolutePath = $this->billImages->generate($invoice, $owner);
        } catch (\Throwable) {
            return null;
        }

        // Convert the absolute path back to a relative path for the local disk.
        $root = Storage::disk('local')->path('');
        $relative = ltrim(str_replace($root, '', $absolutePath), DIRECTORY_SEPARATOR);

        // Normalise to forward slashes for Storage methods.
        $relative = str_replace('\\', '/', $relative);

        if (! Storage::disk('local')->exists($relative)) {
            return null;
        }

        return $relative;
    }
}
