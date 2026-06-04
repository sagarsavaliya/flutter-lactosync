<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'mobile' => ['required', 'digits:10'],
            'pin' => ['required', 'digits:4'],
        ];
    }

    public function messages(): array
    {
        return [
            'mobile.required' => 'Enter your mobile number.',
            'mobile.digits' => 'Enter a valid 10-digit mobile number.',
            'pin.required' => 'Enter your PIN.',
            'pin.digits' => 'PIN must be 4 digits.',
        ];
    }
}
