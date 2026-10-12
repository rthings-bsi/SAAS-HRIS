<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LeaveApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $ownerA;
    protected User $hrA;
    protected User $managerA;
    protected User $userEmpA;
    protected Employee $employeeA;

    protected User $ownerB;
    protected User $managerB;
    protected User $userEmpB;
    protected Employee $employeeB;

    protected function setUp(): void
    {
        parent::setUp();

        // Setup Company A
        $this->companyA = Company::create([
            'name' => 'PT Solusi Teknologi Nusantara',
            'slug' => 'pt-solusi-teknologi-nusantara',
            'email' => 'info@nusantara.test',
            'subscription_status' => 'active',
            'latitude' => -6.2088,
            'longitude' => 106.8456,
            'radius_meters' => 100,
        ]);

        $this->ownerA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Owner Nusantara',
            'email' => 'owner@nusantara.test',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->hrA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'HR Nusantara',
            'email' => 'hr@nusantara.test',
            'password' => Hash::make('password123'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        $this->managerA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Manager Nusantara',
            'email' => 'manager@nusantara.test',
            'password' => Hash::make('password123'),
            'role' => 'manager',
            'is_active' => true,
        ]);

        $this->userEmpA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Staff A',
            'email' => 'staff.a@nusantara.test',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeA = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->userEmpA->id_users,
            'nik' => 'EMP-001',
            'phone' => '081234567890',
            'gender' => 'male',
            'birth_date' => '1995-01-01',
            'hire_date' => '2023-01-01',
            'employment_status' => 'permanent',
            'basic_salary' => 6000000,
            'annual_leave_quota' => 12,
        ]);

        // Setup Company B
        $this->companyB = Company::create([
            'name' => 'PT Maju Bersama Jaya',
            'slug' => 'pt-maju-bersama-jaya',
            'email' => 'info@majubersama.test',
            'subscription_status' => 'active',
            'latitude' => -7.2575,
            'longitude' => 112.7521,
            'radius_meters' => 100,
        ]);

        $this->ownerB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Owner Maju',
            'email' => 'owner@majubersama.test',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->managerB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Manager Maju',
            'email' => 'manager@majubersama.test',
            'password' => Hash::make('password123'),
            'role' => 'manager',
            'is_active' => true,
        ]);

        $this->userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Staff B',
            'email' => 'staff.b@majubersama.test',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $this->userEmpB->id_users,
            'nik' => 'EMP-B01',
            'phone' => '089876543210',
            'gender' => 'female',
            'birth_date' => '1996-05-10',
            'hire_date' => '2023-02-01',
            'employment_status' => 'permanent',
            'basic_salary' => 5500000,
            'annual_leave_quota' => 10,
        ]);
    }

    public function test_admin_owner_and_hr_can_create_leave_type(): void
    {
        Sanctum::actingAs($this->ownerA, ['*']);

        $response = $this->postJson('/api/v1/leave/types', [
            'name' => 'Cuti Menikah',
            'quota_days' => 3,
            'is_paid' => true,
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Jenis cuti berhasil dibuat.',
                'data' => [
                    'name' => 'Cuti Menikah',
                    'quota_days' => 3,
                    'is_paid' => true,
                    'id_companies' => $this->companyA->id_companies,
                ],
                'errors' => null,
            ]);

        // HR can also create leave type
        Sanctum::actingAs($this->hrA, ['*']);
        $hrResponse = $this->postJson('/api/v1/leave/types', [
            'name' => 'Cuti Melahirkan',
            'quota_days' => 90,
            'is_paid' => true,
        ]);

        $hrResponse->assertStatus(201);
    }

    public function test_regular_employee_cannot_create_leave_type(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->postJson('/api/v1/leave/types', [
            'name' => 'Cuti Ilegal',
            'quota_days' => 5,
            'is_paid' => true,
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Akses ditolak. Hanya HR atau Owner yang dapat membuat jenis cuti.',
            ]);
    }

    public function test_leave_type_creation_validation_rules(): void
    {
        Sanctum::actingAs($this->ownerA, ['*']);

        $response = $this->postJson('/api/v1/leave/types', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'quota_days', 'is_paid'])
            ->assertJson([
                'success' => false,
                'message' => 'Validasi gagal.',
            ]);
    }

    public function test_employee_can_get_leave_types(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->getJson('/api/v1/leave/types');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar jenis cuti berhasil diambil.',
            ])
            ->assertJsonFragment([
                'name' => 'Cuti Tahunan',
                'quota_days' => 12,
            ])
            ->assertJsonFragment([
                'name' => 'Cuti Sakit',
            ]);
    }

    public function test_employee_can_check_leave_balance(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        // Create an approved leave request of 2 days
        LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => Carbon::now()->startOfYear()->addDays(10)->toDateString(),
            'end_date' => Carbon::now()->startOfYear()->addDays(11)->toDateString(),
            'total_days' => 2,
            'reason' => 'Keperluan keluarga',
            'status' => 'approved',
            'approved_by' => $this->managerA->id_users,
        ]);

        // Create a pending leave request of 1 day
        LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => Carbon::now()->startOfYear()->addDays(20)->toDateString(),
            'end_date' => Carbon::now()->startOfYear()->addDays(20)->toDateString(),
            'total_days' => 1,
            'reason' => 'Perpanjang SIM',
            'status' => 'pending',
        ]);

        $response = $this->getJson('/api/v1/leave/balance');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Informasi kuota cuti berhasil diambil.',
            ])
            ->assertJsonFragment([
                'name' => 'Cuti Tahunan',
                'quota_days' => 12,
                'used_days' => 2,
                'pending_days' => 1,
                'remaining_days' => 10,
                'available_days' => 9,
            ]);
    }

    public function test_employee_can_submit_leave_request_with_attachment(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        $attachment = UploadedFile::fake()->create('surat_dokter.pdf', 300, 'application/pdf');

        $startDate = Carbon::now()->addDays(5)->toDateString();
        $endDate = Carbon::now()->addDays(7)->toDateString(); // 3 days

        $response = $this->postJson('/api/v1/leave/request', [
            'leave_type' => 'Cuti Sakit',
            'start_date' => $startDate,
            'end_date' => $endDate,
            'reason' => 'Rawat inap di rumah sakit',
            'attachment' => $attachment,
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Pengajuan cuti berhasil diajukan.',
                'data' => [
                    'id_companies' => $this->companyA->id_companies,
                    'id_employees' => $this->employeeA->id_employees,
                    'leave_type' => 'Cuti Sakit',
                    'total_days' => 3,
                    'status' => 'pending',
                ],
            ]);

        $leaveRequestId = $response->json('data.id_leave_requests');

        $this->assertDatabaseHas('leave_requests', [
            'id_leave_requests' => $leaveRequestId,
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Sakit',
            'status' => 'pending',
            'total_days' => 3,
        ]);

        // Verify attachment saved in public disk
        $leaveRequest = LeaveRequest::find($leaveRequestId);
        $this->assertNotNull($leaveRequest->attachment_url);
    }

    public function test_employee_cannot_exceed_leave_quota(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        // Set low quota for test
        $this->employeeA->update(['annual_leave_quota' => 2]);

        $startDate = Carbon::now()->addDays(1)->toDateString();
        $endDate = Carbon::now()->addDays(3)->toDateString(); // 3 days requested > 2 quota

        $response = $this->postJson('/api/v1/leave/request', [
            'leave_type' => 'Cuti Tahunan',
            'start_date' => $startDate,
            'end_date' => $endDate,
            'reason' => 'Liburan',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);

        $this->assertStringContainsString('Sisa kuota cuti tidak mencukupi', $response->json('message'));
    }

    public function test_prevent_overlapping_leave_dates(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        $startDate = Carbon::now()->addDays(10)->toDateString();
        $endDate = Carbon::now()->addDays(12)->toDateString();

        // 1st request (Day 10 - 12)
        $firstResponse = $this->postJson('/api/v1/leave/request', [
            'leave_type' => 'Cuti Tahunan',
            'start_date' => $startDate,
            'end_date' => $endDate,
            'reason' => 'Acara keluarga',
        ]);
        $firstResponse->assertStatus(201);

        // 2nd request overlapping (Day 11 - 13)
        $overlapStart = Carbon::now()->addDays(11)->toDateString();
        $overlapEnd = Carbon::now()->addDays(13)->toDateString();

        $secondResponse = $this->postJson('/api/v1/leave/request', [
            'leave_type' => 'Cuti Tahunan',
            'start_date' => $overlapStart,
            'end_date' => $overlapEnd,
            'reason' => 'Pengajuan susulan',
        ]);

        $secondResponse->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);

        $this->assertStringContainsString('Tanggal pengajuan cuti bertabrakan', $secondResponse->json('message'));
    }

    public function test_hr_or_manager_can_approve_leave_request(): void
    {
        $startDate = Carbon::now()->addDays(10)->toDateString();
        $endDate = Carbon::now()->addDays(11)->toDateString();

        $leaveRequest = LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_days' => 2,
            'reason' => 'Keperluan mendesak',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->managerA, ['*']);

        $response = $this->postJson("/api/v1/leave/approvals/{$leaveRequest->id_leave_requests}/action", [
            'action' => 'approved',
            'notes' => 'Disetujui silakan istirahat.',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Pengajuan cuti berhasil disetujui.',
                'data' => [
                    'id_leave_requests' => $leaveRequest->id_leave_requests,
                    'status' => 'approved',
                    'approved_by' => $this->managerA->id_users,
                ],
            ]);

        $this->assertDatabaseHas('leave_requests', [
            'id_leave_requests' => $leaveRequest->id_leave_requests,
            'status' => 'approved',
            'approved_by' => $this->managerA->id_users,
        ]);
    }

    public function test_hr_or_manager_can_reject_leave_request(): void
    {
        $startDate = Carbon::now()->addDays(10)->toDateString();
        $endDate = Carbon::now()->addDays(11)->toDateString();

        $leaveRequest = LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_days' => 2,
            'reason' => 'Keperluan mendesak',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->hrA, ['*']);

        $response = $this->postJson("/api/v1/leave/approvals/{$leaveRequest->id_leave_requests}/action", [
            'action' => 'rejected',
            'notes' => 'Mohon ditunda karena ada rilis sprint penting.',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Pengajuan cuti berhasil ditolak.',
                'data' => [
                    'id_leave_requests' => $leaveRequest->id_leave_requests,
                    'status' => 'rejected',
                    'rejected_reason' => 'Mohon ditunda karena ada rilis sprint penting.',
                    'approved_by' => $this->hrA->id_users,
                ],
            ]);

        $this->assertDatabaseHas('leave_requests', [
            'id_leave_requests' => $leaveRequest->id_leave_requests,
            'status' => 'rejected',
            'rejected_reason' => 'Mohon ditunda karena ada rilis sprint penting.',
        ]);
    }

    public function test_cannot_approve_already_processed_request(): void
    {
        $leaveRequest = LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => Carbon::now()->addDays(10)->toDateString(),
            'end_date' => Carbon::now()->addDays(11)->toDateString(),
            'total_days' => 2,
            'reason' => 'Keperluan mendesak',
            'status' => 'approved',
            'approved_by' => $this->managerA->id_users,
        ]);

        Sanctum::actingAs($this->managerA, ['*']);

        $response = $this->postJson("/api/v1/leave/approvals/{$leaveRequest->id_leave_requests}/action", [
            'action' => 'rejected',
            'notes' => 'Batal diubah',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Pengajuan cuti ini sudah diproses sebelumnya.',
            ]);
    }

    public function test_non_manager_cannot_approve_leave_request(): void
    {
        $leaveRequest = LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => Carbon::now()->addDays(10)->toDateString(),
            'end_date' => Carbon::now()->addDays(11)->toDateString(),
            'total_days' => 2,
            'reason' => 'Keperluan mendesak',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->postJson("/api/v1/leave/approvals/{$leaveRequest->id_leave_requests}/action", [
            'action' => 'approved',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);

        // Regular employee cannot view approvals list
        $viewResponse = $this->getJson('/api/v1/leave/approvals');
        $viewResponse->assertStatus(403);
    }

    public function test_multi_tenant_isolation_leave_requests(): void
    {
        // Company A employee creates leave request
        $leaveRequestA = LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => Carbon::now()->addDays(10)->toDateString(),
            'end_date' => Carbon::now()->addDays(11)->toDateString(),
            'total_days' => 2,
            'reason' => 'Cuti Company A',
            'status' => 'pending',
        ]);

        // Company B manager checks approvals: should not see Company A
        Sanctum::actingAs($this->managerB, ['*']);

        $approvalsResponse = $this->getJson('/api/v1/leave/approvals');
        $approvalsResponse->assertStatus(200)
            ->assertJsonMissing([
                'reason' => 'Cuti Company A',
            ]);

        // Company B manager tries to approve Company A request: 404
        $actionResponse = $this->postJson("/api/v1/leave/approvals/{$leaveRequestA->id_leave_requests}/action", [
            'action' => 'approved',
        ]);
        $actionResponse->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Pengajuan cuti tidak ditemukan.',
            ]);
    }

    public function test_employee_can_view_own_paginated_leave_requests(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => Carbon::now()->addDays(1)->toDateString(),
            'end_date' => Carbon::now()->addDays(1)->toDateString(),
            'total_days' => 1,
            'reason' => 'Izin 1',
            'status' => 'approved',
        ]);

        LeaveRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'leave_type' => 'Cuti Tahunan',
            'is_paid' => true,
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'end_date' => Carbon::now()->addDays(5)->toDateString(),
            'total_days' => 1,
            'reason' => 'Izin 2',
            'status' => 'pending',
        ]);

        $response = $this->getJson('/api/v1/leave/my-requests');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Riwayat pengajuan cuti berhasil diambil.',
            ]);

        $this->assertCount(2, $response->json('data.data'));

        // Filter by status pending
        $filteredResponse = $this->getJson('/api/v1/leave/my-requests?status=pending');
        $filteredResponse->assertStatus(200);
        $this->assertCount(1, $filteredResponse->json('data.data'));
        $this->assertEquals('Izin 2', $filteredResponse->json('data.data.0.reason'));
    }
}
