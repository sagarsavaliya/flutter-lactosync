<?php

namespace App\Services\Admin;

/**
 * Canonical multi-sheet workbook layout for tenant day-1 bootstrap imports.
 */
final class TenantBootstrapWorkbookSpec
{
    public const FILE_NAME = 'LactoSync_Tenant_Bootstrap_Template.xlsx';

    public const SHEET_README = 'README';

    public const SHEET_FARM = 'Farm Profile';

    public const SHEET_PRODUCTS = 'Products';

    public const SHEET_CUSTOMERS = 'Customers';

    public const SHEET_SUBSCRIPTIONS = 'Subscriptions';

    public const SHEET_ROUTES = 'Routes';

    public const SHEET_ROUTE_CUSTOMERS = 'Route Customers';

    public const SHEET_VALID_VALUES = 'Valid Values';

  /** @var list<string> */
    public const REQUIRED_SHEETS = [
        self::SHEET_FARM,
        self::SHEET_PRODUCTS,
        self::SHEET_CUSTOMERS,
        self::SHEET_SUBSCRIPTIONS,
        self::SHEET_ROUTES,
        self::SHEET_ROUTE_CUSTOMERS,
    ];

    /** @return list<string> */
    public static function farmHeaders(): array
    {
        return [
            'farm_name',
            'address_line',
            'city',
            'state',
            'zip',
            'gst_number',
            'prefill_customer_address',
        ];
    }

    /** @return list<string> */
    public static function productHeaders(): array
    {
        return [
            'product_name',
            'milk_type_name',
            'product_rate',
            'container_type_name',
            'available_container_sizes',
            'is_active',
        ];
    }

    /** @return array<string, list<float>> */
    public static function defaultContainerSizesByType(): array
    {
        return [
            'glass bottle' => [0.5, 1.0],
            'plastic bag' => [0.5, 1.0, 1.5, 2.0],
            'bulk container' => [4.0, 5.0, 6.0],
        ];
    }

    /** @return list<string> */
    public static function customerHeaders(): array
    {
        return [
            'customer_first_name',
            'customer_last_name',
            'customer_contact',
            'secondary_contact',
            'delivery_type',
            'whatsapp_enabled',
            'address_line',
            'area',
            'landmark',
            'city',
            'state',
            'zip',
            'is_active',
        ];
    }

    /** @return list<string> */
    public static function subscriptionHeaders(): array
    {
        return [
            'customer_contact',
            'product_name',
            'shift',
            'quantity_ltr',
            'coupon_amount',
        ];
    }

    /** @return list<string> */
    public static function routeHeaders(): array
    {
        return [
            'route_name',
            'shift',
            'sort_order',
            'is_active',
        ];
    }

    /** @return list<string> */
    public static function routeCustomerHeaders(): array
    {
        return [
            'route_name',
            'shift',
            'customer_contact',
            'sort_order',
        ];
    }
}
