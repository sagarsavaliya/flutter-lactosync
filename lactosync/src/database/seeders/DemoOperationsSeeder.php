<?php

namespace Database\Seeders;

use App\Enums\DeliveryShift;
use App\Enums\InvoiceStatus;
use App\Enums\OrderLogStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentType;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\Farm;
use App\Models\Invoice;
use App\Models\InvoiceLine;
use App\Models\Payment;
use App\Models\Subscription;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class DemoOperationsSeeder extends Seeder
{
    private const DELIVERY_BOYS = ['Raj', 'Kiran', 'Mahesh', 'Suresh'];

    public function run(): void
    {
        $farms = Farm::query()->get();

        if ($farms->isEmpty()) {
            $this->command?->warn('No farms found — register an owner first.');

            return;
        }

        foreach ($farms as $farm) {
            $this->seedFarmOperations($farm);
        }
    }

    private function seedFarmOperations(Farm $farm): void
    {
        $today = Carbon::today();

        if (DailyOrderLog::query()->where('farm_id', $farm->id)->exists()) {
            $added = $this->backfillOrdersToToday($farm, $today);
            $regenerated = $this->regenerateTodayOrders($farm, $today);
            $this->command?->info(
                "Farm #{$farm->id}: backfilled {$added} order logs; refreshed {$regenerated} logs for today.",
            );

            return;
        }

        $start = $today->copy()->subMonths(2)->startOfMonth();
        $end = $today->copy();

        $subscriptions = Subscription::query()
            ->where('farm_id', $farm->id)
            ->where('status', 'active')
            ->with(['customer', 'lines.product'])
            ->get();

        $orderCount = 0;

        foreach ($subscriptions as $subscription) {
            $customer = $subscription->customer;
            if ($customer === null || ! $customer->is_active) {
                continue;
            }

            foreach ($subscription->lines as $line) {
                $product = $line->product;
                if ($product === null) {
                    continue;
                }

                for ($date = $start->copy(); $date->lte($end); $date->addDay()) {
                    if ($this->shouldSkipDay($customer, $date)) {
                        continue;
                    }

                    $status = $this->resolveOrderStatus($date, $today);
                    $qty = (float) $line->quantity;
                    if ($status === OrderLogStatus::Skipped) {
                        $qty = 0;
                    }

                    DailyOrderLog::query()->create([
                        'farm_id' => $farm->id,
                        'customer_id' => $customer->id,
                        'subscription_id' => $subscription->id,
                        'subscription_line_id' => $line->id,
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'quantity' => $qty,
                        'unit_rate' => $line->effective_rate,
                        'line_total' => DailyOrderLog::computeLineTotal($qty, (float) $line->effective_rate),
                        'shift' => $line->shift,
                        'status' => $status,
                        'delivery_date' => $date->toDateString(),
                        'billing_month' => DailyOrderLog::billingMonthFor($date),
                    ]);

                    $orderCount++;
                }
            }
        }

        $invoiceCount = $this->seedInvoicesForFarm($farm, $start, $today);

        $this->command?->info(
            "Farm #{$farm->id}: seeded {$orderCount} order logs and {$invoiceCount} invoices.",
        );
    }

    private function backfillOrdersToToday(Farm $farm, Carbon $today): int
    {
        $lastDateRaw = DailyOrderLog::query()
            ->where('farm_id', $farm->id)
            ->max('delivery_date');

        if ($lastDateRaw === null) {
            return 0;
        }

        $cursor = Carbon::parse($lastDateRaw)->addDay()->startOfDay();
        $through = $today->copy()->subDay()->startOfDay();
        if ($cursor->gt($through)) {
            return 0;
        }

        $subscriptions = Subscription::query()
            ->where('farm_id', $farm->id)
            ->where('status', 'active')
            ->with(['customer', 'lines.product'])
            ->get();

        $orderCount = 0;

        foreach ($subscriptions as $subscription) {
            $customer = $subscription->customer;
            if ($customer === null || ! $customer->is_active) {
                continue;
            }

            foreach ($subscription->lines as $line) {
                $product = $line->product;
                if ($product === null) {
                    continue;
                }

                for ($date = $cursor->copy(); $date->lte($through); $date->addDay()) {
                    if ($this->shouldSkipDay($customer, $date)) {
                        continue;
                    }

                    if (DailyOrderLog::query()
                        ->where('farm_id', $farm->id)
                        ->where('subscription_line_id', $line->id)
                        ->whereDate('delivery_date', $date)
                        ->exists()) {
                        continue;
                    }

                    $status = $this->resolveOrderStatus($date, $today);
                    $qty = (float) $line->quantity;
                    if ($status === OrderLogStatus::Skipped) {
                        $qty = 0;
                    }

                    DailyOrderLog::query()->create([
                        'farm_id' => $farm->id,
                        'customer_id' => $customer->id,
                        'subscription_id' => $subscription->id,
                        'subscription_line_id' => $line->id,
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'quantity' => $qty,
                        'unit_rate' => $line->effective_rate,
                        'line_total' => DailyOrderLog::computeLineTotal($qty, (float) $line->effective_rate),
                        'shift' => $line->shift,
                        'status' => $status,
                        'delivery_date' => $date->toDateString(),
                        'billing_month' => DailyOrderLog::billingMonthFor($date),
                    ]);

                    $orderCount++;
                }
            }
        }

        return $orderCount;
    }

    private function regenerateTodayOrders(Farm $farm, Carbon $today): int
    {
        DailyOrderLog::query()
            ->withTrashed()
            ->where('farm_id', $farm->id)
            ->whereDate('delivery_date', $today)
            ->forceDelete();

        $subscriptions = Subscription::query()
            ->where('farm_id', $farm->id)
            ->where('status', 'active')
            ->with(['customer', 'lines.product'])
            ->get();

        $orderCount = 0;

        foreach ($subscriptions as $subscription) {
            $customer = $subscription->customer;
            if ($customer === null || ! $customer->is_active) {
                continue;
            }

            if ($this->shouldSkipDay($customer, $today)) {
                continue;
            }

            foreach ($subscription->lines as $line) {
                $product = $line->product;
                if ($product === null) {
                    continue;
                }

                $status = $this->resolveOrderStatus($today, $today);
                $qty = (float) $line->quantity;
                if ($status === OrderLogStatus::Skipped) {
                    $qty = 0;
                }

                DailyOrderLog::query()->create([
                    'farm_id' => $farm->id,
                    'customer_id' => $customer->id,
                    'subscription_id' => $subscription->id,
                    'subscription_line_id' => $line->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'quantity' => $qty,
                    'unit_rate' => $line->effective_rate,
                    'line_total' => DailyOrderLog::computeLineTotal($qty, (float) $line->effective_rate),
                    'shift' => $line->shift,
                    'status' => $status,
                    'delivery_date' => $today->toDateString(),
                    'billing_month' => DailyOrderLog::billingMonthFor($today),
                ]);

                $orderCount++;
            }
        }

        return $orderCount;
    }

    private function shouldSkipDay(Customer $customer, Carbon $date): bool
    {
        if ($customer->vacation_start !== null && $customer->vacation_end !== null) {
            return $date->between(
                $customer->vacation_start->startOfDay(),
                $customer->vacation_end->startOfDay(),
            );
        }

        return false;
    }

    private function resolveOrderStatus(Carbon $date, Carbon $today): OrderLogStatus
    {
        if ($date->isSameDay($today)) {
            return OrderLogStatus::Delivered;
        }

        if ($date->isFuture()) {
            return OrderLogStatus::Pending;
        }

        if ($date->dayOfWeek === Carbon::SUNDAY && $date->day % 7 === 0) {
            return OrderLogStatus::Skipped;
        }

        return OrderLogStatus::Delivered;
    }

    private function seedInvoicesForFarm(Farm $farm, Carbon $rangeStart, Carbon $today): int
    {
        $months = collect();
        $cursor = $rangeStart->copy()->startOfMonth();

        while ($cursor->lt($today->copy()->startOfMonth())) {
            $months->push($cursor->format('Y-m'));
            $cursor->addMonth();
        }

        $invoiceCount = 0;
        $sequence = 1;

        foreach ($months as $billingMonth) {
            $logsByCustomer = DailyOrderLog::query()
                ->where('farm_id', $farm->id)
                ->where('billing_month', $billingMonth)
                ->where('status', OrderLogStatus::Delivered)
                ->get()
                ->groupBy('customer_id');

            foreach ($logsByCustomer as $customerId => $logs) {
                /** @var Collection<int, DailyOrderLog> $logs */
                $subtotal = round((float) $logs->sum('line_total'), 2);
                if ($subtotal <= 0) {
                    continue;
                }

                $invoiceNumber = sprintf('INV-%s-%04d', str_replace('-', '', $billingMonth), $sequence++);
                $issuedAt = Carbon::createFromFormat('Y-m', $billingMonth)->addMonth()->startOfMonth();

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

                $this->seedSamplePayments($farm, $invoice, $issuedAt);
                $invoice->refreshPaymentTotals();
                $invoiceCount++;
            }
        }

        return $invoiceCount;
    }

    private function seedSamplePayments(Farm $farm, Invoice $invoice, Carbon $issuedAt): void
    {
        $total = (float) $invoice->total_amount;
        $bucket = $invoice->customer_id % 5;

        if ($bucket === 0) {
            Payment::query()->create([
                'farm_id' => $farm->id,
                'customer_id' => $invoice->customer_id,
                'invoice_id' => $invoice->id,
                'amount' => $total,
                'payment_type' => PaymentType::Jama,
                'payment_method' => PaymentMethod::Cash,
                'payment_date' => $issuedAt->copy()->addDays(3),
                'handed_to' => self::DELIVERY_BOYS[$invoice->customer_id % count(self::DELIVERY_BOYS)],
                'notes' => 'Full payment collected on delivery route',
            ]);

            return;
        }

        if ($bucket === 1) {
            Payment::query()->create([
                'farm_id' => $farm->id,
                'customer_id' => $invoice->customer_id,
                'invoice_id' => $invoice->id,
                'amount' => round($total * 0.5, 2),
                'payment_type' => PaymentType::Jama,
                'payment_method' => PaymentMethod::Upi,
                'payment_date' => $issuedAt->copy()->addDays(5),
                'notes' => 'Partial UPI payment',
            ]);

            return;
        }

        if ($bucket === 2) {
            Payment::query()->create([
                'farm_id' => $farm->id,
                'customer_id' => $invoice->customer_id,
                'invoice_id' => $invoice->id,
                'amount' => round($total * 0.3, 2),
                'payment_type' => PaymentType::Jama,
                'payment_method' => PaymentMethod::Cash,
                'payment_date' => $issuedAt->copy()->addDays(2),
                'handed_to' => self::DELIVERY_BOYS[0],
                'notes' => 'Advance cash — balance udhar',
            ]);
        }
    }
}
