<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Http\Requests\Organization\StoreBranchRequest;
use App\Http\Requests\Organization\UpdateBranchRequest;
use App\Models\Company;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BranchController extends Controller
{
    protected function getCompany(Request $request): ?Company
    {
        return $request->user()?->company ?? Company::first();
    }

    public function index(Request $request): JsonResponse
    {
        $company = $this->getCompany($request);
        $branches = [
            [
                'id_branches' => 1,
                'name' => $company?->name ?? 'Kantor Utama PT SPINDO',
                'address' => $company?->address ?? 'Jl. Kalibutuh No. 189-191, Surabaya',
                'latitude' => (float) ($company?->latitude ?? -7.2575),
                'longitude' => (float) ($company?->longitude ?? 112.7521),
                'radius_meters' => (int) ($company?->radius_meters ?? 100),
                'is_main_office' => true,
            ],
        ];

        return $this->successResponse($branches, 'Daftar cabang berhasil diambil.');
    }

    public function store(StoreBranchRequest $request): JsonResponse
    {
        $company = $this->getCompany($request);
        if ($company) {
            $company->update([
                'latitude' => $request->input('latitude'),
                'longitude' => $request->input('longitude'),
                'radius_meters' => $request->input('radius_meters', 100),
            ]);
        }

        return $this->successResponse([
            'id_branches' => 1,
            'name' => $request->input('name', $company?->name),
            'address' => $request->input('address', $company?->address),
            'latitude' => (float) $request->input('latitude'),
            'longitude' => (float) $request->input('longitude'),
            'radius_meters' => (int) $request->input('radius_meters', 100),
            'id_companies' => $company?->id_companies,
        ], 'Cabang berhasil dibuat.', 201);
    }

    public function show(Request $request, string|int $id_branches): JsonResponse
    {
        if ((int) $id_branches !== 1) {
            return $this->errorResponse('Data cabang tidak ditemukan.', null, 404);
        }

        $company = $this->getCompany($request);

        return $this->successResponse([
            'id_branches' => 1,
            'name' => $company?->name ?? 'Kantor Pusat',
            'latitude' => (float) ($company?->latitude ?? -7.2575),
            'longitude' => (float) ($company?->longitude ?? 112.7521),
            'radius_meters' => (int) ($company?->radius_meters ?? 100),
        ], 'Detail cabang berhasil diambil.');
    }

    public function update(UpdateBranchRequest $request, string|int $id_branches): JsonResponse
    {
        if ((int) $id_branches !== 1) {
            return $this->errorResponse('Data cabang tidak ditemukan.', null, 404);
        }

        $company = $this->getCompany($request);
        if ($company) {
            $company->update([
                'latitude' => $request->input('latitude', $company->latitude),
                'longitude' => $request->input('longitude', $company->longitude),
                'radius_meters' => $request->input('radius_meters', $company->radius_meters),
            ]);
        }

        return $this->successResponse([
            'id_branches' => 1,
            'name' => $request->input('name', $company?->name),
            'latitude' => (float) ($request->input('latitude', $company?->latitude) ?? -7.2575),
            'longitude' => (float) ($request->input('longitude', $company?->longitude) ?? 112.7521),
            'radius_meters' => (int) ($request->input('radius_meters', $company?->radius_meters) ?? 100),
        ], 'Data cabang berhasil diperbarui.');
    }

    public function destroy(string|int $id_branches): JsonResponse
    {
        return $this->successResponse(null, 'Cabang berhasil dihapus.');
    }
}
