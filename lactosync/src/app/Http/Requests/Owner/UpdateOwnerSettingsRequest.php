<?php

namespace App\Http\Requests\Owner;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateOwnerSettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'farm.name' => ['sometimes', 'string', 'max:120'],
            'farm.address_line' => ['sometimes', 'string', 'max:255'],
            'farm.city' => ['sometimes', 'string', 'max:80'],
            'farm.state' => ['sometimes', 'string', 'max:80'],
            'farm.zip' => ['sometimes', 'digits:6'],
            'farm.upi_vpa' => ['sometimes', 'nullable', 'string', 'max:120'],
            'farm.upi_payee_name' => ['sometimes', 'nullable', 'string', 'max:120'],
            'farm.morning_order_time' => ['sometimes', 'date_format:H:i'],
            'farm.evening_order_time' => ['sometimes', 'date_format:H:i'],
            'farm.prefill_customer_address' => ['sometimes', 'nullable', 'boolean'],
            'owner.first_name' => ['sometimes', 'string', 'max:80'],
            'owner.last_name' => ['sometimes', 'string', 'max:80'],
            'document_settings.milk_log_format' => ['sometimes', Rule::in(['text', 'image', 'pdf'])],
            'document_settings.billing_format' => ['sometimes', Rule::in(['text', 'image', 'pdf'])],
            'document_settings.payment_receipt_format' => ['sometimes', Rule::in(['text', 'image', 'pdf'])],
            'document_settings.include_farm_header' => ['sometimes', 'boolean'],
        ];
    }
}
