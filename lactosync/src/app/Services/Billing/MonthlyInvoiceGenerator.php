<?php

namespace App\Services\Billing;

use App\Enums\DeliveryShift;
use App\Enums\InvoiceStatus;
use App\Enums\OrderLogStatus;
use App\Models\DailyOrderLog;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Models\Invoice;
use App\Models\InvoiceLine;
use App\Services\Notifications\OwnerNotificationService;
use App\Support\DeliveryLogPresenter;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class MonthlyInvoiceGenerator
{
    public function __construct(
        private readonly OwnerNotificationService $notifications,
    ) {}

    /**
     * @return list<Invoice>
     */
    public function generateForFarm(Farm $farm, string $billingMonth): array
    {
        $created = [];
        $sequence = (int) Invoice::query()
            ->where('farm_id', $farm->id)
            ->where('billing_month', $billingMonth)
            ->count() + 1;

        $logsByCustomer = DailyOrderLog::query()
            ->where('farm_id', $farm->id)
            ->where('billing_month', $billingMonth)
            ->whereIn('status', DeliveryLogPresenter::billableStatuses())
            ->get()
            ->groupBy('customer_id');

        $issuedAt = Carbon::createFromFormat('Y-m', $billingMonth)->addMonth()->startOfMonth();

        foreach ($logsByCustomer as $customerId => $logs) {
            /** @var Collection<int, DailyOrderLog> $logs */
            if (Invoice::query()
                ->where('farm_id', $farm->id)
                ->where('customer_id', $customerId)
                ->where('billing_month', $billingMonth)
                ->exists()) {
                continue;
            }

            $subtotal = round((float) $logs->sum('line_total'), 2);
            if ($subtotal <= 0) {
                continue;
            }

            $this->finalizeBillableLogs($logs);

            $invoiceNumber = sprintf(
                'INV-%s-%04d',
                str_replace('-', '', $billingMonth),
                $sequence++,
            );

            $invoice = Invoice::query()->create([
                'farm_id' => $farm->id,
                'customer_id' => $customerId,
                'billing_month' => $billingMonth,
                'invoice_number' => $invoiceNumber,
                'subtotal' => $subtotal,
                'discount_total' => 0,
                'total_amount' => $subtotal,
                'amount_paid' => 0,
                'balance_due' => $subtotal,
                'status' => InvoiceStatus::Issued,
                'issued_at' => $issuedAt,
                'due_date' => $issuedAt->copy()->addDays(10),
            ]);

            $grouped = $logs->groupBy(fn (DailyOrderLog $log) => implode('|', [
                $log->subscription_id,
                $log->product_id,
                $log->shift instanceof DeliveryShift ? $log->shift->value : (string) $log->shift,
            ]));

            foreach ($grouped as $group) {
                /** @var DailyOrderLog $first */
                $first = $group->first();

                InvoiceLine::query()->create([
                    'invoice_id' => $invoice->id,
                    'subscription_id' => $first->subscription_id,
                    'product_id' => $first->product_id,
                    'product_name' => $first->product_name,
                    'shift' => $first->shift,
                    'delivery_days' => $group->count(),
                    'total_quantity' => round((float) $group->sum('quantity'), 2),
                    'unit_rate' => $first->unit_rate,
                    'line_total' => round((float) $group->sum('line_total'), 2),
                ]);
            }

            $owner = $farm->owner;
            if ($owner instanceof FarmOwner) {
                $this->notifications->billGenerated($owner, $invoice->fresh(['customer']));
            }

            $created[] = $invoice;
        }

        return $created;
    }

    public function generateForCustomer(Farm $farm, int $customerId, string $billingMonth): ?Invoice
    {
        if (Invoice::query()
            ->where('farm_id', $farm->id)
            ->where('customer_id', $customerId)
            ->where('billing_month', $billingMonth)
            ->exists()) {
            return Invoice::query()
                ->where('farm_id', $farm->id)
                ->where('customer_id', $customerId)
                ->where('billing_month', $billingMonth)
                ->first();
        }

        $logs = DailyOrderLog::query()
            ->where('farm_id', $farm->id)
            ->where('customer_id', $customerId)
            ->where('billing_month', $billingMonth)
            ->whereIn('status', DeliveryLogPresenter::billableStatuses())
            ->get();

        if ($logs->isEmpty()) {
            return null;
        }

        $this->finalizeBillableLogs($logs);

        $subtotal = round((float) $logs->sum('line_total'), 2);
        if ($subtotal <= 0) {
            return null;
        }

        $sequence = (int) Invoice::query()
            ->where('farm_id', $farm->id)
            ->where('billing_month', $billingMonth)
            ->count() + 1;

        $issuedAt = Carbon::createFromFormat('Y-m', $billingMonth)->addMonth()->startOfMonth();
        $invoiceNumber = sprintf(
            'INV-%s-%04d',
            str_replace('-', '', $billingMonth),
            $sequence,
        );

        $invoice = Invoice::query()->create([
            'farm_id' => $farm->id,
            'customer_id' => $customerId,
            'billing_month' => $billingMonth,
            'invoice_number' => $invoiceNumber,
            'subtotal' => $subtotal,
            'discount_total' => 0,
            'total_amount' => $subtotal,
            'amount_paid' => 0,
            'balance_due' => $subtotal,
            'status' => InvoiceStatus::Issued,
            'issued_at' => $issuedAt,
            'due_date' => $issuedAt->copy()->addDays(10),
        ]);

        $grouped = $logs->groupBy(fn (DailyOrderLog $log) => implode('|', [
            $log->subscription_id,
            $log->product_id,
            $log->shift instanceof DeliveryShift ? $log->shift->value : (string) $log->shift,
        ]));

        foreach ($grouped as $group) {
            /** @var DailyOrderLog $first */
            $first = $group->first();

            InvoiceLine::query()->create([
                'invoice_id' => $invoice->id,
                'subscription_id' => $first->subscription_id,
                'product_id' => $first->product_id,
                'product_name' => $first->product_name,
                'shift' => $first->shift,
                'delivery_days' => $group->count(),
                'total_quantity' => round((float) $group->sum('quantity'), 2),
                'unit_rate' => $first->unit_rate,
                'line_total' => round((float) $group->sum('line_total'), 2),
            ]);
        }

        $owner = $farm->owner;
        if ($owner instanceof FarmOwner) {
            $this->notifications->billGenerated($owner, $invoice->fresh(['customer']));
        }

        return $invoice->fresh(['customer']);
    }

    public function regenerateForCustomer(Farm $farm, int $customerId, string $billingMonth): ?Invoice
    {
        $invoice = Invoice::query()
            ->where('farm_id', $farm->id)
            ->where('customer_id', $customerId)
            ->where('billing_month', $billingMonth)
            ->first();

        if ($invoice !== null && (float) $invoice->amount_paid > 0) {
            throw new RuntimeException('Cannot recalculate bill — payment already recorded for this month.');
        }

        $logs = DailyOrderLog::query()
            ->where('farm_id', $farm->id)
            ->where('customer_id', $customerId)
            ->where('billing_month', $billingMonth)
            ->whereIn('status', DeliveryLogPresenter::billableStatuses())
            ->get();

        $this->finalizeBillableLogs($logs);

        $subtotal = round((float) $logs->sum('line_total'), 2);

        if ($invoice === null) {
            if ($subtotal <= 0) {
                return null;
            }

            return $this->createInvoiceFromLogs($farm, $customerId, $billingMonth, $logs, $subtotal);
        }

        if ($subtotal <= 0) {
            $invoice->lines()->delete();
            $invoice->update([
                'subtotal' => 0,
                'discount_total' => 0,
                'total_amount' => 0,
                'balance_due' => 0,
            ]);

            return $invoice->fresh(['customer']);
        }

        $invoice->lines()->delete();

        $grouped = $logs->groupBy(fn (DailyOrderLog $log) => implode('|', [
            $log->subscription_id,
            $log->product_id,
            $log->shift instanceof DeliveryShift ? $log->shift->value : (string) $log->shift,
        ]));

        foreach ($grouped as $group) {
            /** @var DailyOrderLog $first */
            $first = $group->first();

            InvoiceLine::query()->create([
                'invoice_id' => $invoice->id,
                'subscription_id' => $first->subscription_id,
                'product_id' => $first->product_id,
                'product_name' => $first->product_name,
                'shift' => $first->shift,
                'delivery_days' => $group->count(),
                'total_quantity' => round((float) $group->sum('quantity'), 2),
                'unit_rate' => $first->unit_rate,
                'line_total' => round((float) $group->sum('line_total'), 2),
            ]);
        }

        $invoice->update([
            'subtotal' => $subtotal,
            'total_amount' => $subtotal,
            'balance_due' => $subtotal,
        ]);

        return $invoice->fresh(['customer']);
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $logs
     */
    private function createInvoiceFromLogs(
        Farm $farm,
        int $customerId,
        string $billingMonth,
        Collection $logs,
        float $subtotal,
    ): Invoice {
        $sequence = (int) Invoice::query()
            ->where('farm_id', $farm->id)
            ->where('billing_month', $billingMonth)
            ->count() + 1;

        $issuedAt = Carbon::createFromFormat('Y-m', $billingMonth)->addMonth()->startOfMonth();
        $invoiceNumber = sprintf(
            'INV-%s-%04d',
            str_replace('-', '', $billingMonth),
            $sequence,
        );

        $invoice = Invoice::query()->create([
            'farm_id' => $farm->id,
            'customer_id' => $customerId,
            'billing_month' => $billingMonth,
            'invoice_number' => $invoiceNumber,
            'subtotal' => $subtotal,
            'discount_total' => 0,
            'total_amount' => $subtotal,
            'amount_paid' => 0,
            'balance_due' => $subtotal,
            'status' => InvoiceStatus::Issued,
            'issued_at' => $issuedAt,
            'due_date' => $issuedAt->copy()->addDays(10),
        ]);

        $grouped = $logs->groupBy(fn (DailyOrderLog $log) => implode('|', [
            $log->subscription_id,
            $log->product_id,
            $log->shift instanceof DeliveryShift ? $log->shift->value : (string) $log->shift,
        ]));

        foreach ($grouped as $group) {
            /** @var DailyOrderLog $first */
            $first = $group->first();

            InvoiceLine::query()->create([
                'invoice_id' => $invoice->id,
                'subscription_id' => $first->subscription_id,
                'product_id' => $first->product_id,
                'product_name' => $first->product_name,
                'shift' => $first->shift,
                'delivery_days' => $group->count(),
                'total_quantity' => round((float) $group->sum('quantity'), 2),
                'unit_rate' => $first->unit_rate,
                'line_total' => round((float) $group->sum('line_total'), 2),
            ]);
        }

        return $invoice->fresh(['customer']);
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $logs
     */
    private function finalizeBillableLogs(Collection $logs): void
    {
        $pendingIds = $logs
            ->filter(fn (DailyOrderLog $log) => $log->status === OrderLogStatus::Pending)
            ->pluck('id');

        if ($pendingIds->isNotEmpty()) {
            DailyOrderLog::query()
                ->whereIn('id', $pendingIds)
                ->update(['status' => OrderLogStatus::Delivered]);
        }
    }
}
