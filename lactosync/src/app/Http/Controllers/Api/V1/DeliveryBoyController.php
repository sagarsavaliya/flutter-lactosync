<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\OrderLogStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentType;
use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyRouteAssignment;
use App\Models\DeliveryRoute;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\RouteCustomerAssignment;
use App\Services\Operations\RouteDeliverySummaryService;
use App\Support\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Delivery Boy app endpoints.
 *
 * All routes are protected by auth:delivery_boy.
 */
class DeliveryBoyController extends Controller
{
    public function __construct(
        private readonly RouteDeliverySummaryService $routeSummary,
    ) {}

    /**
     * GET /api/delivery-boy/v1/route-sheet?date=YYYY-MM-DD&shift=morning|evening
     *
     * Returns assigned route(s) with packing manifest, customers, and order status.
     * Delivery boys see name + address only — no phone numbers.
     */
    public function routeSheet(Request $request): JsonResponse
    {
        $request->validate([
            'date'  => ['required', 'date_format:Y-m-d'],
            'shift' => ['required', 'string', 'in:morning,evening'],
        ]);

        /** @var DeliveryBoy $boy */
        $boy   = $request->user();
        $date  = $request->input('date');
        $shift = $request->input('shift');

        $routeIds = $this->resolveRouteIdsForBoy($boy, $date);

        if ($routeIds->isEmpty()) {
            return ApiResponse::success([
                'delivery_boy_name' => $boy->name,
                'routes'          => [],
            ]);
        }

        $routes = DeliveryRoute::whereIn('id', $routeIds)
            ->where('shift', $shift)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        $boy->loadMissing('farm');
        $context = $this->routeSummary->loadContext($boy->farm, $routes, $date);

        $customerIds = $routes
            ->flatMap(fn (DeliveryRoute $r) => ($context['assignments'][$r->id] ?? collect())->pluck('customer_id'))
            ->unique()
            ->values();

        $outstandingByCustomer = Invoice::query()
            ->whereIn('customer_id', $customerIds)
            ->where('balance_due', '>', 0)
            ->selectRaw('customer_id, SUM(balance_due) as total_due')
            ->groupBy('customer_id')
            ->pluck('total_due', 'customer_id');

        $data = $routes->map(function (DeliveryRoute $route) use ($context, $date, $outstandingByCustomer): array {
            $summary   = $this->routeSummary->formatRouteSummary($route, $context, $date);
            $customers = ($context['assignments'][$route->id] ?? collect())->map(
                function (RouteCustomerAssignment $a) use ($route, $context, $date, $outstandingByCustomer): array {
                    $row      = $this->routeSummary->formatAssignment($a, $route, $context, $date);
                    $customer = $a->customer;

                    return [
                        'assignment_id'       => $row['id'],
                        'sort_order'          => $row['sort_order'],
                        'on_vacation'         => $row['on_vacation'],
                        'is_skipped'          => $row['is_skipped'],
                        'is_deliverable'      => $row['is_deliverable'],
                        'outstanding_balance' => round((float) ($outstandingByCustomer[$customer->id] ?? 0), 2),
                        'customer'            => $row['customer'],
                        'delivery_lines'      => $row['delivery_lines'],
                    ];
                }
            )->values();

            return [
                'route_id'           => $route->id,
                'route_name'         => $route->name,
                'shift'              => $route->shift,
                'total_liters'       => $summary['total_liters'],
                'customer_count'     => $summary['customer_count'],
                'deliverable_count'  => $summary['deliverable_count'],
                'milk_preparation'   => $summary['milk_preparation'],
                'customers'          => $customers,
            ];
        });

        return ApiResponse::success([
            'delivery_boy_name' => $boy->name,
            'routes'            => $data,
        ]);
    }

