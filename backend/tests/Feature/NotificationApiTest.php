<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\Employee;
use App\Models\Notification;
use App\Models\User;
use App\Services\Leave\LeaveService;
use App\Services\Overtime\OvertimeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;

    protected User $hrA;
    protected User $empUserA;
    protected Employee $employeeA;

    protected User $hrB;
    protected User $empUserB;
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
            'name' => 'HR Perusahaan A',
            'email' => 'hr@a.test',
            'password' => Hash::make('password'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        $this->empUserA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Karyawan A',
            'email' => 'emp@a.test',
            'password' => Hash::make('password'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeA = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->empUserA->id_users,
            'nik' => 'NIK-001',
            'phone' => '081234567890',
            'gender' => 'male',
            'birth_date' => '1995-01-01',
            'hire_date' => '2024-01-01',
            'department_name' => 'IT Engineering',
            'job_position_name' => 'Software Engineer',
            'employment_status' => 'permanent',
            'join_date' => '2024-01-01',
            'basic_salary' => 10000000,
            'annual_leave_quota' => 12,
        ]);

        // Setup Company B
        $this->companyB = Company::create([
            'name' => 'PT Perusahaan B',
            'slug' => 'pt-perusahaan-b',
            'email' => 'info@b.test',
            'subscription_status' => 'active',
            'latitude' => -7.2575,
            'longitude' => 112.7521,
            'radius_meters' => 100,
        ]);

        $this->hrB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'HR Perusahaan B',
            'email' => 'hr@b.test',
            'password' => Hash::make('password'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        $this->empUserB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Karyawan B',
            'email' => 'emp@b.test',
            'password' => Hash::make('password'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $this->empUserB->id_users,
            'nik' => 'NIK-002',
            'phone' => '081234567891',
            'gender' => 'female',
            'birth_date' => '1996-02-02',
            'hire_date' => '2024-01-01',
            'department_name' => 'Finance',
            'job_position_name' => 'Accountant',
            'employment_status' => 'permanent',
            'join_date' => '2024-01-01',
            'basic_salary' => 8000000,
            'annual_leave_quota' => 12,
        ]);
    }

    public function test_user_can_list_notifications_and_read_unread_count(): void
    {
        Notification::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'leave',
            'title' => 'Pengajuan Cuti',
            'message' => 'Karyawan A mengajukan cuti tahunan.',
            'is_read' => false,
        ]);

        Notification::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'overtime',
            'title' => 'Pengajuan Lembur',
            'message' => 'Karyawan A mengajukan lembur 2 jam.',
            'is_read' => true,
            'read_at' => now(),
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->getJson('/api/v1/notifications');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar notifikasi berhasil diambil.',
            ])
            ->assertJsonPath('data.unread_count', 1)
            ->assertJsonCount(2, 'data.notifications');
    }

    public function test_user_can_fetch_unread_count_only(): void
    {
        Notification::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'system',
            'title' => 'Pemberitahuan Sistem',
            'message' => 'Pemeliharaan server terjadwal.',
            'is_read' => false,
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->getJson('/api/v1/notifications/unread-count');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'unread_count' => 1,
                ],
            ]);
    }

    public function test_multi_tenant_isolation_prevents_leak_between_companies(): void
    {
        // Notification in Company B
        $notifB = Notification::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $this->hrB->id_users,
            'type' => 'leave',
            'title' => 'Pengajuan Cuti Company B',
            'message' => 'Rahasia perusahaan B.',
            'is_read' => false,
        ]);

        // User A logs in
        Sanctum::actingAs($this->hrA);

        // Cannot view B's notification in list
        $response = $this->getJson('/api/v1/notifications');
        $response->assertStatus(200)
            ->assertJsonPath('data.unread_count', 0)
            ->assertJsonCount(0, 'data.notifications');

        // Cannot mark B's notification as read
        $markResponse = $this->putJson("/api/v1/notifications/{$notifB->id_notifications}/read");
        $markResponse->assertStatus(404);

        // Cannot delete B's notification
        $delResponse = $this->deleteJson("/api/v1/notifications/{$notifB->id_notifications}");
        $delResponse->assertStatus(404);
    }

    public function test_user_can_mark_single_notification_as_read(): void
    {
        $notif = Notification::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'payroll',
            'title' => 'Gaji Diproses',
            'message' => 'Periode Oktober siap diperiksa.',
            'is_read' => false,
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->putJson("/api/v1/notifications/{$notif->id_notifications}/read");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id_notifications' => $notif->id_notifications,
                    'is_read' => true,
                    'unread_count' => 0,
                ],
            ]);

        $this->assertDatabaseHas('notifications', [
            'id_notifications' => $notif->id_notifications,
            'is_read' => true,
        ]);
    }

    public function test_user_can_mark_all_notifications_as_read(): void
    {
        Notification::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'leave',
            'title' => 'Notif 1',
            'message' => 'Pesan 1',
            'is_read' => false,
        ]);

        Notification::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'overtime',
            'title' => 'Notif 2',
            'message' => 'Pesan 2',
            'is_read' => false,
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->putJson('/api/v1/notifications/read-all');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'marked_count' => 2,
                    'unread_count' => 0,
                ],
            ]);

        $this->assertEquals(0, Notification::where('id_users', $this->hrA->id_users)->where('is_read', false)->count());
    }

    public function test_leave_application_and_approval_triggers_notifications(): void
    {
        $leaveService = app(LeaveService::class);

        // 1. Employee A applies for leave -> HR A should get notification
        Sanctum::actingAs($this->empUserA);
        $leaveRequest = $leaveService->applyLeave($this->employeeA, [
            'leave_type' => 'Cuti Tahunan',
            'start_date' => '2026-11-01',
            'end_date' => '2026-11-03',
            'reason' => 'Liburan keluarga',
        ]);

        $this->assertDatabaseHas('notifications', [
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'leave',
            'title' => 'Pengajuan Cuti Baru',
        ]);

        // 2. HR A approves leave -> Employee A should get notification
        Sanctum::actingAs($this->hrA);
        $leaveService->processApproval($leaveRequest, $this->hrA, 'approved');

        $this->assertDatabaseHas('notifications', [
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->empUserA->id_users,
            'type' => 'leave',
            'title' => 'Pengajuan Cuti Disetujui',
        ]);
    }

    public function test_overtime_application_and_approval_triggers_notifications(): void
    {
        $overtimeService = app(OvertimeService::class);

        // 1. Employee A applies for overtime -> HR A should get notification
        Sanctum::actingAs($this->empUserA);
        $overtime = $overtimeService->applyOvertime($this->employeeA, [
            'date' => '2026-10-20',
            'start_time' => '17:00',
            'end_time' => '20:00',
            'reason' => 'Penyelesaian deployment akhir',
        ]);

        $this->assertDatabaseHas('notifications', [
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->hrA->id_users,
            'type' => 'overtime',
            'title' => 'Pengajuan Lembur Baru',
        ]);

        // 2. HR A approves overtime -> Employee A should get notification
        Sanctum::actingAs($this->hrA);
        $overtimeService->processApproval($overtime, $this->hrA, 'approved');

        $this->assertDatabaseHas('notifications', [
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->empUserA->id_users,
            'type' => 'overtime',
            'title' => 'Pengajuan Lembur Disetujui',
        ]);
    }
}
