<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Http\Requests\Organization\StoreBranchRequest;
use App\Http\Requests\Organization\UpdateBranchRequest;
use App\Models\Branch;
use Illuminate\Http\JsonResponse;

class BranchController extends Controller
{
    public function index(): JsonResponse
    {
        $branches = Branch::all();

        return $this->successResponse($branches, 'Daftar cabang berhasil diambil.');
    }

    public function store(StoreBranchRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['radius_meters'] = $data['radius_meters'] ?? 50;

        $branch = Branch::create($data);

        return $this->successResponse($branch, 'Cabang berhasil dibuat.', 201);
    }

    public function show(string|int $id_branches): JsonResponse
    {
        $branch = Branch::find($id_branches);

        if (! $branch) {
            return $this->errorResponse('Data cabang tidak ditemukan.', null, 404);
        }

        return $this->successResponse($branch, 'Detail cabang berhasil diambil.');
    }

    public function update(UpdateBranchRequest $request, string|int $id_branches): JsonResponse
    {
        $branch = Branch::find($id_branches);

        if (! $branch) {
            return $this->errorResponse('Data cabang tidak ditemukan.', null, 404);
        }

        $branch->update($request->validated());

        return $this->successResponse($branch, 'Data cabang berhasil diperbarui.');
    }

    public function destroy(string|int $id_branches): JsonResponse
    {
        $branch = Branch::find($id_branches);

        if (! $branch) {
            return $this->errorResponse('Data cabang tidak ditemukan.', null, 404);
        }

        if ($branch->employees()->exists()) {
            return $this->errorResponse('Cabang tidak dapat dihapus karena masih memiliki data karyawan terkait.', null, 422);
        }

        $branch->delete();

        return $this->successResponse(null, 'Cabang berhasil dihapus.');
    }
}
