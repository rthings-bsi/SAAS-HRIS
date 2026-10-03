<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Employee\StoreEmployeeRequest;
use App\Http\Requests\Employee\UpdateEmployeeRequest;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class EmployeeController extends Controller
{
    public function index(): JsonResponse
    {
        $employees = Employee::with(['user', 'branch', 'department', 'jobPosition'])
            ->orderBy('id_employees', 'desc')
            ->get();

        return $this->successResponse($employees, 'Daftar karyawan berhasil diambil.');
    }

    public function store(StoreEmployeeRequest $request): JsonResponse
    {
        $employee = DB::transaction(function () use ($request) {
            $companyId = auth()->user()?->id_companies;

            $user = User::create([
                'id_companies' => $companyId,
                'name' => $request->input('name'),
                'email' => $request->input('email'),
                'password' => Hash::make($request->input('password')),
                'role' => $request->input('role', 'employee'),
                'is_active' => true,
            ]);

            $employee = Employee::create([
                'id_companies' => $companyId,
                'id_users' => $user->id_users,
                'id_branches' => $request->input('id_branches'),
                'id_departments' => $request->input('id_departments'),
                'id_job_positions' => $request->input('id_job_positions'),
                'nik' => $request->input('nik'),
                'phone' => $request->input('phone'),
                'gender' => $request->input('gender'),
                'birth_date' => $request->input('birth_date'),
                'hire_date' => $request->input('hire_date'),
                'employment_status' => $request->input('employment_status', 'contract'),
                'basic_salary' => $request->input('basic_salary', 0),
                'allowance_fixed' => $request->input('allowance_fixed', 0),
                'bank_name' => $request->input('bank_name'),
                'bank_account_number' => $request->input('bank_account_number'),
                'bank_account_holder' => $request->input('bank_account_holder'),
            ]);

            return $employee;
        });

        $employee->load(['user', 'branch', 'department', 'jobPosition']);

        return $this->successResponse($employee, 'Karyawan berhasil ditambahkan.', 201);
    }

    public function show(string|int $id_employees): JsonResponse
    {
        $employee = Employee::with(['user', 'branch', 'department', 'jobPosition'])
            ->findOrFail($id_employees);

        return $this->successResponse($employee, 'Detail karyawan berhasil diambil.');
    }

    public function update(UpdateEmployeeRequest $request, string|int $id_employees): JsonResponse
    {
        $employee = Employee::findOrFail($id_employees);

        DB::transaction(function () use ($request, $employee) {
            $user = $employee->user;
            if ($user) {
                $userData = [];
                if ($request->filled('name')) {
                    $userData['name'] = $request->input('name');
                }
                if ($request->filled('email')) {
                    $userData['email'] = $request->input('email');
                }
                if ($request->filled('password')) {
                    $userData['password'] = Hash::make($request->input('password'));
                }
                if ($request->filled('role')) {
                    $userData['role'] = $request->input('role');
                }
                if (!empty($userData)) {
                    $user->update($userData);
                }
            }

            $employeeFields = [
                'id_branches',
                'id_departments',
                'id_job_positions',
                'nik',
                'phone',
                'gender',
                'birth_date',
                'hire_date',
                'employment_status',
                'basic_salary',
                'allowance_fixed',
                'bank_name',
                'bank_account_number',
                'bank_account_holder',
            ];

            $employeeData = $request->only($employeeFields);
            if (!empty($employeeData)) {
                $employee->update($employeeData);
            }
        });

        $employee->load(['user', 'branch', 'department', 'jobPosition']);

        return $this->successResponse($employee, 'Data karyawan berhasil diperbarui.');
    }

    public function destroy(string|int $id_employees): JsonResponse
    {
        $employee = Employee::findOrFail($id_employees);

        DB::transaction(function () use ($employee) {
            $user = $employee->user;
            $employee->delete();
            if ($user) {
                $user->delete();
            }
        });

        return $this->successResponse(null, 'Karyawan berhasil dihapus.');
    }
}
