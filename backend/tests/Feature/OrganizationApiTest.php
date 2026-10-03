<?php

namespace Tests\Feature;

use App\Models\Branch;
use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\JobPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class OrganizationApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $userA;
    protected User $userB;
    protected string $tokenA;
    protected string $tokenB;

    protected function setUp(): void
    {
        parent::setUp();

        $this->companyA = Company::create([
            'name' => 'Perusahaan A',
            'slug' => 'perusahaan-a',
            'email' => 'corp-a@test.com',
            'subscription_status' => 'active',
        ]);

        $this->userA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Owner A',
            'email' => 'owner.a@test.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);
        $this->tokenA = $this->userA->createToken('test_token')->plainTextToken;

        $this->companyB = Company::create([
            'name' => 'Perusahaan B',
            'slug' => 'perusahaan-b',
            'email' => 'corp-b@test.com',
            'subscription_status' => 'active',
        ]);

        $this->userB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Owner B',
            'email' => 'owner.b@test.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);
        $this->tokenB = $this->userB->createToken('test_token')->plainTextToken;
    }

    // ==================== BRANCHES ====================

    public function test_get_branches_list_scoped_to_tenant(): void
    {
        $branchA = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Cabang Jakarta A',
            'address' => 'Jl. Sudirman No. 1',
            'latitude' => -6.2088,
            'longitude' => 106.8456,
            'radius_meters' => 50,
        ]);

        $branchB = Branch::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Cabang Surabaya B',
            'address' => 'Jl. Pemuda No. 2',
            'latitude' => -7.2504,
            'longitude' => 112.7688,
            'radius_meters' => 60,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->getJson('/api/v1/branches');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar cabang berhasil diambil.',
            ]);

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals($branchA->id_branches, $data[0]['id_branches']);
    }

    public function test_create_branch_successful(): void
    {
        $payload = [
            'name' => 'Cabang Bandung',
            'address' => 'Jl. Asia Afrika No. 10',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
            'radius_meters' => 75,
        ];

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->postJson('/api/v1/branches', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Cabang berhasil dibuat.',
                'data' => [
                    'name' => 'Cabang Bandung',
                    'address' => 'Jl. Asia Afrika No. 10',
                    'radius_meters' => 75,
                    'id_companies' => $this->companyA->id_companies,
                ],
                'errors' => null,
            ]);

        $this->assertDatabaseHas('branches', [
            'name' => 'Cabang Bandung',
            'id_companies' => $this->companyA->id_companies,
        ]);
    }

    public function test_create_branch_validation_failure(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->postJson('/api/v1/branches', []);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validasi gagal.',
                'data' => null,
            ])
            ->assertJsonValidationErrors(['name', 'address', 'latitude', 'longitude']);
    }

    public function test_show_branch_successful(): void
    {
        $branch = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Cabang Semarang',
            'address' => 'Jl. Pandanaran No. 5',
            'latitude' => -6.9833,
            'longitude' => 110.4167,
            'radius_meters' => 50,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->getJson('/api/v1/branches/' . $branch->id_branches);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Detail cabang berhasil diambil.',
                'data' => [
                    'id_branches' => $branch->id_branches,
                    'name' => 'Cabang Semarang',
                ],
            ]);
    }

    public function test_show_branch_cross_tenant_returns_404(): void
    {
        $branchB = Branch::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Cabang Milik B',
            'address' => 'Jl. Milik B No. 1',
            'latitude' => -6.2,
            'longitude' => 106.8,
            'radius_meters' => 50,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->getJson('/api/v1/branches/' . $branchB->id_branches);

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Data cabang tidak ditemukan.',
                'data' => null,
            ]);
    }

    public function test_update_branch_successful(): void
    {
        $branch = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Cabang Lama',
            'address' => 'Jl. Lama',
            'latitude' => -6.2,
            'longitude' => 106.8,
            'radius_meters' => 50,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->putJson('/api/v1/branches/' . $branch->id_branches, [
                'name' => 'Cabang Baru Diperbarui',
                'radius_meters' => 100,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Data cabang berhasil diperbarui.',
                'data' => [
                    'name' => 'Cabang Baru Diperbarui',
                    'radius_meters' => 100,
                ],
            ]);
    }

    public function test_delete_branch_successful(): void
    {
        $branch = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Cabang Akan Dihapus',
            'address' => 'Jl. Hapus',
            'latitude' => -6.2,
            'longitude' => 106.8,
            'radius_meters' => 50,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->deleteJson('/api/v1/branches/' . $branch->id_branches);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Cabang berhasil dihapus.',
                'data' => null,
            ]);

        $this->assertDatabaseMissing('branches', [
            'id_branches' => $branch->id_branches,
        ]);
    }

    public function test_delete_branch_fails_if_has_employees(): void
    {
        $branch = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Cabang Dengan Pegawai',
            'address' => 'Jl. Ramai',
            'latitude' => -6.2,
            'longitude' => 106.8,
            'radius_meters' => 50,
        ]);

        $employeeUser = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Karyawan 1',
            'email' => 'karyawan1@test.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $employeeUser->id_users,
            'id_branches' => $branch->id_branches,
            'nik' => 'NIK-001',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->deleteJson('/api/v1/branches/' . $branch->id_branches);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Cabang tidak dapat dihapus karena masih memiliki data karyawan terkait.',
                'data' => null,
            ]);

        $this->assertDatabaseHas('branches', [
            'id_branches' => $branch->id_branches,
        ]);
    }

    // ==================== DEPARTMENTS ====================

    public function test_get_departments_list_scoped_to_tenant(): void
    {
        $deptA = Department::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Departemen HR (A)',
        ]);

        Department::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Departemen HR (B)',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->getJson('/api/v1/departments');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar departemen berhasil diambil.',
            ]);

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals($deptA->id_departments, $data[0]['id_departments']);
    }

    public function test_create_department_successful(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->postJson('/api/v1/departments', [
                'name' => 'Teknologi Informasi',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Departemen berhasil dibuat.',
                'data' => [
                    'name' => 'Teknologi Informasi',
                    'id_companies' => $this->companyA->id_companies,
                ],
            ]);
    }

    public function test_create_department_validation_failure(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->postJson('/api/v1/departments', []);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validasi gagal.',
            ])
            ->assertJsonValidationErrors(['name']);
    }

    public function test_show_department_cross_tenant_returns_404(): void
    {
        $deptB = Department::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Dept B',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->getJson('/api/v1/departments/' . $deptB->id_departments);

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Data departemen tidak ditemukan.',
            ]);
    }

    public function test_update_department_successful(): void
    {
        $dept = Department::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Dept Lama',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->putJson('/api/v1/departments/' . $dept->id_departments, [
                'name' => 'Dept Baru',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Data departemen berhasil diperbarui.',
                'data' => [
                    'name' => 'Dept Baru',
                ],
            ]);
    }

    public function test_delete_department_successful(): void
    {
        $dept = Department::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Dept Dihapus',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->deleteJson('/api/v1/departments/' . $dept->id_departments);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Departemen berhasil dihapus.',
            ]);

        $this->assertDatabaseMissing('departments', [
            'id_departments' => $dept->id_departments,
        ]);
    }

    // ==================== JOB POSITIONS ====================

    public function test_get_job_positions_list_scoped_to_tenant(): void
    {
        $posA = JobPosition::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Software Engineer (A)',
        ]);

        JobPosition::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Software Engineer (B)',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->getJson('/api/v1/job-positions');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar posisi jabatan berhasil diambil.',
            ]);

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals($posA->id_job_positions, $data[0]['id_job_positions']);
    }

    public function test_create_job_position_successful(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->postJson('/api/v1/job-positions', [
                'name' => 'Backend Developer',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Posisi jabatan berhasil dibuat.',
                'data' => [
                    'name' => 'Backend Developer',
                    'id_companies' => $this->companyA->id_companies,
                ],
            ]);
    }

    public function test_create_job_position_validation_failure(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->postJson('/api/v1/job-positions', []);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validasi gagal.',
            ])
            ->assertJsonValidationErrors(['name']);
    }

    public function test_show_job_position_cross_tenant_returns_404(): void
    {
        $posB = JobPosition::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Position B',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->getJson('/api/v1/job-positions/' . $posB->id_job_positions);

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Data posisi jabatan tidak ditemukan.',
            ]);
    }

    public function test_update_job_position_successful(): void
    {
        $pos = JobPosition::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Position Old',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->putJson('/api/v1/job-positions/' . $pos->id_job_positions, [
                'name' => 'Position New',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Data posisi jabatan berhasil diperbarui.',
                'data' => [
                    'name' => 'Position New',
                ],
            ]);
    }

    public function test_delete_job_position_successful(): void
    {
        $pos = JobPosition::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Position To Delete',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenA)
            ->deleteJson('/api/v1/job-positions/' . $pos->id_job_positions);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Posisi jabatan berhasil dihapus.',
            ]);

        $this->assertDatabaseMissing('job_positions', [
            'id_job_positions' => $pos->id_job_positions,
        ]);
    }
}
