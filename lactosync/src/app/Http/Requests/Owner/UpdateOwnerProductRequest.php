<?php

namespace App\Http\Requests\Owner;

use Illuminate\Foundation\Http\FormRequest;

class UpdateOwnerProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'             => ['sometimes', 'string', 'max:120'],
            // New FK-based fields (preferred going forward)
            'milk_type_id'     => ['sometimes', 'nullable', 'integer', 'exists:milk_types,id'],
            'container_type_id'=> ['sometimes', 'nullable', 'integer', 'exists:container_types,id'],
            // Legacy string fields — kept for backward compat during transition; will be removed once old columns are dropped
            'milk_type'        => ['sometimes', 'nullable', 'string', 'max:100'],
            'container_type'   => ['sometimes', 'nullable', 'string', 'max:100'],
            'rate'             => ['sometimes', 'numeric', 'min:1', 'max:99999'],
            'unit'             => ['sometimes', 'string', 'in:ltr'],
        ];
    }
}
