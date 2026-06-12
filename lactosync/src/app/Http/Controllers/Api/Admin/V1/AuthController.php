<?php

namespace App\Http\Controllers\Api\Admin\V1;

use App\Http\Controllers\Controller;
use App\Models\Admin\AdminUser;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Handles admin authentication: login (email + 6-digit PIN) and logout.
 * All responses deliberately omit the PIN — it is never echoed back.
 */
class AuthController extends Controller
{
    /**
     * POST /api/admin/v1/auth/login
     *
     * Validates credentials, enforces the 5-attempt lockout, and issues a
     * Sanctum token scoped to the 'admin' ability on success.
     *
     * Response codes:
     *   200 — authenticated; body contains token + admin email
     *   401 — wrong email or wrong PIN
     *   403 — account is deactivated
     *   423 — account locked; body contains retry_after (seconds remaining)
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'pin'   => ['required', 'string', 'size:6'],
        ]);

        $admin = AdminUser::where('email', $request->email)->first();

        if ($admin === null) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'INVALID_CREDENTIALS', 'message' => 'Invalid email or PIN.'],
            ], 401);
        }

        if (! $admin->is_active) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'ACCOUNT_DISABLED', 'message' => 'This account has been deactivated.'],
            ], 403);
        }

        if ($admin->isLocked()) {
            $retryAfter = (int) now()->diffInSeconds($admin->locked_until);

            return response()->json([
                'success' => false,
                'error'   => [
                    'code'        => 'ACCOUNT_LOCKED',
                    'message'     => 'Too many failed attempts. Account is temporarily locked.',
                    'retry_after' => $retryAfter,
                ],
            ], 423);
        }

        if (! $admin->verifyPin($request->pin)) {
            $admin->recordFailedAttempt();

            // Re-check in case this attempt triggered the lockout.
            if ($admin->isLocked()) {
                return response()->json([
                    'success' => false,
                    'error'   => [
                        'code'        => 'ACCOUNT_LOCKED',
                        'message'     => 'Too many failed attempts. Account is locked for 15 minutes.',
                        'retry_after' => 15 * 60,
                    ],
                ], 423);
            }

            return response()->json([
                'success' => false,
                'error'   => ['code' => 'INVALID_CREDENTIALS', 'message' => 'Invalid email or PIN.'],
            ], 401);
        }

        // Successful login — clear lockout state and record timestamp.
        $admin->clearLockout();
        $admin->update(['last_login_at' => now()]);

        $token = $admin->createToken('admin-session', ['admin'])->plainTextToken;

        return response()->json([
            'success' => true,
            'data'    => [
                'token'      => $token,
                'token_type' => 'Bearer',
                'email'      => $admin->email,
                'name'       => $admin->name,
            ],
        ], 200);
    }

    /**
     * POST /api/admin/v1/auth/logout
     *
     * Revokes the current Sanctum token server-side.
     * Requires auth:admin middleware on the route.
     */
    public function logout(Request $request): JsonResponse
    {
        // currentAccessToken() is always non-null when auth:admin passes.
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out.',
        ], 200);
    }
}
