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
            'name'              => ['sometimes', 'string', 'max:120'],
            'milk_type_id'      => ['sometimes', 'nullable', 'integer', 'exists:milk_types,id'],
            'container_type_id' => ['sometimes', 'nullable', 'integer', 'exists:container_types,id'],
            'rate'              => ['sometimes', 'numeric', 'min:1', 'max:99999'],
            'unit'              => ['sometimes', 'string', 'in:ltr'],
        ];
    }
}
