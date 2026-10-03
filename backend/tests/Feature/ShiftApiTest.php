<?php

namespace Tests\Feature;

use App\Models\Branch;
use App\Models\Company;
use App\Models\Employee;
use App\Models\EmployeeShift;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ShiftApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $userA;
    protected User $userB;
    protected Employee $employeeA;
    protected Employee $employeeB;
    protected Branch $branchA;
    protected Branch $branchB;

    protected function setUp(): void
    {
        parent::setUp();

        // Setup Company A
        $this->companyA = Company::create([
            'name' => 'Company A',
            'slug' => 'company-a',
            'email' => 'comp-a@test.com',
            'subscription_status' => 'active',
        ]);

        $this->userA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Owner Company A',
            'email' => 'owner@companya.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->branchA = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Branch Jakarta',
            'address' => 'Jl. Sudirman No 1',
            'latitude' => -6.2088,
            'longitude' => 106.8456,
            'radius_meters' => 100,
        ]);

        $userEmpA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Employee A',
            'email' => 'empa@companya.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeA = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userEmpA->id_users,
            'id_branches' => $this->branchA->id_branches,
            'nik' => 'NIK-001',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        // Setup Company B
        $this->companyB = Company::create([
            'name' => 'Company B',
            'slug' => 'company-b',
            'email' => 'comp-b@test.com',
            'subscription_status' => 'active',
        ]);

        $this->userB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Owner Company B',
            'email' => 'owner@companyb.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->branchB = Branch::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Branch Surabaya',
            'address' => 'Jl. Pemuda No 2',
            'latitude' => -7.2575,
            'longitude' => 112.7521,
            'radius_meters' => 100,
        ]);

        $userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Employee B',
            'email' => 'empb@companyb.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $userEmpB->id_users,
            'id_branches' => $this->branchB->id_branches,
            'nik' => 'NIK-002',
            'gender' => 'female',
            'hire_date' => '2024-01-01',
        ]);
    }

    public function test_unauthenticated_user_cannot_access_shifts(): void
    {
        $response = $this->getJson('/api/v1/shifts');

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthenticated.',
                'data' => null,
            ]);
    }

    public function test_can_list_shifts_for_current_company_only(): void
    {
        Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Pagi A',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        Shift::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Shift Pagi B',
            'start_time' => '09:00:00',
            'end_time' => '18:00:00',
            'late_tolerance_minutes' => 10,
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->getJson('/api/v1/shifts');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Shift Pagi A');
    }

    public function test_can_create_shift_with_valid_data(): void
    {
        Sanctum::actingAs($this->userA, ['*']);

        $payload = [
            'name' => 'Shift Normal',
            'start_time' => '08:30',
            'end_time' => '17:30',
            'late_tolerance_minutes' => 20,
        ];

        $response = $this->postJson('/api/v1/shifts', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Shift Normal')
            ->assertJsonPath('data.late_tolerance_minutes', 20);

        $this->assertDatabaseHas('shifts', [
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Normal',
            'late_tolerance_minutes' => 20,
        ]);
    }

    public function test_cannot_create_shift_with_invalid_data(): void
    {
        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->postJson('/api/v1/shifts', [
            'name' => '',
            'start_time' => 'invalid-time',
            'end_time' => '',
            'late_tolerance_minutes' => -5,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonValidationErrors(['name', 'start_time', 'end_time', 'late_tolerance_minutes']);
    }

    public function test_can_get_shift_detail(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Khusus',
            'start_time' => '13:00:00',
            'end_time' => '21:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->getJson("/api/v1/shifts/{$shift->id_shifts}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Shift Khusus')
            ->assertJsonPath('data.id_shifts', $shift->id_shifts);
    }

    public function test_cannot_get_shift_from_another_company(): void
    {
        $shiftB = Shift::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Shift Milik B',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->getJson("/api/v1/shifts/{$shiftB->id_shifts}");

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_can_update_shift(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Awal',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'late_tolerance_minutes' => 10,
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->putJson("/api/v1/shifts/{$shift->id_shifts}", [
            'name' => 'Shift Diperbarui',
            'start_time' => '08:30:00',
            'end_time' => '17:30:00',
            'late_tolerance_minutes' => 15,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Shift Diperbarui');

        $this->assertDatabaseHas('shifts', [
            'id_shifts' => $shift->id_shifts,
            'name' => 'Shift Diperbarui',
            'late_tolerance_minutes' => 15,
        ]);
    }

    public function test_cannot_update_shift_belonging_to_another_company(): void
    {
        $shiftB = Shift::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Shift Milik B',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->putJson("/api/v1/shifts/{$shiftB->id_shifts}", [
            'name' => 'Shift Diubah Oleh A',
        ]);

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_can_delete_shift_not_assigned_to_employee(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Hapus',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->deleteJson("/api/v1/shifts/{$shift->id_shifts}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('shifts', [
            'id_shifts' => $shift->id_shifts,
        ]);
    }

    public function test_cannot_delete_shift_currently_assigned_to_employee(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Digunakan',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        EmployeeShift::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift->id_shifts,
            'date' => '2026-10-05',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->deleteJson("/api/v1/shifts/{$shift->id_shifts}");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('shifts', [
            'id_shifts' => $shift->id_shifts,
        ]);
    }

    public function test_can_assign_shift_single_date(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Pagi',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift->id_shifts,
            'date' => '2026-10-10',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('employee_shifts', [
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift->id_shifts,
            'date' => '2026-10-10',
        ]);
    }

    public function test_can_assign_shift_multiple_dates(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Pagi',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift->id_shifts,
            'dates' => ['2026-10-11', '2026-10-12'],
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('employee_shifts', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift->id_shifts,
            'date' => '2026-10-11',
        ]);
        $this->assertDatabaseHas('employee_shifts', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift->id_shifts,
            'date' => '2026-10-12',
        ]);
    }

    public function test_can_assign_shift_date_range(): void
    {
        $shift = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Pagi',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift->id_shifts,
            'start_date' => '2026-10-15',
            'end_date' => '2026-10-17',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('employee_shifts', [
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-15',
        ]);
        $this->assertDatabaseHas('employee_shifts', [
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-16',
        ]);
        $this->assertDatabaseHas('employee_shifts', [
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-17',
        ]);
    }

    public function test_reassigning_shift_on_same_date_updates_without_duplicate_error(): void
    {
        $shift1 = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Pagi',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        $shift2 = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Siang',
            'start_time' => '13:00:00',
            'end_time' => '21:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        // First assignment
        $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift1->id_shifts,
            'date' => '2026-10-20',
        ])->assertStatus(200);

        // Second assignment with new shift
        $response = $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift2->id_shifts,
            'date' => '2026-10-20',
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('employee_shifts', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shift2->id_shifts,
            'date' => '2026-10-20',
        ]);

        $this->assertEquals(1, EmployeeShift::where('id_employees', $this->employeeA->id_employees)->where('date', '2026-10-20')->count());
    }

    public function test_cannot_assign_shift_to_employee_of_another_company(): void
    {
        $shiftA = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Pagi',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        // Try assigning Company A shift to Company B employee
        $response = $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $this->employeeB->id_employees,
            'id_shifts' => $shiftA->id_shifts,
            'date' => '2026-10-25',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['id_employees']);
    }

    public function test_cannot_assign_shift_belonging_to_another_company(): void
    {
        $shiftB = Shift::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Shift Milik B',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        // Try assigning Company B shift to Company A employee
        $response = $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $this->employeeA->id_employees,
            'id_shifts' => $shiftB->id_shifts,
            'date' => '2026-10-25',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['id_shifts']);
    }
}
