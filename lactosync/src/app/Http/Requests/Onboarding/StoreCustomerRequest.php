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

    protected function prepareForValidation(): void
    {
        if ($this->input('delivery_type') !== 'walk_in') {
            return;
        }

        // Walk-in customers omit address fields in the app; DB columns are NOT NULL.
        $this->merge([
            'address_line' => filled($this->input('address_line'))
                ? $this->input('address_line')
                : 'Walk-in customer',
            'city' => filled($this->input('city')) ? $this->input('city') : 'Walk-in',
            'state' => filled($this->input('state')) ? $this->input('state') : 'NA',
            'zip' => filled($this->input('zip')) ? $this->input('zip') : '000000',
        ]);
    }

    public function rules(): array
    {
        $isWalkIn = $this->input('delivery_type') === 'walk_in';
        $farmId = $this->user()?->farm_id;

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
            'contact' => [
                'required',
                'digits:10',
                Rule::unique('customers', 'contact')
                    ->where(fn ($query) => $query
                        ->where('farm_id', $farmId)
                        ->whereNull('deleted_at')),
            ],
            'whatsapp_enabled' => ['sometimes', 'boolean'],
            'secondary_contact' => ['nullable', 'digits:10'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'contact.unique' => 'A customer with this mobile number already exists on your farm.',
        ];
    }
}
