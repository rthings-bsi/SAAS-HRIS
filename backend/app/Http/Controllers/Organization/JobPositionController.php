<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Http\Requests\Organization\StoreJobPositionRequest;
use App\Http\Requests\Organization\UpdateJobPositionRequest;
use App\Models\JobPosition;
use Illuminate\Http\JsonResponse;

class JobPositionController extends Controller
{
    public function index(): JsonResponse
    {
        $jobPositions = JobPosition::all();

        return $this->successResponse($jobPositions, 'Daftar posisi jabatan berhasil diambil.');
    }

    public function store(StoreJobPositionRequest $request): JsonResponse
    {
        $jobPosition = JobPosition::create($request->validated());

        return $this->successResponse($jobPosition, 'Posisi jabatan berhasil dibuat.', 201);
    }

    public function show(string|int $id_job_positions): JsonResponse
    {
        $jobPosition = JobPosition::find($id_job_positions);

        if (! $jobPosition) {
            return $this->errorResponse('Data posisi jabatan tidak ditemukan.', null, 404);
        }

        return $this->successResponse($jobPosition, 'Detail posisi jabatan berhasil diambil.');
    }

    public function update(UpdateJobPositionRequest $request, string|int $id_job_positions): JsonResponse
    {
        $jobPosition = JobPosition::find($id_job_positions);

        if (! $jobPosition) {
            return $this->errorResponse('Data posisi jabatan tidak ditemukan.', null, 404);
        }

        $jobPosition->update($request->validated());

        return $this->successResponse($jobPosition, 'Data posisi jabatan berhasil diperbarui.');
    }

    public function destroy(string|int $id_job_positions): JsonResponse
    {
        $jobPosition = JobPosition::find($id_job_positions);

        if (! $jobPosition) {
            return $this->errorResponse('Data posisi jabatan tidak ditemukan.', null, 404);
        }

        $jobPosition->delete();

        return $this->successResponse(null, 'Posisi jabatan berhasil dihapus.');
    }
}
