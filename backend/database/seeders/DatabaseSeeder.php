<?php

namespace Database\Seeders;

use App\Models\Company;
use App\Models\Employee;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Company (PT Steel Pipe Industry of Indonesia / PT SPINDO with Geofencing)
        $company = Company::create([
            'name' => 'PT Steel Pipe Industry of Indonesia Tbk',
            'industry' => 'Manufaktur & Pipa Baja',
            'email' => 'corporate@spindo.com',
            'phone' => '031-7402345',
            'address' => 'Jl. Kalibutuh No. 189-191, Surabaya, Jawa Timur',
            'latitude' => -7.257500,
            'longitude' => 112.752100,
            'radius_meters' => 100,
        ]);

        // 2. Shift Master
        $shift = Shift::create([
            'id_companies' => $company->id_companies,
            'name' => 'Shift Reguler Operasional',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        // 3. User & Employee Seed Data
        $seedUsers = [
            [
                'name' => 'Ricky Satria',
                'email' => 'rickysatria@hris.com',
                'role' => 'superadmin',
                'employee' => [
                    'nik' => 'EMP-001',
                    'department_name' => 'Direksi & Manajemen Eksekutif',
                    'job_position_name' => 'Super Administrator',
                    'phone' => '081234567001',
                    'gender' => 'male',
                    'birth_date' => '1990-01-15',
                    'hire_date' => '2020-01-01',
                    'employment_status' => 'permanent',
                    'basic_salary' => 15000000.00,
                    'allowance_fixed' => 3000000.00,
                    'bank_name' => 'BCA',
                    'bank_account_number' => '8880011223',
                    'bank_account_holder' => 'Ricky Satria',
                ],
            ],
            [
                'name' => 'Adrilla',
                'email' => 'adrilla@hris.com',
                'role' => 'hr',
                'employee' => [
                    'nik' => 'EMP-002',
                    'department_name' => 'Sumber Daya Manusia',
                    'job_position_name' => 'HRD Administrator',
                    'phone' => '081234567002',
                    'gender' => 'female',
                    'birth_date' => '1995-04-12',
                    'hire_date' => '2022-02-01',
                    'employment_status' => 'permanent',
                    'basic_salary' => 9000000.00,
                    'allowance_fixed' => 2000000.00,
                    'bank_name' => 'Mandiri',
                    'bank_account_number' => '1420019283746',
                    'bank_account_holder' => 'Adrilla',
                ],
            ],
            [
                'name' => 'Norman Alaik',
                'email' => 'norman.alaik@hris.com',
                'role' => 'manager',
                'employee' => [
                    'nik' => 'EMP-003',
                    'department_name' => 'Operasional & Produksi',
                    'job_position_name' => 'Operational Manager',
                    'phone' => '081234567003',
                    'gender' => 'male',
                    'birth_date' => '1992-08-25',
                    'hire_date' => '2021-06-15',
                    'employment_status' => 'permanent',
                    'basic_salary' => 10500000.00,
                    'allowance_fixed' => 2500000.00,
                    'bank_name' => 'BNI',
                    'bank_account_number' => '0234567891',
                    'bank_account_holder' => 'Norman Alaik',
                ],
            ],
            [
                'name' => 'Budi',
                'email' => 'budi@hris.com',
                'role' => 'employee',
                'employee' => [
                    'nik' => 'EMP-004',
                    'department_name' => 'Teknologi Informasi',
                    'job_position_name' => 'Staff IT & Sistem',
                    'phone' => '081234567004',
                    'gender' => 'male',
                    'birth_date' => '1998-03-10',
                    'hire_date' => '2023-01-10',
                    'employment_status' => 'permanent',
                    'basic_salary' => 7500000.00,
                    'allowance_fixed' => 1500000.00,
                    'bank_name' => 'BCA',
                    'bank_account_number' => '1234567890',
                    'bank_account_holder' => 'Budi',
                ],
            ],
            [
                'name' => 'Siti',
                'email' => 'siti@hris.com',
                'role' => 'employee',
                'employee' => [
                    'nik' => 'EMP-005',
                    'department_name' => 'Administrasi & Keuangan',
                    'job_position_name' => 'Staff Administrasi',
                    'phone' => '081234567005',
                    'gender' => 'female',
                    'birth_date' => '1999-07-18',
                    'hire_date' => '2023-05-01',
                    'employment_status' => 'permanent',
                    'basic_salary' => 6500000.00,
                    'allowance_fixed' => 1200000.00,
                    'bank_name' => 'Mandiri',
                    'bank_account_number' => '0987654321',
                    'bank_account_holder' => 'Siti',
                ],
            ],
            [
                'name' => 'Joko',
                'email' => 'joko@hris.com',
                'role' => 'employee',
                'employee' => [
                    'nik' => 'EMP-006',
                    'department_name' => 'Operasional & Produksi',
                    'job_position_name' => 'Operator Mesin Pipa',
                    'phone' => '081234567006',
                    'gender' => 'male',
                    'birth_date' => '1997-11-05',
                    'hire_date' => '2024-02-15',
                    'employment_status' => 'contract',
                    'basic_salary' => 5800000.00,
                    'allowance_fixed' => 1000000.00,
                    'bank_name' => 'BRI',
                    'bank_account_number' => '334455667788',
                    'bank_account_holder' => 'Joko',
                ],
            ],
        ];

        foreach ($seedUsers as $item) {
            $user = User::create([
                'id_companies' => $company->id_companies,
                'name' => $item['name'],
                'email' => $item['email'],
                'password' => Hash::make('password'),
                'role' => $item['role'],
                'is_active' => true,
            ]);

            if (isset($item['employee'])) {
                $emp = $item['employee'];
                Employee::create([
                    'id_companies' => $company->id_companies,
                    'id_users' => $user->id_users,
                    'department_name' => $emp['department_name'],
                    'job_position_name' => $emp['job_position_name'],
                    'id_shifts' => $shift->id_shifts,
                    'annual_leave_quota' => 12,
                    'nik' => $emp['nik'],
                    'phone' => $emp['phone'],
                    'gender' => $emp['gender'],
                    'birth_date' => $emp['birth_date'],
                    'hire_date' => $emp['hire_date'],
                    'employment_status' => $emp['employment_status'],
                    'basic_salary' => $emp['basic_salary'],
                    'allowance_fixed' => $emp['allowance_fixed'],
                    'bank_name' => $emp['bank_name'],
                    'bank_account_number' => $emp['bank_account_number'],
                    'bank_account_holder' => $emp['bank_account_holder'],
                ]);
            }
        }
    }
}
