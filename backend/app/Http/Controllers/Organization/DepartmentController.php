<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Http\Requests\Organization\StoreDepartmentRequest;
use App\Http\Requests\Organization\UpdateDepartmentRequest;
use App\Models\Department;
use Illuminate\Http\JsonResponse;

class DepartmentController extends Controller
{
    public function index(): JsonResponse
    {
        $departments = Department::all();

        return $this->successResponse($departments, 'Daftar departemen berhasil diambil.');
    }

    public function store(StoreDepartmentRequest $request): JsonResponse
    {
        $department = Department::create($request->validated());

        return $this->successResponse($department, 'Departemen berhasil dibuat.', 201);
    }

    public function show(string|int $id_departments): JsonResponse
    {
        $department = Department::find($id_departments);

        if (! $department) {
            return $this->errorResponse('Data departemen tidak ditemukan.', null, 404);
        }

        return $this->successResponse($department, 'Detail departemen berhasil diambil.');
    }

    public function update(UpdateDepartmentRequest $request, string|int $id_departments): JsonResponse
    {
        $department = Department::find($id_departments);

        if (! $department) {
            return $this->errorResponse('Data departemen tidak ditemukan.', null, 404);
        }

        $department->update($request->validated());

        return $this->successResponse($department, 'Data departemen berhasil diperbarui.');
    }

    public function destroy(string|int $id_departments): JsonResponse
    {
        $department = Department::find($id_departments);

        if (! $department) {
            return $this->errorResponse('Data departemen tidak ditemukan.', null, 404);
        }

        $department->delete();

        return $this->successResponse(null, 'Departemen berhasil dihapus.');
    }
}
