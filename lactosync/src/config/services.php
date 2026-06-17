<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'whatsapp' => [
        'token'          => env('WHATSAPP_ACCESS_TOKEN'),
        'phone_number_id'=> env('WHATSAPP_PHONE_NUMBER_ID'),

        // Template names — override in .env if your Meta account uses different names
        'template_otp'               => env('WHATSAPP_TEMPLATE_OTP',               'lacto_sync_otp'),
        'template_bill'              => env('WHATSAPP_TEMPLATE_BILL',              'lacto_sync_monthly_bill'),
        'template_order_log'         => env('WHATSAPP_TEMPLATE_ORDER_LOG',         'lacto_sync_order_log'),
        'template_payment_confirmed' => env('WHATSAPP_TEMPLATE_PAYMENT_CONFIRMED', 'lacto_sync_payment_receipt'),
        'template_delivery_paused'   => env('WHATSAPP_TEMPLATE_DELIVERY_PAUSED',   'lacto_sync_vacation_set'),
        'template_qty_change'        => env('WHATSAPP_TEMPLATE_QTY_CHANGE',        'lacto_sync_subscription_updated'),
        'template_sub_resumed'       => env('WHATSAPP_TEMPLATE_SUB_RESUMED',       'lacto_sync_vacation_ended'),

        'template_owner_vacation_set'     => env('WHATSAPP_TEMPLATE_OWNER_VACATION_SET',     'lacto_sync_owner_vacation_set'),
        'template_owner_vacation_cleared' => env('WHATSAPP_TEMPLATE_OWNER_VACATION_CLEARED', 'lacto_sync_owner_vacation_cleared'),
        'template_owner_qty_change'       => env('WHATSAPP_TEMPLATE_OWNER_QTY_CHANGE',       'lacto_sync_owner_qty_change'),
        'template_owner_day_skipped'      => env('WHATSAPP_TEMPLATE_OWNER_DAY_SKIPPED',      'lacto_sync_owner_day_skipped'),
        'template_owner_address_updated'  => env('WHATSAPP_TEMPLATE_OWNER_ADDRESS_UPDATED',  'lacto_sync_owner_address_updated'),

        'template_language'  => env('WHATSAPP_TEMPLATE_LANGUAGE', 'en'),
        'graph_version'      => env('WHATSAPP_GRAPH_VERSION', 'v21.0'),
        'otp_button_type'    => env('WHATSAPP_OTP_BUTTON_TYPE', 'url'),
        'simulate_documents' => env('WHATSAPP_SIMULATE_DOCUMENTS', env('APP_ENV') === 'local'),
    ],

];
