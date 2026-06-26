<?php

namespace App\Services\WhatsApp;

use App\Models\Customer;
use App\Models\Farm;
use App\Models\FarmOwner;
use App\Models\SubscriptionLine;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Sends approved WhatsApp template notifications to farm owners when customers
 * change orders, vacation, or profile from the customer app.
 */
class OwnerWhatsAppNotifier
{
    private const LANG = 'en';

    public function __construct(private readonly WhatsAppService $whatsApp) {}

    public function vacationSet(
        FarmOwner $owner,
        Customer $customer,
        string $vacationStart,
        string $vacationEnd,
        Farm $farm,
    ): void {
        $resumeDate = Carbon::parse($vacationEnd)->addDay();
        $template = config('services.whatsapp.template_owner_vacation_set', 'lacto_sync_owner_vacation_set');

        $this->fire(
            $farm,
            $customer,
            $owner->mobile,
            $template,
            [
                $customer->fullName(),
                Carbon::parse($vacationStart)->format('d M Y'),
                $resumeDate->format('d M Y'),
                $farm->name,
            ],
            'owner_vacation_set',
            'Customer vacation set',
        );
    }

    public function vacationCleared(FarmOwner $owner, Customer $customer, Farm $farm): void
    {
        $template = config('services.whatsapp.template_owner_vacation_cleared', 'lacto_sync_owner_vacation_cleared');

        $this->fire(
            $farm,
            $customer,
            $owner->mobile,
            $template,
            [
                $customer->fullName(),
                $customer->shortAddress(),
                $farm->name,
            ],
            'owner_vacation_cleared',
            'Customer vacation cleared',
        );
    }

    public function qtyChanged(
        FarmOwner $owner,
        Customer $customer,
        string $deliveryDate,
        SubscriptionLine $line,
        int $qty,
        Farm $farm,
    ): void {
        $productName = $line->product?->name ?? 'Milk';
        $rate = number_format((float) ($line->effective_rate ?? $line->unit_rate), 0);
        $productLabel = "{$productName} - ₹{$rate}/L";
        $template = config('services.whatsapp.template_owner_qty_change', 'lacto_sync_owner_qty_change');

        $this->fire(
            $farm,
            $customer,
            $owner->mobile,
            $template,
            [
                $customer->fullName(),
                Carbon::parse($deliveryDate)->format('d M Y'),
                $productLabel,
                $this->qtyLabel((float) $line->quantity),
                $this->qtyLabel((float) $qty),
                $farm->name,
            ],
            'owner_qty_change',
            'Customer qty change',
        );
    }

    public function daySkipped(
        FarmOwner $owner,
        Customer $customer,
        string $deliveryDate,
        Farm $farm,
    ): void {
        $template = config('services.whatsapp.template_owner_day_skipped', 'lacto_sync_owner_day_skipped');

        $this->fire(
            $farm,
            $customer,
            $owner->mobile,
            $template,
            [
                $customer->fullName(),
                $customer->shortAddress(),
                Carbon::parse($deliveryDate)->format('d M Y'),
                $farm->name,
            ],
            'owner_day_skipped',
            'Customer skipped day',
        );
    }

    public function addressUpdated(
        FarmOwner $owner,
        Customer $customer,
        string $addressSummary,
        Farm $farm,
    ): void {
        $template = config('services.whatsapp.template_owner_address_updated', 'lacto_sync_owner_address_updated');

        $this->fire(
            $farm,
            $customer,
            $owner->mobile,
            $template,
            [
                $customer->fullName(),
                $addressSummary,
                $farm->name,
            ],
            'owner_address_updated',
            'Customer address updated',
        );
    }

    /** @param list<string> $params */
    private function fire(
        Farm $farm,
        ?Customer $customer,
        string $mobile,
        string $template,
        array $params,
        string $messageType,
        ?string $preview = null,
    ): void {
        if ($mobile === '') {
            return;
        }

        $context = new WhatsAppLogContext(
            $farm->id,
            $customer?->id,
            $messageType,
            $template,
            $preview,
        );

        try {
            $this->whatsApp->sendTemplate($mobile, $template, $params, self::LANG, $context);
        } catch (RuntimeException $e) {
            Log::warning("WhatsApp owner {$messageType} notification failed", [
                'mobile'   => $mobile,
                'template' => $template,
                'error'    => $e->getMessage(),
            ]);
        }
    }

    private function qtyLabel(float $qty): string
    {
        if ($qty <= 0) {
            return '0';
        }

        return abs($qty - round($qty)) < 0.001
            ? (string) (int) round($qty)
            : rtrim(rtrim(number_format($qty, 1, '.', ''), '0'), '.');
    }
}
