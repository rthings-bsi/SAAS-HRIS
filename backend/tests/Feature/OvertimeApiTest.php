<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Company;
use App\Models\Employee;
use App\Models\OvertimeRequest;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
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

    public function test_employee_can_cancel_pending_overtime_request(): void
    {
        $overtime = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-18',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'duration_hours' => 3.0,
            'reason' => 'Lembur persiapan rilis',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson("/api/v1/overtime/requests/{$overtime->id_overtime_requests}/cancel", [
            'reason' => 'Pekerjaan selesai lebih awal tanpa lembur',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'cancelled');

        $this->assertDatabaseHas('overtime_requests', [
            'id_overtime_requests' => $overtime->id_overtime_requests,
            'status' => 'cancelled',
            'rejected_reason' => 'Pekerjaan selesai lebih awal tanpa lembur',
        ]);
    }

    public function test_employee_cannot_cancel_approved_or_rejected_overtime(): void
    {
        $approvedOvertime = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-18',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'duration_hours' => 3.0,
            'reason' => 'Lembur disetujui',
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson("/api/v1/overtime/requests/{$approvedOvertime->id_overtime_requests}/cancel");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_employee_cannot_cancel_other_employee_overtime(): void
    {
        $overtimeB = OvertimeRequest::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'date' => '2026-10-18',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'duration_hours' => 3.0,
            'reason' => 'Lembur Karyawan B',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->userEmpA);

        $this->postJson("/api/v1/overtime/requests/{$overtimeB->id_overtime_requests}/cancel")
            ->assertStatus(404);
    }

    public function test_employee_can_revise_pending_overtime_request(): void
    {
        $overtime = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-19',
            'start_time' => '17:00',
            'end_time' => '19:00',
            'duration_hours' => 2.0,
            'reason' => 'Lembur awal',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->userEmpA);

        $response = $this->putJson("/api/v1/overtime/requests/{$overtime->id_overtime_requests}", [
            'date' => '2026-10-19',
            'start_time' => '18:00',
            'end_time' => '21:30',
            'reason' => 'Revisi tugas lembur: deploy hotfix',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.duration_hours', 3.5)
            ->assertJsonPath('data.reason', 'Revisi tugas lembur: deploy hotfix');

        $this->assertDatabaseHas('overtime_requests', [
            'id_overtime_requests' => $overtime->id_overtime_requests,
            'start_time' => '18:00',
            'end_time' => '21:30',
            'duration_hours' => 3.5,
            'reason' => 'Revisi tugas lembur: deploy hotfix',
        ]);
    }

    public function test_employee_cannot_revise_approved_overtime(): void
    {
        $approvedOvertime = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-19',
            'start_time' => '17:00',
            'end_time' => '19:00',
            'duration_hours' => 2.0,
            'reason' => 'Lembur disetujui',
            'status' => 'approved',
        ]);

        Sanctum::actingAs($this->userEmpA);

        $this->putJson("/api/v1/overtime/requests/{$approvedOvertime->id_overtime_requests}", [
            'reason' => 'Coba ubah yang disetujui',
        ])->assertStatus(422);
    }

    public function test_employee_can_submit_multi_day_overtime_with_per_day_hours(): void
    {
        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson('/api/v1/overtime/request', [
            'entries' => [
                ['date' => '2026-10-20', 'start_time' => '17:00', 'end_time' => '19:00'],
                ['date' => '2026-10-21', 'start_time' => '17:30', 'end_time' => '21:00'],
                ['date' => '2026-10-23', 'start_time' => '18:00', 'end_time' => '19:30'],
            ],
            'reason' => 'Tutup buku bulanan dan migrasi server',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.duration_hours', 2)
            ->assertJsonPath('data.1.duration_hours', 3.5)
            ->assertJsonPath('data.2.duration_hours', 1.5);

        $this->assertDatabaseHas('overtime_requests', [
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-20',
            'duration_hours' => 2.0,
            'status' => 'pending',
        ]);
        $this->assertDatabaseHas('overtime_requests', [
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-21',
            'duration_hours' => 3.5,
            'status' => 'pending',
        ]);
        $this->assertDatabaseHas('overtime_requests', [
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-23',
            'duration_hours' => 1.5,
            'status' => 'pending',
        ]);

        $this->assertDatabaseHas('notifications', [
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'overtime',
            'title' => 'Pengajuan Lembur Baru',
        ]);
    }

    public function test_employee_can_submit_multiple_sessions_same_day_and_overnight(): void
    {
        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson('/api/v1/overtime/request', [
            'overtime_type' => 'Jam Lembur',
            'reason_category' => 'Dukungan Operasional',
            'entries' => [
                [
                    'date' => '2026-10-20',
                    'end_date' => '2026-10-20',
                    'start_time' => '17:00',
                    'end_time' => '19:00',
                ],
                [
                    'date' => '2026-10-20',
                    'end_date' => '2026-10-20',
                    'start_time' => '20:00',
                    'end_time' => '22:00',
                ],
                [
                    'date' => '2026-10-21',
                    'end_date' => '2026-10-22',
                    'start_time' => '23:00',
                    'end_time' => '02:00',
                ],
            ],
            'reason' => 'Support produksi dan pemeliharaan malam',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.duration_hours', 2)
            ->assertJsonPath('data.0.overtime_type', 'Jam Lembur')
            ->assertJsonPath('data.0.reason_category', 'Dukungan Operasional')
            ->assertJsonPath('data.1.duration_hours', 2)
            ->assertJsonPath('data.2.end_date', '2026-10-22')
            ->assertJsonPath('data.2.duration_hours', 3);

        $this->assertDatabaseCount('overtime_requests', 3);
    }

    public function test_multi_day_overtime_rejects_overlapping_slots_in_batch(): void
    {
        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson('/api/v1/overtime/request', [
            'entries' => [
                ['date' => '2026-10-20', 'end_date' => '2026-10-20', 'start_time' => '17:00', 'end_time' => '20:00'],
                ['date' => '2026-10-20', 'end_date' => '2026-10-20', 'start_time' => '19:00', 'end_time' => '22:00'],
            ],
            'reason' => 'Jam sesi 1 dan 2 bertabrakan',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['entries.1.start_time']);

        $this->assertDatabaseCount('overtime_requests', 0);
    }

    public function test_employee_can_submit_multipart_batch_overtime_with_attachment(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA);

        $file = UploadedFile::fake()->create('surat_lembur.pdf', 128, 'application/pdf');

        $response = $this->post('/api/v1/overtime/request', [
            'overtime_type' => 'Jam Lembur',
            'reason_category' => 'Lembur',
            'reason' => 'Support Produksi Line B',
            'entries' => json_encode([
                [
                    'date' => '2026-11-09',
                    'end_date' => '2026-11-09',
                    'start_time' => '17:00',
                    'end_time' => '20:00',
                ],
                [
                    'date' => '2026-11-10',
                    'end_date' => '2026-11-10',
                    'start_time' => '18:00',
                    'end_time' => '21:00',
                ],
            ]),
            'attachment' => $file,
        ], ['Accept' => 'application/json']);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data');

        $row = OvertimeRequest::first();
        $this->assertNotNull($row);
        $this->assertNotNull($row->attachment_path);
        $this->assertStringStartsWith("{$this->companyA->id_companies}/overtimes/", $row->attachment_path);
        Storage::disk('public')->assertExists($row->attachment_path);
        $this->assertNotNull($row->attachment_url);
    }

    public function test_multi_day_overtime_rejects_invalid_end_time_in_entry(): void
    {
        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson('/api/v1/overtime/request', [
            'entries' => [
                ['date' => '2026-10-20', 'start_time' => '17:00', 'end_time' => '19:00'],
                ['date' => '2026-10-21', 'start_time' => '20:00', 'end_time' => '19:00'],
            ],
            'reason' => 'Jam terbalik pada hari kedua',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['entries.1.end_time']);

        $this->assertDatabaseCount('overtime_requests', 0);
    }

    public function test_multi_day_overtime_rolls_back_all_entries_on_overlap_conflict(): void
    {
        OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-21',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'duration_hours' => 3.0,
            'reason' => 'Lembur sebelumnya',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->userEmpA);

        $response = $this->postJson('/api/v1/overtime/request', [
            'entries' => [
                ['date' => '2026-10-20', 'start_time' => '17:00', 'end_time' => '19:00'],
                ['date' => '2026-10-21', 'start_time' => '18:00', 'end_time' => '21:00'],
                ['date' => '2026-10-22', 'start_time' => '17:00', 'end_time' => '18:30'],
            ],
            'reason' => 'Batch bertabrakan di hari kedua',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonValidationErrors(['entries.1.start_time']);

        $this->assertDatabaseCount('overtime_requests', 1);
    }

    public function test_employee_can_revise_overtime_with_metadata_cross_day_and_attachment_via_multipart_post(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA);

        $initialFile = UploadedFile::fake()->create('lampiran_awal.pdf', 100, 'application/pdf');
        $applyResp = $this->post('/api/v1/overtime/request', [
            'overtime_type' => 'Jam Lembur',
            'reason_category' => 'Lembur',
            'reason' => 'Batch awal dua hari',
            'entries' => json_encode([
                [
                    'date' => '2026-11-11',
                    'end_date' => '2026-11-11',
                    'start_time' => '17:00',
                    'end_time' => '19:00',
                ],
                [
                    'date' => '2026-11-12',
                    'end_date' => '2026-11-12',
                    'start_time' => '17:00',
                    'end_time' => '19:00',
                ],
            ]),
            'attachment' => $initialFile,
        ], ['Accept' => 'application/json'])->assertStatus(201);

        $firstId = $applyResp->json('data.0.id_overtime_requests');
        $secondId = $applyResp->json('data.1.id_overtime_requests');
        $sharedInitialPath = OvertimeRequest::findOrFail($firstId)->attachment_path;
        Storage::disk('public')->assertExists($sharedInitialPath);

        $replacementFile = UploadedFile::fake()->create('lampiran_revisi.pdf', 140, 'application/pdf');
        $reviseResp = $this->post("/api/v1/overtime/requests/{$firstId}/update", [
            'date' => '2026-11-11',
            'end_date' => '2026-11-12',
            'start_time' => '22:00',
            'end_time' => '01:30',
            'overtime_type' => 'Lembur Hari Libur',
            'reason_category' => 'Dukungan Operasional',
            'reason' => 'Revisi cutover malam lintas hari dengan lampiran baru',
            'attachment' => $replacementFile,
        ], ['Accept' => 'application/json']);

        $reviseResp->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.end_date', '2026-11-12')
            ->assertJsonPath('data.duration_hours', 3.5)
            ->assertJsonPath('data.overtime_type', 'Lembur Hari Libur')
            ->assertJsonPath('data.reason_category', 'Dukungan Operasional');

        $updatedFirst = OvertimeRequest::findOrFail($firstId);
        $this->assertNotEquals($sharedInitialPath, $updatedFirst->attachment_path);
        Storage::disk('public')->assertExists($updatedFirst->attachment_path);
        // Sibling row masih menggunakan file awal, jadi file awal tidak boleh ikut terhapus
        Storage::disk('public')->assertExists($sharedInitialPath);
        $this->assertEquals($sharedInitialPath, OvertimeRequest::findOrFail($secondId)->attachment_path);

        // Hapus lampiran dari baris pertama dan pastikan file pengganti terhapus karena tidak direferensikan baris lain
        $newPathToDelete = $updatedFirst->attachment_path;
        $removeResp = $this->putJson("/api/v1/overtime/requests/{$firstId}", [
            'date' => '2026-11-11',
            'end_date' => '2026-11-12',
            'start_time' => '22:00',
            'end_time' => '01:30',
            'reason' => 'Revisi tanpa lampiran',
            'remove_attachment' => true,
        ]);

        $removeResp->assertStatus(200)
            ->assertJsonPath('data.attachment_url', null);
        Storage::disk('public')->assertMissing($newPathToDelete);
        Storage::disk('public')->assertExists($sharedInitialPath);
    }

    public function test_employee_cannot_revise_other_tenant_overtime(): void
    {
        $otherOvertime = OvertimeRequest::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'date' => '2026-11-15',
            'start_time' => '17:00',
            'end_time' => '19:00',
            'duration_hours' => 2.0,
            'reason' => 'Lembur perusahaan B',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->userEmpA);

        $this->post("/api/v1/overtime/requests/{$otherOvertime->id_overtime_requests}/update", [
            'reason' => 'Coba ubah lintas tenant',
        ], ['Accept' => 'application/json'])->assertStatus(404);
    }

    public function test_overtime_lists_include_request_number_shift_and_tenant_scoped_actual_attendance(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Reguler Operasional',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        $this->employeeA->update(['id_shifts' => $shift->id_shifts]);

        Attendance::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-11-11',
            'clock_in_time' => '07:54:00',
            'clock_out_time' => '17:06:00',
            'status' => 'on_time',
        ]);

        Attendance::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'date' => '2026-11-11',
            'clock_in_time' => '06:00:00',
            'clock_out_time' => '23:00:00',
            'status' => 'on_time',
        ]);

        $overtime = OvertimeRequest::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-11-11',
            'end_date' => '2026-11-11',
            'start_time' => '18:00',
            'end_time' => '20:30',
            'duration_hours' => 2.5,
            'overtime_type' => 'Jam Lembur',
            'reason_category' => 'Dukungan Operasional',
            'reason' => 'Dukungan rilis sistem inventaris',
            'status' => 'pending',
        ]);

        $expectedPrefix = 'OVR-' . $overtime->created_at->format('Ym') . '-' . str_pad((string) $overtime->id_overtime_requests, 6, '0', STR_PAD_LEFT);

        Sanctum::actingAs($this->userEmpA);
        $this->getJson('/api/v1/overtime/my-requests')
            ->assertStatus(200)
            ->assertJsonPath('data.data.0.request_number', $expectedPrefix)
            ->assertJsonPath('data.data.0.employee.user.name', 'Employee A')
            ->assertJsonPath('data.data.0.employee.shift.name', 'Shift Reguler Operasional')
            ->assertJsonPath('data.data.0.actual_clock_in', '07:54:00')
            ->assertJsonPath('data.data.0.actual_clock_out', '17:06:00');

        Sanctum::actingAs($this->managerA);
        $this->getJson('/api/v1/overtime/approvals')
            ->assertStatus(200)
            ->assertJsonPath('data.data.0.request_number', $expectedPrefix)
            ->assertJsonPath('data.data.0.employee.shift.name', 'Shift Reguler Operasional')
            ->assertJsonPath('data.data.0.actual_clock_in', '07:54:00')
            ->assertJsonPath('data.data.0.actual_clock_out', '17:06:00');
    }
}
