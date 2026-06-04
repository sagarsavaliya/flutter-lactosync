<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class VerifyOtpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $otpLength = config('lactosync.otp.length');

        return [
            'mobile' => ['required', 'digits:10'],
            'otp' => ['required', 'digits:'.$otpLength],
        ];
    }
}
