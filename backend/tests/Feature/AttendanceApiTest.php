<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Branch;
use App\Models\Company;
use App\Models\Employee;
use App\Models\EmployeeShift;
use App\Models\Shift;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AttendanceApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $ownerA;
    protected User $hrA;
    protected User $managerA;
    protected User $userEmpA;
    protected Employee $employeeA;
    protected Branch $branchA;
    protected Shift $shiftA;

    protected User $ownerB;
    protected User $userEmpB;
    protected Employee $employeeB;
    protected Branch $branchB;
    protected Shift $shiftB;

    protected function setUp(): void
    {
        parent::setUp();

        // Company A setup
        $this->companyA = Company::create([
            'name' => 'PT Nusantara Sejahtera',
            'slug' => 'pt-nusantara-sejahtera',
            'email' => 'nusantara@test.com',
            'subscription_status' => 'active',
        ]);

        $this->ownerA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Owner A',
            'email' => 'owner@nusantara.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->hrA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'HR A',
            'email' => 'hr@nusantara.com',
            'password' => Hash::make('password123'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        $this->managerA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Manager A',
            'email' => 'manager@nusantara.com',
            'password' => Hash::make('password123'),
            'role' => 'manager',
            'is_active' => true,
        ]);

        $this->branchA = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Kantor Pusat Jakarta',
            'address' => 'Jl. Jend. Sudirman Kav. 1, Jakarta Pusat',
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'radius_meters' => 100,
        ]);

        $this->shiftA = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Normal Pagi',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        $this->userEmpA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Budi Santoso',
            'email' => 'budi@nusantara.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeA = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->userEmpA->id_users,
            'id_branches' => $this->branchA->id_branches,
            'nik' => 'EMP-001',
            'phone' => '08123456789',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        // Company B setup
        $this->companyB = Company::create([
            'name' => 'PT Maju Bersama',
            'slug' => 'pt-maju-bersama',
            'email' => 'maju@test.com',
            'subscription_status' => 'active',
        ]);

        $this->ownerB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Owner B',
            'email' => 'owner@maju.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->branchB = Branch::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Kantor Surabaya',
            'address' => 'Jl. Pemuda No. 10, Surabaya',
            'latitude' => -7.25750000,
            'longitude' => 112.75210000,
            'radius_meters' => 100,
        ]);

        $this->shiftB = Shift::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Shift Pagi B',
            'start_time' => '09:00:00',
            'end_time' => '18:00:00',
            'late_tolerance_minutes' => 10,
        ]);

        $this->userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Siti Rahma',
            'email' => 'siti@maju.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $this->userEmpB->id_users,
            'id_branches' => $this->branchB->id_branches,
            'nik' => 'EMP-B-001',
            'gender' => 'female',
            'hire_date' => '2024-01-01',
        ]);
    }

    public function test_unauthenticated_user_cannot_access_attendance_endpoints(): void
    {
        $this->getJson('/api/v1/attendance/today')->assertStatus(401);
        $this->postJson('/api/v1/attendance/clock-in', [])->assertStatus(401);
        $this->postJson('/api/v1/attendance/clock-out', [])->assertStatus(401);
        $this->getJson('/api/v1/attendance/history')->assertStatus(401);
        $this->getJson('/api/v1/attendance/recap')->assertStatus(401);
    }

    public function test_today_endpoint_returns_fallback_company_shift_and_branch(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->getJson('/api/v1/attendance/today');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.branch.name', 'Kantor Pusat Jakarta')
            ->assertJsonPath('data.shift.name', 'Shift Normal Pagi')
            ->assertJsonPath('data.attendance', null);
    }

    public function test_today_endpoint_returns_assigned_employee_shift(): void
    {
        $today = Carbon::today()->toDateString();

        $customShift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Khusus Siang',
            'start_time' => '13:00:00',
            'end_time' => '21:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        EmployeeShift::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $customShift->id_shifts,
            'date' => $today,
        ]);

        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->getJson('/api/v1/attendance/today');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.shift.name', 'Shift Khusus Siang')
            ->assertJsonPath('data.shift.id_shifts', $customShift->id_shifts);
    }

    public function test_today_endpoint_fails_if_user_has_no_employee_profile(): void
    {
        Sanctum::actingAs($this->ownerA, ['*']);

        $response = $this->getJson('/api/v1/attendance/today');

        $response->assertStatus(404)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Profil karyawan tidak ditemukan.');
    }

    public function test_clock_in_within_radius_success(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // Exactly at branch location
        $file = UploadedFile::fake()->image('selfie.jpg');

        $response = $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => $file,
            'device_time' => '2026-10-01 08:05:00',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Clock-in berhasil.')
            ->assertJsonPath('data.status', 'on_time')
            ->assertJsonPath('data.late_duration_minutes', 0)
            ->assertJsonPath('data.clock_in_distance_meters', 0);

        $attendance = Attendance::where('id_employees', $this->employeeA->id_employees)
            ->where('date', '2026-10-01')
            ->first();

        $this->assertNotNull($attendance);
        $this->assertEquals('08:05:00', $attendance->clock_in_time);
        $this->assertEquals('on_time', $attendance->status);
        $this->assertEquals(0, $attendance->late_duration_minutes);
        Storage::disk('public')->assertExists($attendance->clock_in_photo_path);
    }

    public function test_clock_in_outside_radius_fails_422_with_distance_message(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // ~10km away from branchA (-6.2088, 106.8456)
        $file = UploadedFile::fake()->image('selfie.jpg');

        $response = $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.30000000,
            'longitude' => 106.84560000,
            'photo' => $file,
            'device_time' => '2026-10-01 08:00:00',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        $message = $response->json('message');
        $this->assertStringContainsString('melebihi batas radius kantor (100m).', $message);
        $this->assertMatchesRegularExpression('/Jarak perangkat \d+m, melebihi batas radius kantor \(100m\)\./', $message);

        $this->assertDatabaseMissing('attendances', [
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-01',
        ]);
    }

    public function test_clock_in_validation_fails_when_fields_are_missing(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->postJson('/api/v1/attendance/clock-in', []);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonValidationErrors(['latitude', 'longitude', 'photo']);
    }

    public function test_clock_in_late_tolerance_on_time(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // Shift starts 08:00:00 with 15 min tolerance (08:15:00 cutoff)
        // Clock in at exactly 08:15:00 -> on_time
        $response = $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('selfie.jpg'),
            'device_time' => '2026-10-02 08:15:00',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'on_time')
            ->assertJsonPath('data.late_duration_minutes', 0);
    }

    public function test_clock_in_late_tolerance_late(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // Shift starts 08:00:00 with 15 min tolerance
        // Clock in at 08:25:00 -> late by 25 minutes
        $response = $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('selfie.jpg'),
            'device_time' => '2026-10-03 08:25:00',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'late')
            ->assertJsonPath('data.late_duration_minutes', 25);

        $this->assertDatabaseHas('attendances', [
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-03',
            'status' => 'late',
            'late_duration_minutes' => 25,
        ]);
    }

    public function test_cannot_double_clock_in_on_same_day(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // First clock-in
        $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('selfie1.jpg'),
            'device_time' => '2026-10-04 08:00:00',
        ])->assertStatus(201);

        // Second clock-in on same day
        $response = $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('selfie2.jpg'),
            'device_time' => '2026-10-04 08:05:00',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Anda sudah melakukan clock-in hari ini.');
    }

    public function test_clock_in_fails_if_employee_has_no_branch(): void
    {
        Storage::fake('public');

        $userWithoutBranch = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'No Branch User',
            'email' => 'nobranch@nusantara.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userWithoutBranch->id_users,
            'id_branches' => $this->branchB->id_branches,
            'nik' => 'EMP-NOBRANCH',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($userWithoutBranch, ['*']);

        $response = $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('selfie.jpg'),
            'device_time' => '2026-10-01 08:00:00',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Karyawan belum memiliki kantor cabang penugasan.');
    }

    public function test_clock_out_before_clock_in_fails_422(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->postJson('/api/v1/attendance/clock-out', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'device_time' => '2026-10-05 17:00:00',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Presensi clock-in belum ditemukan untuk hari ini.');
    }

    public function test_clock_out_within_radius_success(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // First clock in
        $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('in.jpg'),
            'device_time' => '2026-10-06 08:00:00',
        ])->assertStatus(201);

        // Then clock out at 17:05:00 (on time, shift ends 17:00)
        $outPhoto = UploadedFile::fake()->image('out.jpg');
        $response = $this->postJson('/api/v1/attendance/clock-out', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => $outPhoto,
            'device_time' => '2026-10-06 17:05:00',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Clock-out berhasil.')
            ->assertJsonPath('data.early_leave_minutes', 0);

        $attendance = Attendance::where('id_employees', $this->employeeA->id_employees)
            ->where('date', '2026-10-06')
            ->first();

        $this->assertEquals('17:05:00', $attendance->clock_out_time);
        $this->assertEquals(0, $attendance->early_leave_minutes);
        $this->assertNotNull($attendance->clock_out_photo_path);
        Storage::disk('public')->assertExists($attendance->clock_out_photo_path);
    }

    public function test_clock_out_outside_radius_fails_422(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // Clock in
        $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('in.jpg'),
            'device_time' => '2026-10-07 08:00:00',
        ])->assertStatus(201);

        // Clock out from far away
        $response = $this->postJson('/api/v1/attendance/clock-out', [
            'latitude' => -6.35000000,
            'longitude' => 106.84560000,
            'device_time' => '2026-10-07 17:00:00',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertStringContainsString('melebihi batas radius kantor (100m).', $response->json('message'));
    }

    public function test_cannot_double_clock_out_on_same_day(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('in.jpg'),
            'device_time' => '2026-10-08 08:00:00',
        ])->assertStatus(201);

        $this->postJson('/api/v1/attendance/clock-out', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'device_time' => '2026-10-08 17:00:00',
        ])->assertStatus(200);

        // Second clock out
        $response = $this->postJson('/api/v1/attendance/clock-out', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'device_time' => '2026-10-08 17:10:00',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Anda sudah melakukan clock-out hari ini.');
    }

    public function test_clock_out_calculates_early_leave_minutes(): void
    {
        Storage::fake('public');
        Sanctum::actingAs($this->userEmpA, ['*']);

        // Shift ends at 17:00:00
        $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'photo' => UploadedFile::fake()->image('in.jpg'),
            'device_time' => '2026-10-09 08:00:00',
        ])->assertStatus(201);

        // Clock out at 16:30:00 (30 minutes early)
        $response = $this->postJson('/api/v1/attendance/clock-out', [
            'latitude' => -6.20880000,
            'longitude' => 106.84560000,
            'device_time' => '2026-10-09 16:30:00',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.early_leave_minutes', 30);

        $this->assertDatabaseHas('attendances', [
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-09',
            'early_leave_minutes' => 30,
        ]);
    }

    public function test_can_get_attendance_history_paginated_and_filtered(): void
    {
        // Seed 3 attendances for Employee A
        Attendance::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-09-28',
            'clock_in_time' => '08:00:00',
            'status' => 'on_time',
        ]);
        Attendance::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-01',
            'clock_in_time' => '08:05:00',
            'status' => 'on_time',
        ]);
        Attendance::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-02',
            'clock_in_time' => '08:30:00',
            'status' => 'late',
            'late_duration_minutes' => 30,
        ]);

        // Seed 1 attendance for Employee B (other company)
        Attendance::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'date' => '2026-10-01',
            'clock_in_time' => '09:00:00',
            'status' => 'on_time',
        ]);

        Sanctum::actingAs($this->userEmpA, ['*']);

        // Default query
        $response = $this->getJson('/api/v1/attendance/history');
        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(3, 'data.data');

        // Filter by month
        $responseMonth = $this->getJson('/api/v1/attendance/history?month=2026-10');
        $responseMonth->assertStatus(200)
            ->assertJsonCount(2, 'data.data');

        // Filter by date range
        $responseRange = $this->getJson('/api/v1/attendance/history?start_date=2026-10-02&end_date=2026-10-05');
        $responseRange->assertStatus(200)
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.date', '2026-10-02');
    }

    public function test_recap_endpoint_accessible_by_owner_hr_and_manager(): void
    {
        Attendance::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-01',
            'clock_in_time' => '08:00:00',
            'status' => 'on_time',
        ]);

        // Owner
        Sanctum::actingAs($this->ownerA, ['*']);
        $resOwner = $this->getJson('/api/v1/attendance/recap?date=2026-10-01');
        $resOwner->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total_present', 1)
            ->assertJsonPath('data.on_time', 1);

        // HR
        Sanctum::actingAs($this->hrA, ['*']);
        $resHr = $this->getJson('/api/v1/attendance/recap?date=2026-10-01');
        $resHr->assertStatus(200)
            ->assertJsonPath('success', true);

        // Manager
        Sanctum::actingAs($this->managerA, ['*']);
        $resManager = $this->getJson('/api/v1/attendance/recap?date=2026-10-01');
        $resManager->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_recap_endpoint_forbidden_for_regular_employee(): void
    {
        Sanctum::actingAs($this->userEmpA, ['*']);

        $response = $this->getJson('/api/v1/attendance/recap');

        $response->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Akses ditolak. Anda tidak memiliki izin melihat rekap presensi.');
    }

    public function test_recap_does_not_leak_other_company_attendances(): void
    {
        Attendance::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-01',
            'clock_in_time' => '08:00:00',
            'status' => 'on_time',
        ]);

        Attendance::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'date' => '2026-10-01',
            'clock_in_time' => '09:00:00',
            'status' => 'on_time',
        ]);

        Sanctum::actingAs($this->ownerA, ['*']);

        $response = $this->getJson('/api/v1/attendance/recap?date=2026-10-01');

        $response->assertStatus(200)
            ->assertJsonPath('data.total_present', 1);

        $this->assertEquals(1, count($response->json('data.attendances')));
        $this->assertEquals($this->employeeA->id_employees, $response->json('data.attendances.0.id_employees'));
    }
}
