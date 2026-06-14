<?php

namespace App\Services\Operations;

use App\Enums\DeliveryShift;
use App\Enums\OrderLogStatus;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\DeliveryRoute;
use App\Models\Farm;
use App\Models\Product;
use App\Models\RouteCustomerAssignment;
use Illuminate\Support\Collection;

class RouteDeliverySummaryService
{
    public function __construct(
        private readonly MilkPreparationSummaryBuilder $milkPrep,
    ) {}

    /**
     * @param  Collection<int, DeliveryRoute>  $routes
     * @return array{
     *     assignments: Collection<int|string, Collection<int, RouteCustomerAssignment>>,
     *     daily_orders: Collection<int, DailyOrderLog>,
     *     products: Collection<int, Product>,
     * }
     */
    public function loadContext(Farm $farm, Collection $routes, string $date): array
    {
        $routeIds = $routes->pluck('id');

        $assignments = RouteCustomerAssignment::query()
            ->whereIn('route_id', $routeIds)
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->with([
                'customer.subscriptions' => fn ($q) => $q
                    ->where('status', 'active')
                    ->whereNull('deleted_at'),
                'customer.subscriptions.lines.product',
            ])
            ->orderBy('sort_order')
            ->get()
            ->groupBy('route_id');

        $customerIds = $assignments->flatten(1)->pluck('customer_id')->unique();

        $dailyOrders = DailyOrderLog::query()
            ->where('farm_id', $farm->id)
            ->whereIn('customer_id', $customerIds)
            ->whereDate('delivery_date', $date)
            ->get();

        $products = $farm->products()
            ->with(['milkType', 'containerType.sizes'])
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        return [
            'assignments'  => $assignments,
            'daily_orders' => $dailyOrders,
            'products'     => $products,
        ];
    }

    /**
     * @param  array<string, mixed>  $context
     * @param  array<string, mixed>|null  $deliveryBoy
     * @return array<string, mixed>
     */
    public function formatRouteSummary(
        DeliveryRoute $route,
        array $context,
        string $date,
        ?array $deliveryBoy = null,
    ): array {
        $assignments = ($context['assignments'][$route->id] ?? collect());
        $formattedCustomers = $assignments->map(
            fn (RouteCustomerAssignment $a) => $this->formatAssignment($a, $route, $context, $date)
        );

        $deliverableCount = $formattedCustomers
            ->filter(fn (array $row) => $row['is_deliverable'] ?? false)
            ->count();

        $offCount = $formattedCustomers
            ->filter(fn (array $row) => ($row['on_vacation'] ?? false) || ($row['is_skipped'] ?? false))
            ->count();

        $milkPrepCards = $this->milkPreparationForRoute($route, $context, $date);
        $totalLiters   = array_sum(array_map(
            fn (array $card) => (float) ($card['total_liters'] ?? 0),
            $milkPrepCards,
        ));

        return [
            'id'                => $route->id,
            'name'              => $route->name,
            'shift'             => $route->shift,
            'sort_order'        => $route->sort_order,
            'is_active'         => $route->is_active,
            'customer_count'    => $assignments->count(),
            'deliverable_count' => $deliverableCount,
            'off_count'         => $offCount,
            'total_liters'      => round($totalLiters, 1),
            'delivery_boy'      => $deliveryBoy,
            'milk_preparation'  => $milkPrepCards,
        ];
    }

    /**
     * @param  array<string, mixed>  $context
     * @return array<string, mixed>
     */
    public function formatAssignment(
        RouteCustomerAssignment $assignment,
        DeliveryRoute $route,
        array $context,
        string $date,
    ): array {
        $customer = $assignment->customer;
        $lines    = $this->deliveryLinesForCustomer($customer, $route, $context['daily_orders']);
        $onVacation = $customer->isOnVacation();
        $isSkipped  = collect($lines)->contains(
            fn (array $line) => ($line['status'] ?? '') === 'skipped'
        );

        $isDeliverable = ! $onVacation && ! $isSkipped && collect($lines)->contains(
            fn (array $line) => ($line['quantity'] ?? 0) > 0
                && ! in_array($line['status'] ?? '', ['skipped', 'cancelled', 'vacation'], true)
        );

        return [
            'id'             => $assignment->id,
            'sort_order'     => $assignment->sort_order,
            'on_vacation'    => $onVacation,
            'is_skipped'     => $isSkipped,
            'is_deliverable' => $isDeliverable,
            'customer'       => $this->formatCustomer($customer),
            'delivery_lines' => $lines,
        ];
    }

