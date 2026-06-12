<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates the payload for POST /api/admin/v1/plans.
 *
 * All five plan fields are required; price and limits must be positive;
 * billing_cycle must be one of the four allowed enum values.
 */
class StorePlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // guarded at route level by auth:admin
    }

    public function rules(): array
    {
        return [
            'name'               => ['required', 'string', 'max:100', 'unique:subscription_plans,name'],
            'description'        => ['nullable', 'string'],
            'price'              => ['required', 'numeric', 'gt:0'],
            'billing_cycle'      => ['required', 'string', 'in:monthly,quarterly,half_yearly,yearly'],
            'max_customers'      => ['required', 'integer', 'min:1'],
            'max_subscriptions'  => ['required', 'integer', 'min:1'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.unique'              => 'A plan with this name already exists.',
            'price.gt'                 => 'Price must be greater than zero.',
            'billing_cycle.in'         => 'Billing cycle must be one of: monthly, quarterly, half_yearly, yearly.',
            'max_customers.min'        => 'Max customers must be at least 1.',
            'max_subscriptions.min'    => 'Max subscriptions must be at least 1.',
        ];
    }
}
