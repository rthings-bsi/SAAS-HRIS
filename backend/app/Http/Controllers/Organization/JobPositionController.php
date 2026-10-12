<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Http\Requests\Organization\StoreJobPositionRequest;
use App\Http\Requests\Organization\UpdateJobPositionRequest;
use App\Models\Employee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JobPositionController extends Controller
{
    protected static array $defaultPositions = [
        ['id_job_positions' => 1, 'name' => 'Direktur Utama', 'level' => 'director'],
        ['id_job_positions' => 2, 'name' => 'Manajer HRD', 'level' => 'manager'],
        ['id_job_positions' => 3, 'name' => 'Software Engineer', 'level' => 'staff'],
        ['id_job_positions' => 4, 'name' => 'Staff Administrasi', 'level' => 'staff'],
        ['id_job_positions' => 5, 'name' => 'Operator Mesin', 'level' => 'staff'],
    ];

    public function index(Request $request): JsonResponse
    {
        $companyId = $request->user()?->id_companies;

        $existing = Employee::when($companyId, fn ($q) => $q->where('id_companies', $companyId))
            ->whereNotNull('job_position_name')
            ->distinct()
            ->pluck('job_position_name')
            ->map(function ($name, $idx) {
                return [
                    'id_job_positions' => $idx + 1,
                    'name' => $name,
                    'level' => 'staff',
                ];
            });

        $list = $existing->isNotEmpty() ? $existing->values() : collect(self::$defaultPositions);

        return $this->successResponse($list, 'Daftar posisi jabatan berhasil diambil.');
    }

    public function store(StoreJobPositionRequest $request): JsonResponse
    {
        $companyId = $request->user()?->id_companies;

        $item = [
            'id_job_positions' => rand(10, 99),
            'name' => $request->validated('name'),
            'level' => $request->input('level', 'staff'),
            'id_companies' => $companyId,
        ];

        return $this->successResponse($item, 'Posisi jabatan berhasil dibuat.', 201);
    }

    public function show(string|int $id_job_positions): JsonResponse
    {
        if ((int) $id_job_positions > 50 || (int) $id_job_positions < 1) {
            return $this->errorResponse('Data posisi jabatan tidak ditemukan.', null, 404);
        }

        return $this->successResponse([
            'id_job_positions' => (int) $id_job_positions,
            'name' => 'Jabatan',
            'level' => 'staff',
        ], 'Detail posisi jabatan berhasil diambil.');
    }

    public function update(UpdateJobPositionRequest $request, string|int $id_job_positions): JsonResponse
    {
        if ((int) $id_job_positions > 50 || (int) $id_job_positions < 1) {
            return $this->errorResponse('Data posisi jabatan tidak ditemukan.', null, 404);
        }

        return $this->successResponse([
            'id_job_positions' => (int) $id_job_positions,
            'name' => $request->validated('name'),
            'level' => $request->input('level', 'staff'),
        ], 'Data posisi jabatan berhasil diperbarui.');
    }

    public function destroy(string|int $id_job_positions): JsonResponse
    {
        return $this->successResponse(null, 'Posisi jabatan berhasil dihapus.');
    }
}
