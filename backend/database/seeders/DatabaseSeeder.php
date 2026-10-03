<?php

namespace Database\Seeders;

use App\Models\Branch;
use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\JobPosition;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 0. Platform Superadmin (SaaS Owner / Web Master)
        User::create([
            'id_companies' => null,
            'name' => 'Platform Superadmin',
            'email' => 'superadmin@hris-saas.com',
            'password' => Hash::make('password'),
            'role' => 'superadmin',
            'is_active' => true,
        ]);

        // 1. Company
        $company = Company::create([
            'name' => 'PT Solusi Digital',
            'slug' => 'pt-solusi-digital',
            'email' => 'info@solusidigital.co.id',
            'phone' => '021-5551234',
            'address' => 'Jl. Jenderal Sudirman No. 45, Jakarta Selatan',
            'subscription_status' => 'active',
            'trial_ends_at' => null,
        ]);

        // 2. Branch
        $branch = Branch::create([
            'id_companies' => $company->id_companies,
            'name' => 'Kantor Pusat Jakarta',
            'address' => 'Jl. Jenderal Sudirman No. 45, Jakarta Selatan',
            'latitude' => -6.200000,
            'longitude' => 106.816666,
            'radius_meters' => 50,
        ]);

        // 3. Department
        $department = Department::create([
            'id_companies' => $company->id_companies,
            'name' => 'Teknologi Informasi',
        ]);

        // 4. Job Position
        $jobPosition = JobPosition::create([
            'id_companies' => $company->id_companies,
            'name' => 'Software Engineer',
        ]);

        // 5. Shift
        Shift::create([
            'id_companies' => $company->id_companies,
            'name' => 'Shift Reguler',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        // 6. Owner User
        User::create([
            'id_companies' => $company->id_companies,
            'name' => 'Budi Santoso',
            'email' => 'owner@solusidigital.co.id',
            'password' => Hash::make('password'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        // 7. HR User
        User::create([
            'id_companies' => $company->id_companies,
            'name' => 'Siti Rahma',
            'email' => 'hr@solusidigital.co.id',
            'password' => Hash::make('password'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        // 8. 3 Employee Users & Employee Profiles
        $employeesData = [
            [
                'name' => 'Ahmad Fauzi',
                'email' => 'ahmad.fauzi@solusidigital.co.id',
                'nik' => 'EMP-001',
                'phone' => '081234567801',
                'gender' => 'male',
                'birth_date' => '1995-05-15',
                'hire_date' => '2023-01-10',
                'employment_status' => 'permanent',
                'basic_salary' => 8000000.00,
                'allowance_fixed' => 1500000.00,
                'bank_name' => 'BCA',
                'bank_account_number' => '1234567890',
                'bank_account_holder' => 'Ahmad Fauzi',
            ],
            [
                'name' => 'Dewi Lestari',
                'email' => 'dewi.lestari@solusidigital.co.id',
                'nik' => 'EMP-002',
                'phone' => '081234567802',
                'gender' => 'female',
                'birth_date' => '1997-08-20',
                'hire_date' => '2023-03-01',
                'employment_status' => 'permanent',
                'basic_salary' => 7500000.00,
                'allowance_fixed' => 1200000.00,
                'bank_name' => 'Mandiri',
                'bank_account_number' => '0987654321',
                'bank_account_holder' => 'Dewi Lestari',
            ],
            [
                'name' => 'Rizky Pratama',
                'email' => 'rizky.pratama@solusidigital.co.id',
                'nik' => 'EMP-003',
                'phone' => '081234567803',
                'gender' => 'male',
                'birth_date' => '1999-11-12',
                'hire_date' => '2024-01-15',
                'employment_status' => 'contract',
                'basic_salary' => 6000000.00,
                'allowance_fixed' => 1000000.00,
                'bank_name' => 'BNI',
                'bank_account_number' => '1122334455',
                'bank_account_holder' => 'Rizky Pratama',
            ],
        ];

        foreach ($employeesData as $data) {
            $user = User::create([
                'id_companies' => $company->id_companies,
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make('password'),
                'role' => 'employee',
                'is_active' => true,
            ]);

            Employee::create([
                'id_companies' => $company->id_companies,
                'id_users' => $user->id_users,
                'id_branches' => $branch->id_branches,
                'id_departments' => $department->id_departments,
                'id_job_positions' => $jobPosition->id_job_positions,
                'nik' => $data['nik'],
                'phone' => $data['phone'],
                'gender' => $data['gender'],
                'birth_date' => $data['birth_date'],
                'hire_date' => $data['hire_date'],
                'employment_status' => $data['employment_status'],
                'basic_salary' => $data['basic_salary'],
                'allowance_fixed' => $data['allowance_fixed'],
                'bank_name' => $data['bank_name'],
                'bank_account_number' => $data['bank_account_number'],
                'bank_account_holder' => $data['bank_account_holder'],
            ]);
        }
    }
}
