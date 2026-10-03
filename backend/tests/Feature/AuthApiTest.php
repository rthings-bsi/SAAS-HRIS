<?php

namespace Tests\Feature;

use App\Models\Branch;
use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\JobPosition;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_company_successful(): void
    {
        $payload = [
            'company_name' => 'PT Teknologi Nusantara',
            'name' => 'Budi Santoso',
            'email' => 'budi@teknus.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'phone' => '081234567890',
            'address' => 'Jl. Jend. Sudirman Kav. 1, Jakarta',
        ];

        $response = $this->postJson('/api/v1/auth/register-company', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Registrasi perusahaan berhasil.',
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
                        'is_active',
                    ],
                    'company' => [
                        'id_companies',
                        'name',
                        'slug',
                        'email',
                        'subscription_status',
                        'trial_ends_at',
                    ],
                ],
                'errors',
            ]);

        $company = Company::where('slug', 'pt-teknologi-nusantara')->first();
        $this->assertNotNull($company);
        $this->assertEquals('trial', $company->subscription_status);
        $this->assertNotNull($company->trial_ends_at);

        $branch = Branch::where('id_companies', $company->id_companies)->first();
        $this->assertNotNull($branch);
        $this->assertEquals('Kantor Utama', $branch->name);
        $this->assertEquals(-6.2088, (float) $branch->latitude);
        $this->assertEquals(106.8456, (float) $branch->longitude);
        $this->assertEquals(50, $branch->radius_meters);

        $shift = Shift::where('id_companies', $company->id_companies)->first();
        $this->assertNotNull($shift);
        $this->assertEquals('Shift Normal', $shift->name);
        $this->assertEquals('08:00:00', $shift->start_time);
        $this->assertEquals('17:00:00', $shift->end_time);
        $this->assertEquals(15, $shift->late_tolerance_minutes);

        $user = User::where('email', 'budi@teknus.com')->first();
        $this->assertNotNull($user);
        $this->assertEquals('owner', $user->role);
        $this->assertTrue($user->is_active);
        $this->assertEquals($company->id_companies, $user->id_companies);
    }

    public function test_register_company_validation_failure(): void
    {
        $response = $this->postJson('/api/v1/auth/register-company', []);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validasi gagal.',
                'data' => null,
            ])
            ->assertJsonValidationErrors(['company_name', 'name', 'email', 'password']);
    }

    public function test_register_company_duplicate_email(): void
    {
        User::create([
            'name' => 'Existing User',
            'email' => 'existing@test.com',
            'password' => Hash::make('password'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $payload = [
            'company_name' => 'PT Baru',
            'name' => 'User Baru',
            'email' => 'existing@test.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        $response = $this->postJson('/api/v1/auth/register-company', $payload);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validasi gagal.',
                'data' => null,
            ])
            ->assertJsonValidationErrors(['email']);
    }

    public function test_register_company_duplicate_name_generates_unique_slug(): void
    {
        $payload1 = [
            'company_name' => 'PT Kembar',
            'name' => 'Owner 1',
            'email' => 'owner1@test.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        $payload2 = [
            'company_name' => 'PT Kembar',
            'name' => 'Owner 2',
            'email' => 'owner2@test.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        $this->postJson('/api/v1/auth/register-company', $payload1)->assertStatus(201);
        $this->postJson('/api/v1/auth/register-company', $payload2)->assertStatus(201);

        $this->assertDatabaseHas('companies', ['slug' => 'pt-kembar']);
        $this->assertDatabaseHas('companies', ['slug' => 'pt-kembar-1']);
    }

    public function test_login_successful(): void
    {
        $company = Company::create([
            'name' => 'PT Maju Terus',
            'slug' => 'pt-maju-terus',
            'email' => 'info@majuterus.com',
            'subscription_status' => 'active',
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
            'slug' => 'pt-solusi-digital',
            'email' => 'info@solusidigital.co.id',
            'subscription_status' => 'active',
        ]);

        $branch = Branch::create([
            'id_companies' => $company->id_companies,
            'name' => 'Kantor Pusat',
            'address' => 'Jl. Sudirman',
            'latitude' => -6.200000,
            'longitude' => 106.816666,
            'radius_meters' => 50,
        ]);

        $department = Department::create([
            'id_companies' => $company->id_companies,
            'name' => 'IT',
        ]);

        $jobPosition = JobPosition::create([
            'id_companies' => $company->id_companies,
            'name' => 'Software Engineer',
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
            'id_branches' => $branch->id_branches,
            'id_departments' => $department->id_departments,
            'id_job_positions' => $jobPosition->id_job_positions,
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
            'slug' => 'pt-maju-terus',
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
            'slug' => 'pt-maju-terus',
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
            'slug' => 'pt-maju-terus',
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
            'slug' => 'pt-maju-terus',
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
