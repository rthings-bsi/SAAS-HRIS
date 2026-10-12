<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Company;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CompanyProfileController extends Controller
{
    public function show(): JsonResponse
    {
        $company = Company::find(1) ?? Company::firstOrCreate(
            ['id_companies' => 1],
            ['name' => 'PT. Steel Pipe Industry Of Indonesia']
        );

        return response()->json([
            'success' => true,
            'message' => 'Profil perusahaan berhasil diambil.',
            'data' => $company,
            'errors' => null,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'industry' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:255',
            'website' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:50',
            'address' => 'nullable|string|max:500',
            'director_name' => 'nullable|string|max:255',
            'hr_manager_name' => 'nullable|string|max:255',
        ]);

        $company = Company::find(1) ?? Company::firstOrCreate(
            ['id_companies' => 1],
            ['name' => $request->input('name')]
        );

        $company->update($request->only([
            'name',
            'industry',
            'email',
            'website',
            'phone',
            'address',
            'director_name',
            'hr_manager_name',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Profil perusahaan berhasil diperbarui.',
            'data' => $company,
            'errors' => null,
        ]);
    }
}
