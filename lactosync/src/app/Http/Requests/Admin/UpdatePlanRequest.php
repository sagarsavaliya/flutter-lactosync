<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validates the payload for PUT /api/admin/v1/plans/{id}.
 *
 * All fields are optional (PATCH semantics on a PUT endpoint —
 * only sent fields are updated). name uniqueness check ignores
 * the current plan row.
 */
class UpdatePlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // guarded at route level by auth:admin
    }

    public function rules(): array
    {
        $planId = $this->route('plan');

        return [
            'name'               => [
                'sometimes',
                'string',
                'max:100',
                Rule::unique('subscription_plans', 'name')->ignore($planId),
            ],
            'description'        => ['sometimes', 'nullable', 'string'],
            'price'              => ['sometimes', 'numeric', 'gt:0'],
            'billing_cycle'      => ['sometimes', 'string', 'in:monthly,quarterly,half_yearly,yearly'],
            'max_customers'      => ['sometimes', 'integer', 'min:1'],
            'max_subscriptions'  => ['sometimes', 'integer', 'min:1'],
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

    /**
     * Returns true if the request includes any field that is frozen
     * when the plan has active tenant assignments (FR-20).
     */
    public function hasFrozenFields(): bool
    {
        return $this->hasAny(['price', 'max_customers', 'max_subscriptions']);
    }
}
