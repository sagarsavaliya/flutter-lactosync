<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\DailyOrderLog;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyRouteAssignment;
use App\Models\DeliveryRoute;
use App\Models\FarmOwner;
use App\Models\RouteCustomerAssignment;
use App\Services\Operations\RouteDeliverySummaryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/**
 * Owner-facing delivery management endpoints.
 *
 * All routes are nested under /api/v1/owner and protected by:
 *   - auth:sanctum (owner token)
 *   - check.subscription
 *   - module:route_delivery
 */
class OwnerDeliveryController extends Controller
{
    public function __construct(
        private readonly RouteDeliverySummaryService $routeSummary,
    ) {}

    // =========================================================================
    // S8-07 — Delivery boys CRUD
    // =========================================================================

    /** GET /owner/delivery-boys */
    public function deliveryBoys(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $boys = DeliveryBoy::where('farm_id', $owner->farm_id)
            ->orderBy('name')
            ->get()
            ->map(fn (DeliveryBoy $b) => $this->formatBoy($b));

        return response()->json(['success' => true, 'data' => $boys]);
    }

    /** POST /owner/delivery-boys */
    public function storeDeliveryBoy(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $validated = $request->validate([
            'name'          => ['required', 'string', 'max:100'],
            'phone'         => ['nullable', 'string', 'max:20'],
            'salary_type'   => ['required', 'string', 'in:monthly,per_delivery,hourly,part_time'],
            'salary_amount' => ['nullable', 'numeric', 'min:0'],
        ]);

        $boy = DeliveryBoy::create([
            ...$validated,
            'farm_id'   => $owner->farm_id,
            'is_active' => true,
        ]);

        return response()->json(['success' => true, 'data' => $this->formatBoy($boy)], 201);
    }

    /** PATCH /owner/delivery-boys/{boy} */
    public function updateDeliveryBoy(Request $request, DeliveryBoy $boy): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($boy->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $validated = $request->validate([
            'name'          => ['sometimes', 'string', 'max:100'],
            'phone'         => ['sometimes', 'nullable', 'string', 'max:20'],
            'salary_type'   => ['sometimes', 'string', 'in:monthly,per_delivery,hourly,part_time'],
            'salary_amount' => ['sometimes', 'nullable', 'numeric', 'min:0'],
            'is_active'     => ['sometimes', 'boolean'],
        ]);

        $boy->update($validated);

        return response()->json(['success' => true, 'data' => $this->formatBoy($boy->fresh())]);
    }

    /**
     * POST /owner/delivery-boys/{boy}/reset-pin
     *
     * Generates a random 4-digit temporary PIN, hashes and stores it,
     * and returns the plain text PIN once so the owner can share it.
     */
    public function resetDeliveryBoyPin(Request $request, DeliveryBoy $boy): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($boy->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $pin = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        $boy->update(['pin_hash' => Hash::make($pin)]);

        return response()->json(['success' => true, 'data' => ['temporary_pin' => $pin]]);
    }

