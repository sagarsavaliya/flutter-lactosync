<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyRouteAssignment;
use App\Models\DeliveryRoute;
use App\Models\RouteCustomerAssignment;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Delivery Boy app endpoints.
 *
 * All routes are protected by auth:delivery_boy.
 */
class DeliveryBoyController extends Controller
{
    /**
     * GET /api/delivery-boy/v1/route-sheet?date=YYYY-MM-DD&shift=morning|evening
     *
     * Returns the route(s) assigned to this delivery boy on the given date/shift,
     * with customers and their order status.
     *
     * Per spec: delivery boy sees full name + address, NO phone number.
     * Skip status is visible so they know who to skip.
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

        // Find routes assigned to this delivery boy for this date + shift.
        $routeIds = DeliveryBoyRouteAssignment::where('delivery_boy_id', $boy->id)
            ->where('assigned_date', $date)
            ->pluck('route_id');

        if ($routeIds->isEmpty()) {
            return ApiResponse::success([]);
        }

        $routes = DeliveryRoute::whereIn('id', $routeIds)
            ->where('shift', $shift)
            ->orderBy('sort_order')
            ->get();

        // Batch-load standing customer assignments.
        $standingAssignments = RouteCustomerAssignment::whereIn('route_id', $routes->pluck('id'))
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->with('customer')
            ->orderBy('sort_order')
            ->get()
            ->groupBy('route_id');

        // Batch-load daily orders.
        $customerIds = $standingAssignments->flatten()->pluck('customer_id')->unique();
        $dailyOrders = DailyOrderLog::whereIn('customer_id', $customerIds)
            ->whereDate('delivery_date', $date)
            ->get()
            ->keyBy('customer_id');

        $data = $routes->map(function (DeliveryRoute $route) use ($standingAssignments, $dailyOrders): array {
            $customers = ($standingAssignments[$route->id] ?? collect())->map(
                function (RouteCustomerAssignment $a) use ($dailyOrders): array {
                    $order    = $dailyOrders[$a->customer_id] ?? null;
                    $customer = $a->customer;

                    return [
                        'assignment_id' => $a->id,
                        'sort_order'    => $a->sort_order,
                        // NO phone number for delivery boy view (per spec)
                        'customer'      => [
                            'id'      => $customer->id,
                            'name'    => trim($customer->first_name . ' ' . $customer->last_name),
                            'address' => trim(implode(', ', array_filter([
                                $customer->address_line,
                                $customer->area,
                                $customer->landmark,
                                $customer->city,
                            ]))),
                        ],
                        'order' => $order ? [
                            'id'      => $order->id,
                            'qty'     => $order->qty,
                            'status'  => $order->status,
                            'skipped' => $order->status === 'skipped',
                        ] : null,
                    ];
                }
            );

            return [
                'route_id'   => $route->id,
                'route_name' => $route->name,
                'shift'      => $route->shift,
                'customers'  => $customers,
            ];
        });

        return ApiResponse::success($data);
    }

    /**
     * POST /api/delivery-boy/v1/skip-delivery
     *
     * Delivery boy marks a specific customer's order as skipped for a date.
     */
    public function skipDelivery(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'date'        => ['required', 'date_format:Y-m-d'],
        ]);

        /** @var DeliveryBoy $boy */
        $boy = $request->user();

        // Verify the customer is on a route assigned to this delivery boy today.
        $assignedRouteIds = DeliveryBoyRouteAssignment::where('delivery_boy_id', $boy->id)
            ->where('assigned_date', $validated['date'])
            ->pluck('route_id');

        $onRoute = RouteCustomerAssignment::whereIn('route_id', $assignedRouteIds)
            ->where('customer_id', $validated['customer_id'])
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->exists();

        if (! $onRoute) {
            return ApiResponse::error('NOT_ON_ROUTE', 'Customer is not on your route for this date.', 403);
        }

        $order = DailyOrderLog::where('customer_id', $validated['customer_id'])
            ->whereDate('delivery_date', $validated['date'])
            ->first();

        if (! $order) {
            return ApiResponse::error('NO_ORDER', 'No order found for this customer on that date.', 404);
        }

        $order->update(['status' => 'skipped']);

        return ApiResponse::success(['message' => 'Delivery marked as skipped.']);
    }
}
