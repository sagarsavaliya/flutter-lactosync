<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class SignupCompleteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'signup_token' => ['required', 'string', 'size:64'],
            'pin' => ['required', 'digits:4', 'confirmed'],
        ];
    }
}