    /** DELETE /owner/delivery-boys/{boy} */
    public function destroyDeliveryBoy(Request $request, DeliveryBoy $boy): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($boy->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        // Prevent deleting a boy that has future route assignments.
        $hasFuture = DeliveryBoyRouteAssignment::where('delivery_boy_id', $boy->id)
            ->where('assigned_date', '>=', now()->toDateString())
            ->exists();

        if ($hasFuture) {
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'HAS_FUTURE_ASSIGNMENTS',
                    'message' => 'This delivery boy has upcoming route assignments. Deactivate instead.',
                ],
            ], 422);
        }

        $boy->delete();

        return response()->json(['success' => true]);
    }

    // =========================================================================
    // S8-08 — Routes CRUD
    // =========================================================================

    /** GET /owner/routes */
    public function routes(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();
        $date  = (string) $request->query('date', Carbon::today()->toDateString());

        $routes = DeliveryRoute::where('farm_id', $owner->farm_id)
            ->orderBy('shift')
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        $context = $this->routeSummary->loadContext($owner->farm, $routes, $date);

        $boyAssignments = DeliveryBoyRouteAssignment::query()
            ->whereIn('route_id', $routes->pluck('id'))
            ->where('assigned_date', $date)
            ->with('deliveryBoy')
            ->get()
            ->keyBy('route_id');

        $data = $routes->map(function (DeliveryRoute $route) use ($context, $date, $boyAssignments) {
            $boyAssignment = $boyAssignments[$route->id] ?? null;
            $boy           = $boyAssignment && $boyAssignment->deliveryBoy
                ? $this->formatBoy($boyAssignment->deliveryBoy)
                : null;

            return $this->routeSummary->formatRouteSummary($route, $context, $date, $boy);
        });

        return response()->json(['success' => true, 'data' => $data]);
    }

    /** POST /owner/routes */
    public function storeRoute(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $validated = $request->validate([
            'name'       => ['required', 'string', 'max:100'],
            'shift'      => ['required', 'string', 'in:morning,evening'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);

        $exists = DeliveryRoute::where('farm_id', $owner->farm_id)
            ->where('name', $validated['name'])
            ->where('shift', $validated['shift'])
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'ROUTE_EXISTS', 'message' => 'A route with this name already exists for this shift.'],
            ], 422);
        }

        $route = DeliveryRoute::create([
            ...$validated,
            'farm_id'    => $owner->farm_id,
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active'  => true,
        ]);

        return response()->json(['success' => true, 'data' => $this->formatRoute($route)], 201);
    }

    /** PATCH /owner/routes/{route} */
    public function updateRoute(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $validated = $request->validate([
            'name'       => ['sometimes', 'string', 'max:100'],
            'shift'      => ['sometimes', 'string', 'in:morning,evening'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
            'is_active'  => ['sometimes', 'boolean'],
        ]);

        $route->update($validated);

        return response()->json(['success' => true, 'data' => $this->formatRoute($route->fresh())]);
    }

    /** DELETE /owner/routes/{route} */
    public function destroyRoute(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        DB::transaction(function () use ($route): void {
            RouteCustomerAssignment::where('route_id', $route->id)->delete();
            DeliveryBoyRouteAssignment::where('route_id', $route->id)
                ->where('assigned_date', '>=', now()->toDateString())
                ->delete();
            $route->delete();
        });

        return response()->json(['success' => true]);
    }

    // =========================================================================
    // S8-09 — Route customer assignments
    // =========================================================================

    /** GET /owner/routes/{route}/customers */
    public function routeCustomers(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $date    = (string) $request->query('date', Carbon::today()->toDateString());
        $context = $this->routeSummary->loadContext($owner->farm, collect([$route]), $date);

        $assignments = RouteCustomerAssignment::where('route_id', $route->id)
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->with([
                'customer.subscriptions' => fn ($q) => $q
                    ->where('status', 'active')
                    ->whereNull('deleted_at'),
                'customer.subscriptions.lines.product',
            ])
            ->orderBy('sort_order')
            ->get()
            ->map(fn (RouteCustomerAssignment $a) => $this->routeSummary->formatAssignment(
                $a,
                $route,
                $context,
                $date,
            ));

        return response()->json(['success' => true, 'data' => $assignments]);
    }

    /**
     * GET /owner/routes/{route}/available-customers
     *
     * Active customers with a subscription on this route's shift who are not
     * already assigned to any route for this farm.
     */
    public function availableRouteCustomers(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $search = trim((string) $request->query('search', ''));

        $assignedCustomerIds = RouteCustomerAssignment::query()
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->whereHas('route', fn ($q) => $q->where('farm_id', $owner->farm_id))
            ->pluck('customer_id');

        $query = Customer::query()
            ->where('farm_id', $owner->farm_id)
            ->where('is_active', true)
            ->when(
                $assignedCustomerIds->isNotEmpty(),
                fn ($q) => $q->whereNotIn('id', $assignedCustomerIds),
            )
            ->whereHas('subscriptions', function ($q) use ($route) {
                $q->where('status', 'active')
                    ->whereNull('deleted_at')
                    ->whereHas('lines', fn ($line) => $line->where('shift', $route->shift));
            });

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('contact', 'like', "%{$search}%")
                    ->orWhere('area', 'like', "%{$search}%");
            });
        }

        $customers = $query
            ->orderBy('first_name')
            ->orderBy('last_name')
            ->get()
            ->map(fn (Customer $customer) => $this->formatCustomerForDelivery($customer))
            ->values();

        return response()->json(['success' => true, 'data' => $customers]);
    }

    /** POST /owner/routes/{route}/customers */
    public function addRouteCustomer(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $validated = $request->validate([
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'sort_order'  => ['nullable', 'integer', 'min:0'],
        ]);

        $customer = Customer::findOrFail($validated['customer_id']);

        if ($customer->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $maxOrder = RouteCustomerAssignment::where('route_id', $route->id)
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->max('sort_order') ?? -1;

        try {
            $assignment = RouteCustomerAssignment::create([
                'route_id'      => $route->id,
                'customer_id'   => $customer->id,
                'sort_order'    => $validated['sort_order'] ?? ($maxOrder + 1),
                'assigned_date' => RouteCustomerAssignment::STANDING_DATE,
            ]);
        } catch (\Illuminate\Database\UniqueConstraintViolationException) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'ALREADY_ASSIGNED', 'message' => 'Customer is already on this route.'],
            ], 422);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'id'         => $assignment->id,
                'sort_order' => $assignment->sort_order,
                'customer'   => $this->formatCustomerForDelivery($customer),
            ],
        ], 201);
    }

    /** DELETE /owner/routes/{route}/customers/{assignment} */
    public function removeRouteCustomer(Request $request, DeliveryRoute $route, RouteCustomerAssignment $assignment): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id || $assignment->route_id !== $route->id) {
            return $this->notFound();
        }

        $assignment->delete();

        return response()->json(['success' => true]);
    }

    /** PUT /owner/routes/{route}/customers/reorder */
    public function reorderRouteCustomers(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $request->validate([
            'order'   => ['required', 'array'],
            'order.*' => ['integer'],
        ]);

        // order = [assignment_id1, assignment_id2, ...] in desired order
        DB::transaction(function () use ($request, $route): void {
            foreach ($request->input('order') as $position => $assignmentId) {
                RouteCustomerAssignment::where('id', $assignmentId)
                    ->where('route_id', $route->id)
                    ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
                    ->update(['sort_order' => $position]);
            }
        });

        return $this->routeCustomers($request, $route);
    }

    // =========================================================================
    // S8-10 — Route-delivery-boy assignments
    // =========================================================================

    /** GET /owner/routes/{route}/assignments?date=YYYY-MM-DD */
    public function routeBoyAssignment(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $request->validate(['date' => ['required', 'date_format:Y-m-d']]);
        $date = $request->input('date');

        $assignment = DeliveryBoyRouteAssignment::where('route_id', $route->id)
            ->where('assigned_date', $date)
            ->with('deliveryBoy')
            ->first();

        return response()->json([
            'success' => true,
            'data'    => $assignment ? [
                'id'            => $assignment->id,
                'assigned_date' => $assignment->assigned_date->toDateString(),
                'delivery_boy'  => $this->formatBoy($assignment->deliveryBoy),
            ] : null,
        ]);
    }

    /** PUT /owner/routes/{route}/assignments */
    public function assignRouteDeliveryBoy(Request $request, DeliveryRoute $route): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        if ($route->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $validated = $request->validate([
            'delivery_boy_id' => ['required', 'integer', 'exists:delivery_boys,id'],
            'date'            => ['required', 'date_format:Y-m-d'],
        ]);

        $boy = DeliveryBoy::findOrFail($validated['delivery_boy_id']);
        if ($boy->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $now = now()->toDateTimeString();
        DB::table('delivery_boy_route_assignments')->upsert(
            [
                'route_id'        => $route->id,
                'delivery_boy_id' => $boy->id,
                'assigned_date'   => $validated['date'],
                'created_at'      => $now,
                'updated_at'      => $now,
            ],
            ['route_id', 'assigned_date'],
            ['delivery_boy_id', 'updated_at'],
        );

        return response()->json([
            'success' => true,
            'data'    => [
                'route_id'        => $route->id,
                'delivery_boy_id' => $boy->id,
                'assigned_date'   => $validated['date'],
                'delivery_boy'    => $this->formatBoy($boy),
            ],
        ]);
    }

    // =========================================================================
    // S8-14 — Owner daily route sheet
    // =========================================================================

    /**
     * GET /owner/route-sheet?date=YYYY-MM-DD&shift=morning|evening
     *
     * Returns all active routes for the shift with their customers and
     * today's order quantities so the owner sees the full packing view.
     */
    public function ownerRouteSheet(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $request->validate([
            'date'  => ['required', 'date_format:Y-m-d'],
            'shift' => ['required', 'string', 'in:morning,evening'],
        ]);

        $date  = $request->input('date');
        $shift = $request->input('shift');

        $routes = DeliveryRoute::where('farm_id', $owner->farm_id)
            ->where('shift', $shift)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        $routeIds = $routes->pluck('id');

        // Batch-load standing customer assignments for all routes.
        $standingAssignments = RouteCustomerAssignment::whereIn('route_id', $routeIds)
            ->where('assigned_date', RouteCustomerAssignment::STANDING_DATE)
            ->with('customer')
            ->orderBy('sort_order')
            ->get()
            ->groupBy('route_id');

        // Batch-load daily orders for these customers on the requested date + shift.
        $customerIds = $standingAssignments->flatten()->pluck('customer_id')->unique();
        $dailyOrders = DailyOrderLog::whereIn('customer_id', $customerIds)
            ->whereDate('delivery_date', $date)
            ->where('shift', $shift)
            ->get()
            ->groupBy('customer_id');

        // Batch-load delivery boy assignments for the date.
        $boyAssignments = DeliveryBoyRouteAssignment::whereIn('route_id', $routeIds)
            ->where('assigned_date', $date)
            ->with('deliveryBoy')
            ->get()
            ->keyBy('route_id');

        $data = $routes->map(function (DeliveryRoute $route) use ($standingAssignments, $dailyOrders, $boyAssignments): array {
            $customers = ($standingAssignments[$route->id] ?? collect())->map(
                function (RouteCustomerAssignment $a) use ($dailyOrders): array {
                    $ordersForCustomer = $dailyOrders[$a->customer_id] ?? collect();
                    $customer = $a->customer;
                    $totalQty = round((float) $ordersForCustomer->sum('quantity'), 2);
                    $primaryOrder = $ordersForCustomer->sortBy('id')->first();
                    $allSkipped = $ordersForCustomer->isNotEmpty()
                        && $ordersForCustomer->every(fn (DailyOrderLog $o) => $o->status === 'skipped');

                    return [
                        'assignment_id' => $a->id,
                        'sort_order'    => $a->sort_order,
                        'customer'      => $this->formatCustomerForDelivery($customer),
                        'customer_id'   => $customer->id,
                        'order'         => $primaryOrder ? [
                            'id'        => $primaryOrder->id,
                            'quantity'  => $totalQty,
                            'qty'       => $totalQty,
                            'status'    => $allSkipped ? 'skipped' : $primaryOrder->status,
                            'skipped'   => $allSkipped,
                        ] : null,
                    ];
                }
            );

            $boyAssignment = $boyAssignments[$route->id] ?? null;

            return [
                'route_id'     => $route->id,
                'route_name'   => $route->name,
                'shift'        => $route->shift,
                'sort_order'   => $route->sort_order,
                'delivery_boy' => $boyAssignment ? $this->formatBoy($boyAssignment->deliveryBoy) : null,
                'customers'    => $customers,
            ];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }

    // =========================================================================
    // S8-13 — Skip delivery (owner can skip any customer's order for a day)
    // =========================================================================

    /** POST /owner/skip-delivery */
    public function skipDelivery(Request $request): JsonResponse
    {
        /** @var FarmOwner $owner */
        $owner = $request->user();

        $validated = $request->validate([
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'date'        => ['required', 'date_format:Y-m-d'],
        ]);

        $customer = Customer::findOrFail($validated['customer_id']);
        if ($customer->farm_id !== $owner->farm_id) {
            return $this->notFound();
        }

        $order = DailyOrderLog::where('customer_id', $customer->id)
            ->whereDate('delivery_date', $validated['date'])
            ->first();

        if (! $order) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'NO_ORDER', 'message' => 'No daily order found for this customer on that date.'],
            ], 404);
        }

        $order->update(['status' => 'skipped']);

        return response()->json(['success' => true]);
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    private function formatBoy(DeliveryBoy $boy): array
    {
        return [
            'id'            => $boy->id,
            'name'          => $boy->name,
            'phone'         => $boy->phone,
            'salary_type'   => $boy->salary_type,
            'salary_amount' => $boy->salary_amount,
            'is_active'     => $boy->is_active,
            'has_pin'       => $boy->pin_hash !== null,
        ];
    }

    private function formatRoute(DeliveryRoute $route): array
    {
        return [
            'id'         => $route->id,
            'name'       => $route->name,
            'shift'      => $route->shift,
            'sort_order' => $route->sort_order,
            'is_active'  => $route->is_active,
        ];
    }

    private function formatCustomerForDelivery(Customer $customer): array
    {
        return [
            'id'      => $customer->id,
            'name'    => trim($customer->first_name . ' ' . $customer->last_name),
            'address' => trim(implode(', ', array_filter([
                $customer->address_line,
                $customer->area,
                $customer->landmark,
                $customer->city,
            ]))),
        ];
    }

    private function notFound(): JsonResponse
    {
        return response()->json(['success' => false, 'error' => ['code' => 'NOT_FOUND', 'message' => 'Resource not found.']], 404);
    }
}
