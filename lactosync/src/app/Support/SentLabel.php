<?php

namespace App\Support;

use Illuminate\Support\Carbon;

abstract class SentLabel
{
    public static function format(?Carbon $sentAt): ?string
    {
        if ($sentAt === null) {
            return null;
        }

        $sentAt = $sentAt->copy()->startOfDay();
        $today = now()->startOfDay();
        $days = (int) $sentAt->diffInDays($today, false);

        if ($days === 0) {
            return 'Sent today';
        }

        if ($days === 1) {
            return 'Sent yesterday';
        }

        if ($days > 1 && $days < 7) {
            return "Sent {$days} days ago";
        }

        return 'Sent on '.$sentAt->format('jS M');
    }
}
