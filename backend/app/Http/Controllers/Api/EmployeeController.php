<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Employee\StoreEmployeeRequest;
use App\Http\Requests\Employee\UpdateEmployeeRequest;
use App\Models\Employee;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class EmployeeController extends Controller
{
    public function index(): JsonResponse
    {
        $employees = Employee::with(['user', 'shift'])
            ->orderBy('id_employees', 'desc')
            ->get();

        return $this->successResponse($employees, 'Daftar karyawan berhasil diambil.');
    }

    public function store(StoreEmployeeRequest $request): JsonResponse
    {
        $employee = DB::transaction(function () use ($request) {
            $companyId = auth()->user()?->id_companies ?? 1;

            $user = User::create([
                'id_companies' => $companyId,
                'name' => $request->input('name'),
                'email' => $request->input('email'),
                'password' => Hash::make($request->input('password')),
                'role' => $request->input('role', 'employee'),
                'is_active' => true,
            ]);

            $deptName = $request->input('department_name');
            if (!$deptName && $request->filled('id_departments')) {
                $deptMap = [
                    1 => 'Teknologi Informasi',
                    2 => 'Sumber Daya Manusia',
                    3 => 'Operasional & Produksi',
                    4 => 'Keuangan & Akuntansi',
                    5 => 'Pemasaran & Penjualan',
                ];
                $deptName = $deptMap[$request->input('id_departments')] ?? ('Departemen ' . $request->input('id_departments'));
            }

            $posName = $request->input('job_position_name');
            if (!$posName && $request->filled('id_job_positions')) {
                $posMap = [
                    1 => 'Direktur Utama',
                    2 => 'Manajer HRD',
                    3 => 'Software Engineer',
                    4 => 'Staff Administrasi',
                    5 => 'Operator Mesin',
                ];
                $posName = $posMap[$request->input('id_job_positions')] ?? ('Jabatan ' . $request->input('id_job_positions'));
            }

            $shiftId = $request->input('id_shifts') ?? Shift::first()?->id_shifts;

            $employee = Employee::create([
                'id_companies' => $companyId,
                'id_users' => $user->id_users,
                'department_name' => $deptName,
                'job_position_name' => $posName,
                'id_shifts' => $shiftId,
                'annual_leave_quota' => $request->input('annual_leave_quota', 12),
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

        $employee->load(['user', 'shift']);

        return $this->successResponse($employee, 'Karyawan berhasil ditambahkan.', 201);
    }

    public function show(string|int $id_employees): JsonResponse
    {
        $employee = Employee::with(['user', 'shift'])
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
                'annual_leave_quota',
                'id_shifts',
            ];

            $employeeData = $request->only($employeeFields);

            if ($request->has('department_name')) {
                $employeeData['department_name'] = $request->input('department_name');
            } elseif ($request->filled('id_departments')) {
                $deptMap = [
                    1 => 'Teknologi Informasi',
                    2 => 'Sumber Daya Manusia',
                    3 => 'Operasional & Produksi',
                    4 => 'Keuangan & Akuntansi',
                    5 => 'Pemasaran & Penjualan',
                ];
                $employeeData['department_name'] = $deptMap[$request->input('id_departments')] ?? ('Departemen ' . $request->input('id_departments'));
            }

            if ($request->has('job_position_name')) {
                $employeeData['job_position_name'] = $request->input('job_position_name');
            } elseif ($request->filled('id_job_positions')) {
                $posMap = [
                    1 => 'Direktur Utama',
                    2 => 'Manajer HRD',
                    3 => 'Software Engineer',
                    4 => 'Staff Administrasi',
                    5 => 'Operator Mesin',
                ];
                $employeeData['job_position_name'] = $posMap[$request->input('id_job_positions')] ?? ('Jabatan ' . $request->input('id_job_positions'));
            }

            if (!empty($employeeData)) {
                $employee->update($employeeData);
            }
        });

        $employee->load(['user', 'shift']);

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

