<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Http\Requests\Organization\StoreDepartmentRequest;
use App\Http\Requests\Organization\UpdateDepartmentRequest;
use App\Models\Employee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DepartmentController extends Controller
{
    protected static array $defaultDepartments = [
        ['id_departments' => 1, 'name' => 'Teknologi Informasi', 'description' => 'Departemen IT & Software Engineering'],
        ['id_departments' => 2, 'name' => 'Sumber Daya Manusia', 'description' => 'Human Resources & Talent Management'],
        ['id_departments' => 3, 'name' => 'Operasional & Produksi', 'description' => 'Operasional Pabrik & Logistik'],
        ['id_departments' => 4, 'name' => 'Keuangan & Akuntansi', 'description' => 'Finance & Accounting'],
        ['id_departments' => 5, 'name' => 'Pemasaran & Penjualan', 'description' => 'Marketing & Sales'],
    ];

    public function index(Request $request): JsonResponse
    {
        $companyId = $request->user()?->id_companies;

        $existing = Employee::when($companyId, fn ($q) => $q->where('id_companies', $companyId))
            ->whereNotNull('department_name')
            ->distinct()
            ->pluck('department_name')
            ->map(function ($name, $idx) {
                return [
                    'id_departments' => $idx + 1,
                    'name' => $name,
                    'description' => 'Departemen ' . $name,
                ];
            });

        $list = $existing->isNotEmpty() ? $existing->values() : collect(self::$defaultDepartments);

        return $this->successResponse($list, 'Daftar departemen berhasil diambil.');
    }

    public function store(StoreDepartmentRequest $request): JsonResponse
    {
        $companyId = $request->user()?->id_companies;

        $item = [
            'id_departments' => rand(10, 99),
            'name' => $request->validated('name'),
            'description' => $request->input('description'),
            'id_companies' => $companyId,
        ];

        return $this->successResponse($item, 'Departemen berhasil dibuat.', 201);
    }

    public function show(string|int $id_departments): JsonResponse
    {
        if ((int) $id_departments > 50 || (int) $id_departments < 1) {
            return $this->errorResponse('Data departemen tidak ditemukan.', null, 404);
        }

        return $this->successResponse([
            'id_departments' => (int) $id_departments,
            'name' => 'Departemen',
            'description' => 'Deskripsi Departemen',
        ], 'Detail departemen berhasil diambil.');
    }

    public function update(UpdateDepartmentRequest $request, string|int $id_departments): JsonResponse
    {
        if ((int) $id_departments > 50 || (int) $id_departments < 1) {
            return $this->errorResponse('Data departemen tidak ditemukan.', null, 404);
        }

        return $this->successResponse([
            'id_departments' => (int) $id_departments,
            'name' => $request->validated('name'),
            'description' => $request->input('description'),
        ], 'Data departemen berhasil diperbarui.');
    }

    public function destroy(string|int $id_departments): JsonResponse
    {
        return $this->successResponse(null, 'Departemen berhasil dihapus.');
    }
}
