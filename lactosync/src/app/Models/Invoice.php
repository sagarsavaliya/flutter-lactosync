<?php

namespace App\Models;

use App\Enums\InvoiceStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Invoice extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'farm_id',
        'customer_id',
        'billing_month',
        'invoice_number',
        'subtotal',
        'discount_total',
        'total_amount',
        'amount_paid',
        'balance_due',
        'status',
        'issued_at',
        'due_date',
        'sent_at',
        'sent_via',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'decimal:2',
            'discount_total' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'amount_paid' => 'decimal:2',
            'balance_due' => 'decimal:2',
            'status' => InvoiceStatus::class,
            'issued_at' => 'datetime',
            'due_date' => 'date',
            'sent_at' => 'datetime',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(InvoiceLine::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function refreshPaymentTotals(): void
    {
        $paid = (float) $this->payments()
            ->whereIn('payment_type', ['receipt', 'jama'])
            ->sum('amount');

        $balance = round((float) $this->total_amount - $paid, 2);

        $status = match (true) {
            $balance <= 0 => InvoiceStatus::Paid,
            $paid > 0 => InvoiceStatus::Partial,
            default => $this->status === InvoiceStatus::Draft ? InvoiceStatus::Draft : InvoiceStatus::Issued,
        };

        $this->update([
            'amount_paid' => $paid,
            'balance_due' => max(0, $balance),
            'status' => $status,
        ]);
    }
}
