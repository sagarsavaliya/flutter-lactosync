<?php

namespace App\Http\Requests\Owner;

use Illuminate\Foundation\Http\FormRequest;

class StoreOwnerProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'milk_type_id'      => ['required', 'integer', 'exists:milk_types,id'],
            'container_type_id' => ['required', 'integer'],
            'rate'              => ['required', 'numeric', 'min:1', 'max:9999'],
        ];
    }
}
