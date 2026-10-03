<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya Owner atau HR yang dapat mengelola hak akses role pengguna.', null, 403);
        }

        $query = User::where('id_companies', $currentUser->id_companies)
            ->with(['employee.branch', 'employee.department', 'employee.jobPosition'])
            ->orderBy('id_users', 'asc');

        if ($request->filled('role')) {
            $query->where('role', $request->input('role'));
        }

        $users = $query->get();

        return $this->successResponse($users, 'Daftar pengguna dan hak akses role berhasil diambil.');
    }

    public function updateRole(Request $request, string|int $id_users): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki wewenang untuk mengubah role.', null, 403);
        }

        $targetUser = User::where('id_companies', $currentUser->id_companies)
            ->where('id_users', $id_users)
            ->first();

        if (! $targetUser) {
            return $this->errorResponse('Pengguna tidak ditemukan dalam perusahaan Anda.', null, 404);
        }

        // Prevent admin from locking themselves out
        if ($targetUser->id_users === $currentUser->id_users) {
            return $this->errorResponse('Anda tidak dapat mengubah role akun Anda sendiri demi keamanan akses.', null, 422);
        }

        $validated = $request->validate([
            'role' => ['required', 'string', Rule::in(['owner', 'hr', 'manager', 'employee'])],
        ], [
            'role.required' => 'Pilihan role wajib ditentukan.',
            'role.in' => 'Role yang dipilih tidak valid (pilihan: owner, hr, manager, employee).',
        ]);

        // Only existing owner or superadmin can grant owner role
        if ($validated['role'] === 'owner' && ! in_array($currentUser->role, ['owner', 'superadmin'])) {
            return $this->errorResponse('Hanya pemilik perusahaan (Owner) yang dapat memindahtangankan atau mengangkat role Owner.', null, 403);
        }

        $targetUser->update([
            'role' => $validated['role'],
        ]);

        $targetUser->load(['employee.branch', 'employee.department', 'employee.jobPosition']);

        return $this->successResponse($targetUser, "Role pengguna {$targetUser->name} berhasil diperbarui menjadi {$validated['role']}.");
    }

    public function toggleStatus(string|int $id_users): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki wewenang mengelola status pengguna.', null, 403);
        }

        $targetUser = User::where('id_companies', $currentUser->id_companies)
            ->where('id_users', $id_users)
            ->first();

        if (! $targetUser) {
            return $this->errorResponse('Pengguna tidak ditemukan dalam perusahaan Anda.', null, 404);
        }

        if ($targetUser->id_users === $currentUser->id_users) {
            return $this->errorResponse('Anda tidak dapat menonaktifkan akun Anda sendiri.', null, 422);
        }

        $targetUser->update([
            'is_active' => ! $targetUser->is_active,
        ]);

        $statusText = $targetUser->is_active ? 'diaktifkan' : 'dinonaktifkan';

        return $this->successResponse($targetUser, "Status akun pengguna {$targetUser->name} berhasil {$statusText}.");
    }
}
