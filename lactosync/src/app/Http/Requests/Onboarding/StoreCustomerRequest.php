<?php

namespace App\Http\Requests\Onboarding;

use Illuminate\Foundation\Http\FormRequest;

class StoreCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'first_name' => ['required', 'string', 'max:80'],
            'last_name' => ['required', 'string', 'max:80'],
            'address_line' => ['required', 'string', 'max:255'],
            'area' => ['nullable', 'string', 'max:120'],
            'landmark' => ['nullable', 'string', 'max:120'],
            'city' => ['required', 'string', 'max:80'],
            'state' => ['required', 'string', 'max:80'],
            'zip' => ['required', 'digits:6'],
            'contact' => ['required', 'digits:10'],
            'whatsapp_enabled' => ['sometimes', 'boolean'],
            'secondary_contact' => ['nullable', 'digits:10'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
