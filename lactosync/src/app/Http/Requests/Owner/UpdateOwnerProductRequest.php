<?php

namespace App\Http\Requests\Owner;

use App\Enums\ContainerType;
use App\Enums\MilkType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateOwnerProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:120'],
            'milk_type' => ['sometimes', Rule::enum(MilkType::class)],
            'rate' => ['sometimes', 'numeric', 'min:1', 'max:99999'],
            'unit' => ['sometimes', 'string', 'in:ltr'],
            'container_type' => ['sometimes', Rule::enum(ContainerType::class)],
        ];
    }
}
