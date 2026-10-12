<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return $this->errorResponse('Email atau password salah.', null, 401);
        }

        if (! $user->is_active) {
            return $this->errorResponse('Akun Anda tidak aktif.', null, 403);
        }

        $user->load([
            'company',
            'employee.branch',
            'employee.department',
            'employee.jobPosition',
        ]);
        $token = $user->createToken('access_token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user,
        ], 'Login berhasil.');
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->successResponse(null, 'Logout berhasil.');
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load([
            'company',
            'employee.branch',
            'employee.department',
            'employee.jobPosition',
        ]);

        return $this->successResponse($user, 'Profil berhasil diambil.');
    }
}
