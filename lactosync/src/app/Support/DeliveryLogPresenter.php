<?php

namespace App\Support;

use App\Enums\OrderLogStatus;
use App\Models\DailyOrderLog;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

final class DeliveryLogPresenter
{
    /** @return list<OrderLogStatus> */
    public static function billableStatuses(): array
    {
        return [OrderLogStatus::Pending, OrderLogStatus::Delivered];
    }

    /**
     * Last calendar day included when viewing a billing month (today for current month, month-end for past).
     */
    public static function effectiveThroughDate(string $billingMonth, ?Carbon $reference = null): Carbon
    {
        $reference = ($reference ?? Carbon::today())->copy()->startOfDay();
        $start = Carbon::createFromFormat('Y-m', $billingMonth)->startOfMonth();

        if ($reference->format('Y-m') !== $billingMonth) {
            return $reference->lt($start)
                ? $start->copy()
                : $start->copy()->endOfMonth()->startOfDay();
        }

        return $reference;
    }

    /**
     * Billable logs from month start through the effective "today" for that billing month.
     *
     * @param  Collection<int, DailyOrderLog>  $logs
     * @return Collection<int, DailyOrderLog>
     */
    public static function logsThroughDate(
        Collection $logs,
        string $billingMonth,
        ?Carbon $reference = null,
    ): Collection {
        $through = self::effectiveThroughDate($billingMonth, $reference);

        return $logs->filter(
            fn (DailyOrderLog $log) => $log->delivery_date->copy()->startOfDay()->lte($through),
        );
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $logs
     * @return list<array{date: string, morning: ?float, evening: ?float}>
     */
    public static function dailyOrdersTable(Collection $logs): array
    {
        return $logs
            ->groupBy(fn (DailyOrderLog $log) => $log->delivery_date->toDateString())
            ->map(function (Collection $dayLogs, string $date) {
                $morning = round((float) $dayLogs
                    ->filter(fn (DailyOrderLog $l) => ($l->shift->value ?? $l->shift) === 'morning')
                    ->sum('quantity'), 2);
                $evening = round((float) $dayLogs
                    ->filter(fn (DailyOrderLog $l) => ($l->shift->value ?? $l->shift) === 'evening')
                    ->sum('quantity'), 2);

                return [
                    'date' => $date,
                    'morning' => $morning > 0 ? $morning : null,
                    'evening' => $evening > 0 ? $evening : null,
                ];
            })
            ->values()
            ->sortBy('date')
            ->values()
            ->all();
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $logs
     * @return list<array{date: string, morning: ?float, evening: ?float, has_delivery: bool}>
     */
    public static function fullMonthDailyOrdersTable(
        Collection $logs,
        string $billingMonth,
        ?Carbon $throughDate = null,
    ): array {
        $start = Carbon::createFromFormat('Y-m', $billingMonth)->startOfMonth();
        $daysInMonth = $start->daysInMonth;
        $through = $throughDate?->copy()->startOfDay() ?? Carbon::today()->startOfDay();
        if ($through->format('Y-m') !== $billingMonth) {
            $through = $through->lt($start)
                ? $start->copy()
                : $start->copy()->endOfMonth()->startOfDay();
        }
        $lastDay = min($daysInMonth, (int) $through->day);
        $byDate = collect(self::dailyOrdersTable($logs))->keyBy('date');

        $rows = [];
        for ($day = 1; $day <= $lastDay; $day++) {
            $date = $start->copy()->day($day)->toDateString();
            $existing = $byDate->get($date);
            $morning = $existing['morning'] ?? null;
            $evening = $existing['evening'] ?? null;
            $hasDelivery = ($morning ?? 0) > 0 || ($evening ?? 0) > 0;

            $rows[] = [
                'date' => $date,
                'morning' => $morning,
                'evening' => $evening,
                'has_delivery' => $hasDelivery,
            ];
        }

        return $rows;
    }

    /**
     * @param  Collection<int, DailyOrderLog>  $logs
     */
    public static function logsForSubscriptionLine(Collection $logs, object $line): Collection
    {
        $lineShift = $line->shift instanceof \BackedEnum ? $line->shift->value : (string) $line->shift;

        return $logs->filter(function (DailyOrderLog $log) use ($line, $lineShift) {
            if ($log->subscription_line_id !== null) {
                return (int) $log->subscription_line_id === (int) $line->id;
            }

            return (int) $log->product_id === (int) $line->product_id
                && ($log->shift->value ?? (string) $log->shift) === $lineShift;
        });
    }
}