    /**
     * POST /api/delivery-boy/v1/mark-delivered
     */
    public function markDelivered(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id'      => ['required', 'integer', 'exists:daily_order_logs,id'],
            'date'          => ['required', 'date_format:Y-m-d'],
            'quantity'      => ['sometimes', 'numeric', 'min:0', 'max:999'],
            'cash_received' => ['sometimes', 'numeric', 'min:0'],
        ]);

        /** @var DeliveryBoy $boy */
        $boy = $request->user();

        $order = DailyOrderLog::query()->findOrFail($validated['order_id']);

        if ($order->farm_id !== $boy->farm_id) {
            return ApiResponse::error('NOT_FOUND', 'Order not found.', 404);
        }

        if (! $this->customerOnBoyRoute($boy, (int) $order->customer_id, $validated['date'])) {
            return ApiResponse::error('NOT_ON_ROUTE', 'Customer is not on your route for this date.', 403);
        }

        if (array_key_exists('quantity', $validated)) {
            $order->quantity = $validated['quantity'];
        }

        $order->status     = OrderLogStatus::Delivered;
        $order->line_total = DailyOrderLog::computeLineTotal(
            (float) $order->quantity,
            (float) $order->unit_rate,
        );
        $order->save();

        $paymentId = null;
        $cash      = (float) ($validated['cash_received'] ?? 0);

        if ($cash > 0) {
            $invoice = Invoice::query()
                ->where('customer_id', $order->customer_id)
                ->where('balance_due', '>', 0)
                ->orderByDesc('billing_month')
                ->first();

            if ($invoice !== null) {
                $amount  = min($cash, (float) $invoice->balance_due);
                $payment = Payment::query()->create([
                    'farm_id'        => $boy->farm_id,
                    'customer_id'    => $order->customer_id,
                    'invoice_id'     => $invoice->id,
                    'amount'         => $amount,
                    'payment_type'   => PaymentType::Receipt,
                    'payment_method' => PaymentMethod::Cash,
                    'payment_date'   => Carbon::today(),
                    'recorded_by'    => null,
                    'notes'          => 'Collected by delivery boy '.$boy->name,
                ]);
                $invoice->refreshPaymentTotals();
                $paymentId = $payment->id;
            }
        }

        return ApiResponse::success([
            'order_id'   => $order->id,
            'status'     => $order->status->value,
            'payment_id' => $paymentId,
        ]);
    }

    /**
     * GET /api/delivery-boy/v1/cash-collections?date=YYYY-MM-DD
     */
    public function cashCollections(Request $request): JsonResponse
    {
        $request->validate([
            'date' => ['required', 'date_format:Y-m-d'],
        ]);

        /** @var DeliveryBoy $boy */
        $boy  = $request->user();
        $date = $request->input('date');

        $payments = Payment::query()
            ->where('farm_id', $boy->farm_id)
            ->where('payment_method', PaymentMethod::Cash)
            ->whereDate('payment_date', $date)
            ->where('notes', 'like', 'Collected by delivery boy '.$boy->name.'%')
            ->with('customer:id,first_name,last_name')
            ->orderByDesc('created_at')
            ->get();

        $items = $payments->map(function (Payment $p) {
            $customer = $p->customer;

            return [
                'payment_id'    => $p->id,
                'customer_name' => $customer
                    ? trim($customer->first_name.' '.$customer->last_name)
                    : 'Customer',
                'amount'        => (float) $p->amount,
                'recorded_at'   => $p->created_at?->toIso8601String(),
            ];
        });

        return ApiResponse::success([
            'total' => round((float) $items->sum('amount'), 2),
            'items' => $items,
        ]);
    }

    /**
     * POST /api/delivery-boy/v1/skip-delivery
     */
    public function skipDelivery(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'date'        => ['required', 'date_format:Y-m-d'],
        ]);

        /** @var DeliveryBoy $boy */
        $boy = $request->user();

        if (! $this->customerOnBoyRoute($boy, (int) $validated['customer_id'], $validated['date'])) {
            return ApiResponse::error('NOT_ON_ROUTE', 'Customer is not on your route for this date.', 403);
        }

        $orders = DailyOrderLog::where('customer_id', $validated['customer_id'])
            ->whereDate('delivery_date', $validated['date'])
            ->get();

        if ($orders->isEmpty()) {
            return ApiResponse::error('NO_ORDER', 'No order found for this customer on that date.', 404);
        }

        foreach ($orders as $order) {
            $order->update([
                'status'   => OrderLogStatus::Skipped,
                'quantity' => 0,
            ]);
        }

        return ApiResponse::success(['message' => 'Delivery marked as skipped.']);
    }

    private function customerOnBoyRoute(DeliveryBoy $boy, int $customerId, string $date): bool
    {
        $assignedRouteIds = $this->resolveRouteIdsForBoy($boy, $date);

        return RouteCustomerAssignment::whereIn('route_id', $assignedRouteIds)
            ->where('customer_id', $customerId)
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->exists();
    }

    /**
     * Standing assignment first; fall back to legacy per-day rows for migration.
     *
     * @return \Illuminate\Support\Collection<int, int>
     */
    private function resolveRouteIdsForBoy(DeliveryBoy $boy, string $date): \Illuminate\Support\Collection
    {
        $standing = DeliveryBoyRouteAssignment::where('delivery_boy_id', $boy->id)
            ->where('assigned_date', DeliveryBoyRouteAssignment::STANDING_DATE)
            ->pluck('route_id');

        if ($standing->isNotEmpty()) {
            return $standing;
        }

        $dated = DeliveryBoyRouteAssignment::where('delivery_boy_id', $boy->id)
            ->where('assigned_date', $date)
            ->pluck('route_id');

        if ($dated->isNotEmpty()) {
            return $dated;
        }

        return DeliveryBoyRouteAssignment::where('delivery_boy_id', $boy->id)
            ->orderByDesc('assigned_date')
            ->get()
            ->unique('route_id')
            ->pluck('route_id');
    }
}
