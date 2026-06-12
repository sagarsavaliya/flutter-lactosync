<?php

namespace App\Http\Requests\Owner;

use Illuminate\Foundation\Http\FormRequest;

class StoreContainerTypeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'    => ['required', 'string', 'max:100'],
            'sizes'   => ['required', 'array', 'min:1'],
            'sizes.*' => ['required', 'numeric', 'min:0.5', 'max:20'],
        ];
    }
}
