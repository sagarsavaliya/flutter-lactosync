<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class ResetPinRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'mobile' => ['required', 'digits:10'],
            'reset_token' => ['required', 'string', 'size:64'],
            'pin' => ['required', 'digits:4', 'confirmed'],
        ];
    }
}
