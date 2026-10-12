<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_company_endpoint_is_removed_for_single_company(): void
    {
        $response = $this->postJson('/api/v1/auth/register-company', [
            'company_name' => 'PT Any',
            'name' => 'User',
            'email' => 'user@any.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(404);
    }

    public function test_login_successful(): void
    {
        $company = Company::create([
            'name' => 'PT Maju Terus',
            'email' => 'info@majuterus.com',
        ]);

        User::create([
            'id_companies' => $company->id_companies,
            'name' => 'Siti Aminah',
            'email' => 'siti@majuterus.com',
            'password' => Hash::make('secret123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'siti@majuterus.com',
            'password' => 'secret123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Login berhasil.',
                'errors' => null,
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'access_token',
                    'token_type',
                    'user' => [
                        'id_users',
                        'id_companies',
                        'name',
                        'email',
                        'role',
                        'company',
                    ],
                ],
                'errors',
            ]);
    }

    public function test_login_employee_eager_loads_employee_profile_and_relations(): void
    {
        $company = Company::create([
            'name' => 'PT Solusi Digital',
            'email' => 'info@solusidigital.co.id',
            'latitude' => -6.200000,
            'longitude' => 106.816666,
            'radius_meters' => 50,
        ]);

        $user = User::create([
            'id_companies' => $company->id_companies,
            'name' => 'Ahmad Fauzi',
            'email' => 'ahmad.fauzi@solusidigital.co.id',
            'password' => Hash::make('password'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        Employee::create([
            'id_companies' => $company->id_companies,
            'id_users' => $user->id_users,
            'department_name' => 'IT',
            'job_position_name' => 'Software Engineer',
            'nik' => 'EMP-001',
            'phone' => '081234567801',
            'gender' => 'male',
            'birth_date' => '1995-05-15',
            'hire_date' => '2023-01-10',
            'employment_status' => 'permanent',
            'basic_salary' => 8000000.00,
            'allowance_fixed' => 1500000.00,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'ahmad.fauzi@solusidigital.co.id',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Login berhasil.',
            ])
            ->assertJsonStructure([
                'data' => [
                    'user' => [
                        'id_users',
                        'name',
                        'email',
                        'role',
                        'company',
                        'employee' => [
                            'id_employees',
                            'nik',
                            'branch' => [
                                'id_branches',
                                'name',
                            ],
                            'department' => [
                                'id_departments',
                                'name',
                            ],
                            'job_position' => [
                                'id_job_positions',
                                'name',
                            ],
                        ],
                    ],
                ],
            ]);
    }

    public function test_login_invalid_password(): void
    {
        $company = Company::create([
            'name' => 'PT Maju Terus',
            'email' => 'info@majuterus.com',
        ]);

        User::create([
            'id_companies' => $company->id_companies,
            'name' => 'Siti Aminah',
            'email' => 'siti@majuterus.com',
            'password' => Hash::make('secret123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'siti@majuterus.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Email atau password salah.',
                'data' => null,
                'errors' => null,
            ]);
    }

    public function test_login_inactive_user(): void
    {
        $company = Company::create([
            'name' => 'PT Maju Terus',
            'email' => 'info@majuterus.com',
        ]);

        User::create([
            'id_companies' => $company->id_companies,
            'name' => 'User Nonaktif',
            'email' => 'nonaktif@majuterus.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
            'is_active' => false,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nonaktif@majuterus.com',
            'password' => 'secret123',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Akun Anda tidak aktif.',
                'data' => null,
                'errors' => null,
            ]);
    }

    public function test_logout_successful(): void
    {
        $company = Company::create([
            'name' => 'PT Maju Terus',
            'email' => 'info@majuterus.com',
        ]);

        $user = User::create([
            'id_companies' => $company->id_companies,
            'name' => 'User Test',
            'email' => 'test@majuterus.com',
            'password' => Hash::make('secret123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $token = $user->createToken('access_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Logout berhasil.',
                'data' => null,
                'errors' => null,
            ]);

        $this->assertCount(0, $user->fresh()->tokens);
    }

    public function test_get_me_successful(): void
    {
        $company = Company::create([
            'name' => 'PT Maju Terus',
            'email' => 'info@majuterus.com',
        ]);

        $user = User::create([
            'id_companies' => $company->id_companies,
            'name' => 'User Me',
            'email' => 'me@majuterus.com',
            'password' => Hash::make('secret123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $token = $user->createToken('access_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Profil berhasil diambil.',
                'data' => [
                    'id_users' => $user->id_users,
                    'email' => 'me@majuterus.com',
                    'company' => [
                        'id_companies' => $company->id_companies,
                    ],
                ],
                'errors' => null,
            ]);
    }

    public function test_get_me_unauthenticated(): void
    {
        $response = $this->getJson('/api/v1/auth/me');

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthenticated.',
                'data' => null,
                'errors' => null,
            ]);
    }
}
