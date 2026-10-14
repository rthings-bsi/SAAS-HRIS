<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Company;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    protected function getCompany(?User $currentUser): ?Company
    {
        return $currentUser?->company ?? Company::first();
    }

    public function index(Request $request): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya Owner atau HR yang dapat mengelola hak akses role pengguna.', null, 403);
        }

        $company = $this->getCompany($currentUser);
        $companyId = $currentUser?->id_companies ?? $company?->id_companies ?? 1;

        $query = User::where('id_companies', $companyId)
            ->with(['employee'])
            ->orderBy('id_users', 'asc');

        if ($request->filled('role')) {
            $query->where('role', $request->input('role'));
        }

        $users = $query->get();

        return $this->successResponse($users, 'Daftar pengguna dan hak akses role berhasil diambil.');
    }

    public function getRoles(): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya Owner atau HR yang dapat mengelola hak akses role pengguna.', null, 403);
        }

        $company = $this->getCompany($currentUser);
        if (! $company) {
            return $this->errorResponse('Data perusahaan belum terdaftar di sistem.', null, 404);
        }

        $roles = $company->getRoleConfigurations();

        // Calculate active user count per role
        $counts = User::where('id_companies', $company->id_companies)
            ->selectRaw('role, count(*) as count')
            ->groupBy('role')
            ->pluck('count', 'role')
            ->toArray();

        foreach ($roles as &$role) {
            $role['user_count'] = $counts[$role['key']] ?? 0;
            if ($role['key'] === 'superadmin') {
                $role['user_count'] += ($counts['owner'] ?? 0);
            }
        }

        $availablePermissions = Company::getAvailablePermissions();

        return $this->successResponse([
            'roles' => $roles,
            'available_permissions' => $availablePermissions,
        ], 'Konfigurasi role dan daftar hak akses berhasil dimuat.');
    }

    public function storeRole(Request $request): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki wewenang untuk menambah role baru.', null, 403);
        }

        $company = $this->getCompany($currentUser);
        if (! $company) {
            return $this->errorResponse('Data perusahaan belum terdaftar di sistem.', null, 404);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:50'],
            'key' => ['nullable', 'string', 'max:50', 'regex:/^[a-z0-9_\-]+$/i'],
            'description' => ['nullable', 'string', 'max:255'],
            'badgeClass' => ['nullable', 'string', 'max:150'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['string'],
        ], [
            'name.required' => 'Nama role wajib diisi.',
            'name.max' => 'Nama role maksimal 50 karakter.',
            'key.regex' => 'Kode unik role hanya boleh terdiri dari huruf, angka, tanda strip atau garis bawah.',
        ]);

        $key = !empty($validated['key'])
            ? strtolower(trim($validated['key']))
            : Str::slug($validated['name'], '_');

        $currentRoles = $company->getRoleConfigurations();
        foreach ($currentRoles as $role) {
            if ($role['key'] === $key) {
                return $this->errorResponse("Role dengan kode '{$key}' sudah ada. Gunakan kode atau nama role lain.", null, 422);
            }
        }

        $newRole = [
            'key' => $key,
            'label' => $validated['name'],
            'description' => $validated['description'] ?? '',
            'badgeClass' => $validated['badgeClass'] ?? 'bg-blue-50 text-blue-700 border-blue-200/80',
            'is_system' => false,
            'permissions' => $validated['permissions'] ?? [],
        ];

        $currentRoles[] = $newRole;
        $company->update(['role_configurations' => $currentRoles]);

        $newRole['user_count'] = 0;

        return $this->successResponse($newRole, "Role baru '{$newRole['label']}' berhasil ditambahkan.");
    }

    public function updateRoleConfig(Request $request, string $key): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki wewenang untuk mengonfigurasi role.', null, 403);
        }

        $company = $this->getCompany($currentUser);
        if (! $company) {
            return $this->errorResponse('Data perusahaan belum terdaftar di sistem.', null, 404);
        }

        $validated = $request->validate([
            'label' => ['required', 'string', 'max:50'],
            'description' => ['nullable', 'string', 'max:255'],
            'badgeClass' => ['nullable', 'string', 'max:150'],
            'permissions' => ['required', 'array'],
            'permissions.*' => ['string'],
        ], [
            'label.required' => 'Label nama role wajib diisi.',
            'permissions.required' => 'Daftar hak akses wewenang wajib disertakan.',
        ]);

        $roles = $company->getRoleConfigurations();
        $foundIndex = -1;
        foreach ($roles as $idx => $role) {
            if ($role['key'] === $key) {
                $foundIndex = $idx;
                break;
            }
        }

        if ($foundIndex === -1) {
            return $this->errorResponse("Role dengan kode '{$key}' tidak ditemukan.", null, 404);
        }

        $target = $roles[$foundIndex];
        $isSystem = $target['is_system'] ?? in_array($key, ['owner', 'hr', 'manager', 'employee', 'superadmin']);

        $roles[$foundIndex] = [
            'key' => $key,
            'label' => $validated['label'],
            'description' => $validated['description'] ?? ($target['description'] ?? ''),
            'badgeClass' => $validated['badgeClass'] ?? ($target['badgeClass'] ?? 'bg-blue-50 text-blue-700 border-blue-200/80'),
            'is_system' => $isSystem,
            'permissions' => array_values(array_unique($validated['permissions'])),
        ];

        $company->update(['role_configurations' => $roles]);

        return $this->successResponse($roles[$foundIndex], "Konfigurasi role '{$validated['label']}' berhasil disimpan.");
    }

    public function destroyRole(string $key): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki wewenang menghapus role.', null, 403);
        }

        if (in_array($key, ['owner', 'hr', 'manager', 'employee', 'superadmin'])) {
            return $this->errorResponse('Role bawaan sistem tidak dapat dihapus demi keamanan operasional aplikasi.', null, 422);
        }

        $company = $this->getCompany($currentUser);
        if (! $company) {
            return $this->errorResponse('Data perusahaan belum terdaftar di sistem.', null, 404);
        }

        // Check if any users currently have this role
        $assignedCount = User::where('id_companies', $company->id_companies)
            ->where('role', $key)
            ->count();

        if ($assignedCount > 0) {
            return $this->errorResponse("Role '{$key}' masih digunakan oleh {$assignedCount} akun pengguna. Pindahkan pengguna ke role lain sebelum menghapus role ini.", null, 422);
        }

        $roles = $company->getRoleConfigurations();
        $filtered = array_values(array_filter($roles, fn($r) => $r['key'] !== $key));

        $company->update(['role_configurations' => $filtered]);

        return $this->successResponse(null, "Role kustom '{$key}' berhasil dihapus.");
    }

    public function resetRoles(): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['superadmin', 'owner'])) {
            return $this->errorResponse('Hanya Super Admin yang dapat mereset konfigurasi role ke bawaan standar sistem.', null, 403);
        }

        $company = $this->getCompany($currentUser);
        if (! $company) {
            return $this->errorResponse('Data perusahaan belum terdaftar di sistem.', null, 404);
        }

        $company->update(['role_configurations' => null]);

        return $this->successResponse($company->getRoleConfigurations(), 'Seluruh konfigurasi role berhasil direset ke pengaturan awal sistem.');
    }

    public function updateRole(Request $request, string|int $id_users): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki wewenang untuk mengubah role.', null, 403);
        }

        $company = $this->getCompany($currentUser);
        $companyId = $currentUser?->id_companies ?? $company?->id_companies ?? 1;

        $targetUser = User::where('id_companies', $companyId)
            ->where('id_users', $id_users)
            ->first();

        if (! $targetUser) {
            return $this->errorResponse('Pengguna tidak ditemukan dalam perusahaan Anda.', null, 404);
        }

        // Prevent admin from locking themselves out
        if ($targetUser->id_users === $currentUser->id_users) {
            return $this->errorResponse('Anda tidak dapat mengubah role akun Anda sendiri demi keamanan akses.', null, 422);
        }

        $allowedRoles = $company ? $company->getRoleKeys() : ['superadmin', 'owner', 'hr', 'manager', 'employee'];

        $validated = $request->validate([
            'role' => ['required', 'string', Rule::in($allowedRoles)],
        ], [
            'role.required' => 'Pilihan role wajib ditentukan.',
            'role.in' => 'Role yang dipilih tidak valid untuk organisasi ini.',
        ]);

        // Only existing superadmin or owner can grant superadmin or owner role
        if (in_array($validated['role'], ['superadmin', 'owner']) && ! in_array($currentUser->role, ['superadmin', 'owner'])) {
            return $this->errorResponse('Hanya Super Admin yang dapat mengangkat atau memindahtangankan role Super Admin.', null, 403);
        }

        $targetUser->update([
            'role' => $validated['role'],
        ]);

        $targetUser->load(['employee']);

        return $this->successResponse($targetUser, "Role pengguna {$targetUser->name} berhasil diperbarui menjadi {$validated['role']}.");
    }

    public function toggleStatus(string|int $id_users): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! in_array($currentUser?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki wewenang mengelola status pengguna.', null, 403);
        }

        $company = $this->getCompany($currentUser);
        $companyId = $currentUser?->id_companies ?? $company?->id_companies ?? 1;

        $targetUser = User::where('id_companies', $companyId)
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
