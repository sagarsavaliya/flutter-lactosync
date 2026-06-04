<?php

namespace App\Http\Requests\Onboarding;

use App\Enums\ContainerType;
use App\Enums\MilkType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'milk_type' => ['required', Rule::enum(MilkType::class)],
            'rate' => ['required', 'numeric', 'min:1', 'max:99999'],
            'unit' => ['required', 'string', 'in:ltr'],
            'container_type' => ['required', Rule::enum(ContainerType::class)],
        ];
    }
}
