<?php

namespace App\Http\Requests\Onboarding;

use App\Enums\DeliveryShift;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSubscriptionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'integer'],
            'lines' => ['required', 'array', 'min:1'],
            'lines.*.product_id' => ['required', 'integer'],
            'lines.*.quantity' => ['required', 'numeric', 'min:0.25', 'max:100'],
            'lines.*.coupon_amount' => ['nullable', 'numeric', 'min:0', 'max:99999'],
            'lines.*.shift' => ['required', Rule::enum(DeliveryShift::class)],
        ];
    }
}
