<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Http\Requests\SuperAdmin\UpdateCompanyRequest;
use App\Models\Company;
use App\Models\Employee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CompanyController extends Controller
{
    /**
     * Pastikan hanya superadmin yang dapat mengakses.
     */
    private function checkSuperAdmin(Request $request): ?JsonResponse
    {
        if ($request->user()?->role !== 'superadmin') {
            return $this->errorResponse('Akses ditolak. Hanya Superadmin platform yang diizinkan.', null, 403);
        }

        return null;
    }

    /**
     * Statistik platform SaaS HRIS untuk Superadmin.
     */
    public function stats(Request $request): JsonResponse
    {
        if ($denied = $this->checkSuperAdmin($request)) {
            return $denied;
        }

        $totalCompanies = Company::count();
        $activeCompanies = Company::where('subscription_status', 'active')->count();
        $trialCompanies = Company::where('subscription_status', 'trial')->count();
        $suspendedCompanies = Company::where('subscription_status', 'suspended')->count();
        $totalEmployees = Employee::count();

        return $this->successResponse([
            'total_companies' => $totalCompanies,
            'active_companies' => $activeCompanies,
            'trial_companies' => $trialCompanies,
            'suspended_companies' => $suspendedCompanies,
            'total_employees' => $totalEmployees,
        ], 'Statistik platform berhasil diambil.');
    }

    /**
     * Daftar seluruh tenant perusahaan (perusahaan klien).
     */
    public function index(Request $request): JsonResponse
    {
        if ($denied = $this->checkSuperAdmin($request)) {
            return $denied;
        }

        $query = Company::withCount(['users', 'employees', 'branches']);

        if ($request->filled('status')) {
            $query->where('subscription_status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('slug', 'like', "%{$search}%");
            });
        }

        $companies = $query->orderBy('id_companies', 'desc')->paginate(15);

        return $this->successResponse($companies, 'Daftar perusahaan berhasil dimuat.');
    }

    /**
     * Rincian data satu tenant perusahaan.
     */
    public function show(Request $request, int $id_companies): JsonResponse
    {
        if ($denied = $this->checkSuperAdmin($request)) {
            return $denied;
        }

        $company = Company::withCount(['users', 'employees', 'branches', 'departments', 'jobPositions'])
            ->with(['users' => function ($q) {
                $q->whereIn('role', ['owner', 'hr']);
            }])
            ->find($id_companies);

        if (! $company) {
            return $this->errorResponse('Perusahaan tidak ditemukan.', null, 404);
        }

        return $this->successResponse($company, 'Detail perusahaan berhasil dimuat.');
    }

    /**
     * Ubah data dan status langganan tenant perusahaan.
     */
    public function update(UpdateCompanyRequest $request, int $id_companies): JsonResponse
    {
        if ($denied = $this->checkSuperAdmin($request)) {
            return $denied;
        }

        $company = Company::find($id_companies);

        if (! $company) {
            return $this->errorResponse('Perusahaan tidak ditemukan.', null, 404);
        }

        $company->update($request->validated());

        return $this->successResponse($company, 'Data perusahaan berhasil diperbarui.');
    }

    /**
     * Hapus tenant perusahaan beserta seluruh relasi data (cascade).
     */
    public function destroy(Request $request, int $id_companies): JsonResponse
    {
        if ($denied = $this->checkSuperAdmin($request)) {
            return $denied;
        }

        $company = Company::find($id_companies);

        if (! $company) {
            return $this->errorResponse('Perusahaan tidak ditemukan.', null, 404);
        }

        $companyName = $company->name;
        $company->delete();

        return $this->successResponse(null, "Perusahaan {$companyName} berhasil dihapus.");
    }
}
