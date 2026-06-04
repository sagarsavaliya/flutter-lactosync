<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'owner_name' => ['required', 'string', 'max:120'],
            'farm_name' => ['required', 'string', 'max:160'],
            'mobile' => ['required', 'digits:10', 'unique:farm_owners,mobile'],
            'pin' => ['required', 'digits:4', 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'mobile.unique' => 'This mobile number is already registered.',
        ];
    }
}
