<?php

namespace App\Http\Requests\Onboarding;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $isWalkIn = $this->input('delivery_type') === 'walk_in';

        return [
            'first_name' => ['required', 'string', 'max:80'],
            'last_name' => ['required', 'string', 'max:80'],
            'delivery_type' => ['sometimes', 'string', Rule::in(['home_delivery', 'walk_in'])],
            'address_line' => [$isWalkIn ? 'nullable' : 'required', 'string', 'max:255'],
            'area' => ['nullable', 'string', 'max:120'],
            'landmark' => ['nullable', 'string', 'max:120'],
            'city' => [$isWalkIn ? 'nullable' : 'required', 'string', 'max:80'],
            'state' => [$isWalkIn ? 'nullable' : 'required', 'string', 'max:80'],
            'zip' => [$isWalkIn ? 'nullable' : 'required', 'digits:6'],
            'contact' => ['required', 'digits:10'],
            'whatsapp_enabled' => ['sometimes', 'boolean'],
            'secondary_contact' => ['nullable', 'digits:10'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
