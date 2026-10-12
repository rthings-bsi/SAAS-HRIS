<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\Employee;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EmployeeApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $userA;
    protected User $userB;
    protected Shift $shiftA;
    protected Shift $shiftB;

    protected function setUp(): void
    {
        parent::setUp();

        // Setup Company A
        $this->companyA = Company::create([
            'name' => 'Company A',
            'slug' => 'company-a',
            'email' => 'comp-a@test.com',
            'subscription_status' => 'active',
            'latitude' => -6.2088,
            'longitude' => 106.8456,
            'radius_meters' => 100,
        ]);

        $this->userA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Owner Company A',
            'email' => 'owner@companya.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->shiftA = Shift::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Shift Reguler A',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'late_tolerance_minutes' => 15,
        ]);

        // Setup Company B
        $this->companyB = Company::create([
            'name' => 'Company B',
            'slug' => 'company-b',
            'email' => 'comp-b@test.com',
            'subscription_status' => 'active',
            'latitude' => -7.2575,
            'longitude' => 112.7521,
            'radius_meters' => 100,
        ]);

        $this->userB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Owner Company B',
            'email' => 'owner@companyb.com',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->shiftB = Shift::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Shift Reguler B',
            'start_time' => '09:00:00',
            'end_time' => '18:00:00',
            'late_tolerance_minutes' => 10,
        ]);
    }

    public function test_unauthenticated_user_cannot_access_employees(): void
    {
        $response = $this->getJson('/api/v1/employees');

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthenticated.',
                'data' => null,
            ]);
    }

    public function test_can_list_employees_for_current_company_with_relations(): void
    {
        $userEmpA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Budi Santoso',
            'email' => 'budi@companya.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userEmpA->id_users,
            'department_name' => 'IT Department',
            'job_position_name' => 'Backend Developer',
            'id_shifts' => $this->shiftA->id_shifts,
            'nik' => 'EMP-001',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
            'basic_salary' => 8000000,
        ]);

        // Employee Company B
        $userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Siti Aminah',
            'email' => 'siti@companyb.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $userEmpB->id_users,
            'department_name' => 'HR Department B',
            'job_position_name' => 'Recruiter B',
            'id_shifts' => $this->shiftB->id_shifts,
            'nik' => 'EMP-B-001',
            'gender' => 'female',
            'hire_date' => '2024-02-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->getJson('/api/v1/employees');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.nik', 'EMP-001')
            ->assertJsonPath('data.0.user.name', 'Budi Santoso')
            ->assertJsonPath('data.0.branch.name', 'Company A')
            ->assertJsonPath('data.0.department.name', 'IT Department')
            ->assertJsonPath('data.0.job_position.name', 'Backend Developer');
    }

    public function test_can_create_employee_with_user_in_transaction(): void
    {
        Sanctum::actingAs($this->userA, ['*']);

        $payload = [
            'name' => 'Ahmad Dani',
            'email' => 'ahmad.dani@companya.com',
            'password' => 'secret1234',
            'department_name' => 'Teknologi Informasi',
            'job_position_name' => 'Software Engineer',
            'id_shifts' => $this->shiftA->id_shifts,
            'nik' => 'NIK-1001',
            'phone' => '081234567890',
            'gender' => 'male',
            'birth_date' => '1995-05-15',
            'hire_date' => '2024-03-01',
            'employment_status' => 'permanent',
            'basic_salary' => 9500000,
            'allowance_fixed' => 1500000,
            'bank_name' => 'BCA',
            'bank_account_number' => '1234567890',
            'bank_account_holder' => 'Ahmad Dani',
        ];

        $response = $this->postJson('/api/v1/employees', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nik', 'NIK-1001')
            ->assertJsonPath('data.user.name', 'Ahmad Dani')
            ->assertJsonPath('data.user.email', 'ahmad.dani@companya.com')
            ->assertJsonPath('data.branch.name', 'Company A')
            ->assertJsonPath('data.department.name', 'Teknologi Informasi')
            ->assertJsonPath('data.job_position.name', 'Software Engineer');

        // Verify user in DB
        $user = User::where('email', 'ahmad.dani@companya.com')->first();
        $this->assertNotNull($user);
        $this->assertEquals($this->companyA->id_companies, $user->id_companies);
        $this->assertEquals('employee', $user->role);
        $this->assertTrue($user->is_active);
        $this->assertTrue(Hash::check('secret1234', $user->password));

        // Verify employee in DB
        $this->assertDatabaseHas('employees', [
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $user->id_users,
            'nik' => 'NIK-1001',
            'gender' => 'male',
            'basic_salary' => 9500000,
            'bank_name' => 'BCA',
        ]);
    }

    public function test_can_create_employee_with_optional_fields_omitted(): void
    {
        Sanctum::actingAs($this->userA, ['*']);

        $payload = [
            'name' => 'Rina Nose',
            'email' => 'rina@companya.com',
            'password' => 'secret1234',
            'nik' => 'NIK-MINIMAL',
            'gender' => 'female',
            'hire_date' => '2024-04-01',
        ];

        $response = $this->postJson('/api/v1/employees', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nik', 'NIK-MINIMAL')
            ->assertJsonPath('data.employment_status', 'contract');

        $this->assertDatabaseHas('employees', [
            'id_companies' => $this->companyA->id_companies,
            'nik' => 'NIK-MINIMAL',
            'department_name' => null,
            'job_position_name' => null,
        ]);
    }

    public function test_cannot_create_employee_with_existing_email(): void
    {
        User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Existing User',
            'email' => 'existing@companya.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->postJson('/api/v1/employees', [
            'name' => 'New User Duplicate Email',
            'email' => 'existing@companya.com',
            'password' => 'secret1234',
            'nik' => 'NIK-DUP',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_cannot_create_employee_with_invalid_data(): void
    {
        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->postJson('/api/v1/employees', [
            'name' => '',
            'email' => 'not-an-email',
            'password' => 'short',
            'nik' => '',
            'gender' => 'unknown',
            'hire_date' => 'invalid-date',
            'basic_salary' => -100,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors([
                'name',
                'email',
                'password',
                'nik',
                'gender',
                'hire_date',
                'basic_salary',
            ]);
    }

    public function test_cannot_create_employee_with_invalid_shift(): void
    {
        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->postJson('/api/v1/employees', [
            'name' => 'Invalid Shift Worker',
            'email' => 'invalidshift@companya.com',
            'password' => 'secret1234',
            'id_shifts' => 99999,
            'nik' => 'NIK-INVALID-SHIFT',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['id_shifts']);
    }

    public function test_can_get_employee_detail_with_relations(): void
    {
        $userEmp = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Joko Anwar',
            'email' => 'joko@companya.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
        ]);

        $emp = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userEmp->id_users,
            'department_name' => 'IT Department',
            'job_position_name' => 'Backend Developer',
            'id_shifts' => $this->shiftA->id_shifts,
            'nik' => 'EMP-JOKO',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->getJson("/api/v1/employees/{$emp->id_employees}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nik', 'EMP-JOKO')
            ->assertJsonPath('data.user.name', 'Joko Anwar')
            ->assertJsonPath('data.branch.name', 'Company A')
            ->assertJsonPath('data.department.name', 'IT Department')
            ->assertJsonPath('data.job_position.name', 'Backend Developer');
    }

    public function test_cannot_get_employee_from_another_company(): void
    {
        $userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Emp B User',
            'email' => 'empb_secret@companyb.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
        ]);

        $empB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $userEmpB->id_users,
            'department_name' => 'HR',
            'nik' => 'EMP-B-SECRET',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->getJson("/api/v1/employees/{$empB->id_employees}");

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_can_update_employee_profile_and_associated_user(): void
    {
        $userEmp = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Nama Lama',
            'email' => 'lama@companya.com',
            'password' => Hash::make('oldpassword'),
            'role' => 'employee',
        ]);

        $emp = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userEmp->id_users,
            'nik' => 'NIK-OLD',
            'phone' => '0811111111',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
            'basic_salary' => 5000000,
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->putJson("/api/v1/employees/{$emp->id_employees}", [
            'name' => 'Nama Baru',
            'email' => 'baru@companya.com',
            'nik' => 'NIK-NEW',
            'phone' => '0822222222',
            'basic_salary' => 7000000,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.name', 'Nama Baru')
            ->assertJsonPath('data.user.email', 'baru@companya.com')
            ->assertJsonPath('data.nik', 'NIK-NEW');

        // Check DB updates
        $this->assertDatabaseHas('users', [
            'id_users' => $userEmp->id_users,
            'name' => 'Nama Baru',
            'email' => 'baru@companya.com',
        ]);

        $this->assertDatabaseHas('employees', [
            'id_employees' => $emp->id_employees,
            'nik' => 'NIK-NEW',
            'phone' => '0822222222',
            'basic_salary' => 7000000,
        ]);
    }

    public function test_can_update_employee_keeping_same_email(): void
    {
        $userEmp = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Tetap Email',
            'email' => 'tetap@companya.com',
            'password' => Hash::make('oldpassword'),
            'role' => 'employee',
        ]);

        $emp = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userEmp->id_users,
            'nik' => 'NIK-TETAP',
            'gender' => 'female',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->putJson("/api/v1/employees/{$emp->id_employees}", [
            'name' => 'Nama Berubah',
            'email' => 'tetap@companya.com',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.name', 'Nama Berubah')
            ->assertJsonPath('data.user.email', 'tetap@companya.com');
    }

    public function test_cannot_update_employee_with_email_already_taken_by_another_user(): void
    {
        User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Other Person',
            'email' => 'other@companya.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
        ]);

        $userEmp = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'My Person',
            'email' => 'myperson@companya.com',
            'password' => Hash::make('password123'),
            'role' => 'employee',
        ]);

        $emp = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userEmp->id_users,
            'nik' => 'NIK-MY',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->putJson("/api/v1/employees/{$emp->id_employees}", [
            'email' => 'other@companya.com',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_cannot_update_employee_from_another_company(): void
    {
        $userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'User B Target',
            'email' => 'targetb@companyb.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
        ]);

        $empB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $userEmpB->id_users,
            'nik' => 'EMP-B-TGT',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->putJson("/api/v1/employees/{$empB->id_employees}", [
            'name' => 'Hacked Name',
        ]);

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_can_delete_employee_and_cascades_to_associated_user(): void
    {
        $userEmp = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Delete Me',
            'email' => 'deleteme@companya.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
        ]);

        $emp = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $userEmp->id_users,
            'nik' => 'EMP-DEL',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->deleteJson("/api/v1/employees/{$emp->id_employees}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('employees', [
            'id_employees' => $emp->id_employees,
        ]);

        $this->assertDatabaseMissing('users', [
            'id_users' => $userEmp->id_users,
        ]);
    }

    public function test_cannot_delete_employee_from_another_company(): void
    {
        $userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Delete Protected B',
            'email' => 'protb@companyb.com',
            'password' => Hash::make('secret123'),
            'role' => 'employee',
        ]);

        $empB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $userEmpB->id_users,
            'nik' => 'EMP-B-PROT',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
        ]);

        Sanctum::actingAs($this->userA, ['*']);

        $response = $this->deleteJson("/api/v1/employees/{$empB->id_employees}");

        $response->assertStatus(404)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('employees', [
            'id_employees' => $empB->id_employees,
        ]);

        $this->assertDatabaseHas('users', [
            'id_users' => $userEmpB->id_users,
        ]);
    }
}