    /**
     * @param  array<string, mixed>  $context
     * @return list<array<string, mixed>>
     */
    public function milkPreparationForRoute(DeliveryRoute $route, array $context, string $date): array
    {
        $assignments = $context['assignments'][$route->id] ?? collect();
        if ($assignments->isEmpty()) {
            return [];
        }

        $routeCustomerIds = $assignments->pluck('customer_id')->all();
        $shift            = DeliveryShift::from((string) $route->shift);

        $vacationIds = $assignments
            ->map(fn (RouteCustomerAssignment $a) => $a->customer)
            ->filter(fn (Customer $c) => $c->isOnVacation())
            ->pluck('id')
            ->all();

        $routeOrders = $context['daily_orders']->filter(
            fn (DailyOrderLog $log) => in_array($log->customer_id, $routeCustomerIds, true)
                && $log->shift === $shift
                && ! in_array($log->customer_id, $vacationIds, true)
        );

        try {
            $summary = $this->milkPrep->build(
                $routeOrders,
                $context['products'],
                $date,
                $route->farm_id,
            );

            return $summary[$shift->value] ?? [];
        } catch (\Throwable) {
            return [];
        }
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $allDailyOrders
     * @return list<array<string, mixed>>
     */
    private function deliveryLinesForCustomer(
        Customer $customer,
        DeliveryRoute $route,
        Collection $allDailyOrders,
    ): array {
        $shift = DeliveryShift::from((string) $route->shift);

        if ($customer->isOnVacation()) {
            return $this->subscriptionLinesForShift($customer, $shift, 0, 'vacation');
        }

        $orders = $allDailyOrders->filter(
            fn (DailyOrderLog $log) => $log->customer_id === $customer->id && $log->shift === $shift
        );

        if ($orders->isNotEmpty()) {
            return $orders->map(fn (DailyOrderLog $log) => [
                'order_id'     => $log->id,
                'product_id'   => $log->product_id,
                'product_name' => $log->product_name ?? '',
                'quantity'     => (float) $log->quantity,
                'status'       => $log->status instanceof OrderLogStatus
                    ? $log->status->value
                    : (string) $log->status,
            ])->values()->all();
        }

        return $this->subscriptionLinesForShift($customer, $shift, null, 'expected');
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function subscriptionLinesForShift(
        Customer $customer,
        DeliveryShift $shift,
        ?float $quantity,
        string $status,
    ): array {
        $lines = [];

        foreach ($customer->subscriptions ?? [] as $subscription) {
            foreach ($subscription->lines ?? [] as $line) {
                $lineShift = $line->shift instanceof DeliveryShift
                    ? $line->shift
                    : DeliveryShift::from((string) $line->shift);

                if ($lineShift !== $shift) {
                    continue;
                }

                $product = $line->product;
                if ($product === null) {
                    continue;
                }

                $qty = $quantity ?? (float) $line->quantity;

                $lines[] = [
                    'product_id'   => $product->id,
                    'product_name' => $product->name ?? '',
                    'quantity'     => $qty,
                    'status'       => $status,
                ];
            }
        }

        return $lines;
    }

    /** @return array<string, mixed> */
    private function formatCustomer(Customer $customer): array
    {
        return [
            'id'      => $customer->id,
            'name'    => trim($customer->first_name.' '.$customer->last_name),
            'address' => trim(implode(', ', array_filter([
                $customer->address_line,
                $customer->area,
                $customer->landmark,
                $customer->city,
            ]))),
        ];
    }
}
