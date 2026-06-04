<?php

return [
    'otp' => [
        'length' => (int) env('LACTOSYNC_OTP_LENGTH', 6),
        'ttl_seconds' => (int) env('LACTOSYNC_OTP_TTL', 600),
        'max_sends_per_hour' => (int) env('LACTOSYNC_OTP_MAX_SENDS', 3),
        'max_verify_attempts' => (int) env('LACTOSYNC_OTP_MAX_ATTEMPTS', 5),
        'reset_token_ttl_seconds' => (int) env('LACTOSYNC_RESET_TOKEN_TTL', 900),
    ],
    'schedule' => [
        'timezone' => env('LACTOSYNC_SCHEDULE_TIMEZONE', 'Asia/Kolkata'),
    ],
];
