<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\Employee;
use App\Models\OvertimeRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OvertimeApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $hrA;
    protected User $managerA;
    protected User $userEmpA;
    protected Employee $employeeA;

    protected User $managerB;
    protected User $userEmpB;
    protected Employee $employeeB;

    protected function setUp(): void
    {
        parent::setUp();

        // Setup Company A
        $this->companyA = Company::create([
            'name' => 'PT Perusahaan A',
            'slug' => 'pt-perusahaan-a',
            'email' => 'info@a.test',
            'subscription_status' => 'active',
            'latitude' => -6.2088,
            'longitude' => 106.8456,
            'radius_meters' => 100,
        ]);

        $this->hrA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'HR User A',
            'email' => 'hr@a.test',
            'password' => Hash::make('password123'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        $this->managerA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Manager User A',
            'email' => 'manager@a.test',
            'password' => Hash::make('password123'),
            'role' => 'manager',
            'is_active' => true,
        ]);

        $this->userEmpA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Employee A',
            'email' => 'employee@a.test',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeA = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->userEmpA->id_users,
            'nik' => 'EMP-001',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
            'basic_salary' => 5000000,
            'employment_status' => 'permanent',
        ]);

        // Setup Company B
        $this->companyB = Company::create([
            'name' => 'PT Perusahaan B',
            'slug' => 'pt-perusahaan-b',
            'email' => 'info@b.test',
            'subscription_status' => 'active',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
            'radius_meters' => 100,
        ]);

        $this->managerB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Manager B',
            'email' => 'manager@b.test',
            'password' => Hash::make('password123'),
            'role' => 'manager',
            'is_active' => true,
        ]);

        $this->userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Employee B',
            'email' => 'employee@b.test',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $this->userEmpB->id_users,
            'nik' => 'EMP-002',
            'gender' => 'female',
            'hire_date' => '2024-01-01',
            'basic_salary' => 6000000,
            'employment_status' => 'permanent',
        ]);
    }

    public function test_unauthenticated_user_cannot_access_overtime(): void
    {
        $this->getJson('/api/v1/overtime/my-requests')->assertStatus(401);
        $this->postJson('/api/v1/overtime/request', [])->assertStatus(401);
        $this->getJson('/api/v1/overtime/approvals')->assertStatus(401);
    }

    public function test_regular_employee_can_submit_overtime_request(): void
    {
        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson('/api/v1/overtime/request', [
            'date' => '2026-10-15',
            'start_time' => '17:00',
            'end_time' => '20:30',
            'reason' => 'Menyelesaikan laporan keuangan akhir bulan',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.duration_hours', 3.5)
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('overtime_requests', [
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-15',
            'duration_hours' => 3.5,
            'status' => 'pending',
        ]);
    }

    public function test_overtime_validation_fails_on_missing_or_invalid_fields(): void
    {
        Sanctum::actingAs($this->userEmpA);

        // End time before start time
        $response = $this->postJson('/api/v1/overtime/request', [
            'date' => '2026-10-15',
            'start_time' => '19:00',
            'end_time' => '18:00',
            'reason' => 'Validasi jam terbalik',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['end_time']);
    }

    public function test_cannot_submit_overlapping_overtime_request(): void
    {
        Sanctum::actingAs($this->userEmpA);

        // Buat lembur pertama
        $this->postJson('/api/v1/overtime/request', [
            'date' => '2026-10-15',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'reason' => 'Lembur sesi 1',
        ])->assertStatus(201);

        // Coba lembur kedua tumpang tindih
        $response = $this->postJson('/api/v1/overtime/request', [
            'date' => '2026-10-15',
            'start_time' => '19:00',
            'end_time' => '21:00',
            'reason' => 'Lembur sesi 2 tumpang tindih',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_employee_can_view_own_requests(): void
    {
        Sanctum::actingAs($this->userEmpA);

        OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-15',
            'start_time' => '17:00',
            'end_time' => '19:00',
            'duration_hours' => 2.0,
            'reason' => 'Tugas lembur A',
            'status' => 'pending',
        ]);

        $response = $this->getJson('/api/v1/overtime/my-requests');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data.data');
    }

    public function test_regular_employee_cannot_access_approvals(): void
    {
        Sanctum::actingAs($this->userEmpA);

        $this->getJson('/api/v1/overtime/approvals')->assertStatus(403);
    }

    public function test_manager_can_view_and_approve_overtime_request(): void
    {
        $overtime = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-15',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'duration_hours' => 3.0,
            'reason' => 'Lembur perbaikan server',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->managerA);

        // Manager lihat daftar approval
        $this->getJson('/api/v1/overtime/approvals')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data.data');

        // Manager menyetujui
        $response = $this->postJson("/api/v1/overtime/approvals/{$overtime->id_overtime_requests}/action", [
            'action' => 'approved',
            'notes' => 'Disetujui untuk lembur perbaikan',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'approved');

        $this->assertDatabaseHas('overtime_requests', [
            'id_overtime_requests' => $overtime->id_overtime_requests,
            'status' => 'approved',
            'approved_by' => $this->managerA->id_users,
        ]);
    }

    public function test_hr_can_reject_overtime_request(): void
    {
        $overtime = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-15',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'duration_hours' => 3.0,
            'reason' => 'Lembur opsional',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->postJson("/api/v1/overtime/approvals/{$overtime->id_overtime_requests}/action", [
            'action' => 'rejected',
            'notes' => 'Tidak memenuhi urgensi pekerjaan',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'rejected');

        $this->assertDatabaseHas('overtime_requests', [
            'id_overtime_requests' => $overtime->id_overtime_requests,
            'status' => 'rejected',
            'rejected_reason' => 'Tidak memenuhi urgensi pekerjaan',
        ]);
    }

    public function test_multi_tenant_isolation_overtime(): void
    {
        $overtimeA = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-15',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'duration_hours' => 3.0,
            'reason' => 'Lembur rahasia PT A',
            'status' => 'pending',
        ]);

        // Manager B tidak boleh melihat overtime A
        Sanctum::actingAs($this->managerB);

        $this->getJson('/api/v1/overtime/approvals')
            ->assertStatus(200)
            ->assertJsonCount(0, 'data.data');

        // Manager B tidak boleh approve overtime A
        $this->postJson("/api/v1/overtime/approvals/{$overtimeA->id_overtime_requests}/action", [
            'action' => 'approved',
        ])->assertStatus(404);
    }
}
