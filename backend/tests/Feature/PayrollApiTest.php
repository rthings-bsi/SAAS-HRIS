<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Company;
use App\Models\Employee;
use App\Models\PayrollSlip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PayrollApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $ownerA;
    protected User $hrA;
    protected User $userEmpA;
    protected Employee $employeeA;

    protected User $ownerB;
    protected User $userEmpB;
    protected Employee $employeeB;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');

        // Company A
        $this->companyA = Company::create([
            'name' => 'PT Nusantara Sejahtera',
            'slug' => 'pt-nusantara-sejahtera',
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

        $this->userEmpA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Budi Staff',
            'email' => 'budi@nusantara.test',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeA = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->userEmpA->id_users,
            'nik' => 'EMP001',
            'department_name' => 'Teknologi Informasi',
            'job_position_name' => 'Software Engineer',
            'gender' => 'male',
            'hire_date' => '2024-01-01',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'employment_status' => 'permanent',
        ]);

        // Company B
        $this->companyB = Company::create([
            'name' => 'PT Maju Makmur Bersama',
            'slug' => 'pt-maju-makmur-bersama',
            'email' => 'info@majumakmur.test',
            'subscription_status' => 'active',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
            'radius_meters' => 100,
        ]);

        $this->ownerB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Owner Maju',
            'email' => 'owner@majumakmur.test',
            'password' => Hash::make('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->userEmpB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Siti Staff Maju',
            'email' => 'siti@majumakmur.test',
            'password' => Hash::make('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);

        $this->employeeB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $this->userEmpB->id_users,
            'nik' => 'EMP999',
            'department_name' => 'Keuangan',
            'job_position_name' => 'Staff Keuangan',
            'gender' => 'female',
            'hire_date' => '2024-01-01',
            'basic_salary' => 6000000,
            'allowance_fixed' => 500000,
            'employment_status' => 'permanent',
        ]);
    }

    public function test_unauthenticated_user_cannot_access_payroll_endpoints(): void
    {
        $this->getJson('/api/v1/payroll/periods')->assertStatus(401);
        $this->getJson('/api/v1/payroll/my-slips')->assertStatus(401);
    }

    public function test_employee_cannot_access_admin_payroll_period_endpoints(): void
    {
        Sanctum::actingAs($this->userEmpA);

        $this->getJson('/api/v1/payroll/periods')->assertStatus(403);
        $this->postJson('/api/v1/payroll/periods', [
            'name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
        ])->assertStatus(403);
    }

    public function test_hr_or_owner_can_create_payroll_period(): void
    {
        Sanctum::actingAs($this->hrA);

        $response = $this->postJson('/api/v1/payroll/periods', [
            'name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Periode penggajian berhasil dibuka.',
                'data' => [
                    'name' => 'Oktober 2026',
                    'status' => 'draft',
                ],
            ]);

        $this->assertDatabaseHas('payroll_slips', [
            'id_companies' => $this->companyA->id_companies,
            'period_name' => 'Oktober 2026',
            'status' => 'draft',
        ]);
    }

    public function test_payroll_period_validation_rules_check(): void
    {
        Sanctum::actingAs($this->ownerA);

        $response = $this->postJson('/api/v1/payroll/periods', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'start_date', 'end_date', 'payment_date']);
    }

    public function test_hr_or_owner_can_list_payroll_periods_scoped_to_tenant(): void
    {
        PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'September 2026',
            'start_date' => '2026-09-01',
            'end_date' => '2026-09-30',
            'payment_date' => '2026-10-01',
            'status' => 'finalized',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        PayrollSlip::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'period_name' => 'September 2026 Maju',
            'start_date' => '2026-09-01',
            'end_date' => '2026-09-30',
            'payment_date' => '2026-10-01',
            'status' => 'draft',
            'basic_salary' => 6000000,
            'allowance_fixed' => 500000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 6500000,
        ]);

        Sanctum::actingAs($this->ownerA);

        $response = $this->getJson('/api/v1/payroll/periods');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment(['name' => 'September 2026'])
            ->assertJsonMissing(['name' => 'September 2026 Maju']);
    }

    public function test_hr_can_calculate_payroll_for_a_period(): void
    {
        $slip = PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'draft',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->postJson("/api/v1/payroll/periods/{$slip->id_payroll_slips}/calculate");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slips_calculated' => 1,
                ],
            ]);

        $this->assertDatabaseHas('payroll_slips', [
            'id_payroll_slips' => $slip->id_payroll_slips,
            'status' => 'calculated',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
        ]);
    }

    public function test_payroll_calculation_correctly_computes_deductions_from_attendance(): void
    {
        $slip = PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'draft',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        // Buat data absensi: hadir 20 hari dengan terlambat 30 menit
        Attendance::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'date' => '2026-10-02',
            'status' => 'late',
            'late_duration_minutes' => 30,
        ]);

        Sanctum::actingAs($this->ownerA);

        $this->postJson("/api/v1/payroll/periods/{$slip->id_payroll_slips}/calculate")->assertStatus(200);

        $calculatedSlip = PayrollSlip::where('period_name', 'Oktober 2026')
            ->where('id_employees', $this->employeeA->id_employees)
            ->first();

        $this->assertNotNull($calculatedSlip);
        // Potongan keterlambatan 30 menit * Rp 1.000 = Rp 30.000
        $this->assertEquals(30000, (float) $calculatedSlip->deduction_late);
        $this->assertGreaterThan(0, (float) $calculatedSlip->deduction_absence);
    }

    public function test_hr_can_review_slips_for_a_period(): void
    {
        $slip = PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'draft',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->getJson("/api/v1/payroll/periods/{$slip->id_payroll_slips}/slips");

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment([
                'name' => 'Budi Staff',
                'net_salary' => 9000000,
            ]);
    }

    public function test_hr_can_finalize_payroll_period_and_generate_pdf(): void
    {
        $slip = PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'calculated',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->postJson("/api/v1/payroll/periods/{$slip->id_payroll_slips}/finalize");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slips_finalized' => 1,
                ],
            ]);

        $this->assertDatabaseHas('payroll_slips', [
            'id_payroll_slips' => $slip->id_payroll_slips,
            'status' => 'finalized',
        ]);

        $finalizedSlip = PayrollSlip::find($slip->id_payroll_slips);
        $this->assertNotEmpty($finalizedSlip->pdf_path);
        $this->assertTrue(Storage::disk('public')->exists($finalizedSlip->pdf_path));
    }

    public function test_cannot_recalculate_already_finalized_payroll_period(): void
    {
        $slip = PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'finalized',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        Sanctum::actingAs($this->hrA);

        $response = $this->postJson("/api/v1/payroll/periods/{$slip->id_payroll_slips}/calculate");

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_employee_can_view_their_own_payroll_slips(): void
    {
        PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'finalized',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        Sanctum::actingAs($this->userEmpA);

        $response = $this->getJson('/api/v1/payroll/my-slips');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment([
                'period_name' => 'Oktober 2026',
                'net_salary' => 9000000,
            ]);
    }

    public function test_employee_can_download_their_own_payroll_slip_pdf(): void
    {
        $slip = PayrollSlip::create([
            'id_companies' => $this->companyA->id_companies,
            'id_employees' => $this->employeeA->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'finalized',
            'basic_salary' => 8000000,
            'allowance_fixed' => 1000000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 9000000,
        ]);

        Sanctum::actingAs($this->userEmpA);

        $response = $this->get("/api/v1/payroll/my-slips/{$slip->id_payroll_slips}/download");

        $response->assertStatus(200)
            ->assertHeader('content-type', 'application/pdf');
    }

    public function test_employee_cannot_download_another_employees_slip(): void
    {
        $slipB = PayrollSlip::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'period_name' => 'Oktober 2026',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'finalized',
            'basic_salary' => 6000000,
            'allowance_fixed' => 500000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 6500000,
        ]);

        Sanctum::actingAs($this->userEmpA);

        // Employee A tries to download Employee B's slip
        $this->getJson("/api/v1/payroll/my-slips/{$slipB->id_payroll_slips}/download")->assertStatus(404);
    }

    public function test_tenant_isolation_tenant_a_cannot_view_or_calculate_tenant_b_payroll(): void
    {
        $slipB = PayrollSlip::create([
            'id_companies' => $this->companyB->id_companies,
            'id_employees' => $this->employeeB->id_employees,
            'period_name' => 'Oktober 2026 B',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
            'status' => 'draft',
            'basic_salary' => 6000000,
            'allowance_fixed' => 500000,
            'overtime_pay' => 0,
            'deduction_late' => 0,
            'deduction_absence' => 0,
            'deduction_other' => 0,
            'net_salary' => 6500000,
        ]);

        Sanctum::actingAs($this->ownerA);

        $this->getJson("/api/v1/payroll/periods/{$slipB->id_payroll_slips}")->assertStatus(404);
        $this->postJson("/api/v1/payroll/periods/{$slipB->id_payroll_slips}/calculate")->assertStatus(404);
        $this->postJson("/api/v1/payroll/periods/{$slipB->id_payroll_slips}/finalize")->assertStatus(404);
    }

    public function test_cannot_create_payroll_period_with_duplicate_name_or_overlapping_dates(): void
    {
        Sanctum::actingAs($this->hrA);

        // First creation succeeds
        $res1 = $this->postJson('/api/v1/payroll/periods', [
            'name' => 'Payroll Q1 2026',
            'start_date' => '2026-01-01',
            'end_date' => '2026-03-31',
            'payment_date' => '2026-04-01',
        ]);
        $res1->assertStatus(201);

        // Attempt duplicate name fails 422
        $res2 = $this->postJson('/api/v1/payroll/periods', [
            'name' => 'payroll q1 2026',
            'start_date' => '2026-04-01',
            'end_date' => '2026-06-30',
            'payment_date' => '2026-07-01',
        ]);
        $res2->assertStatus(422)
            ->assertJsonPath('success', false);

        // Attempt overlapping dates fails 422
        $res3 = $this->postJson('/api/v1/payroll/periods', [
            'name' => 'Payroll Interm 2026',
            'start_date' => '2026-02-01',
            'end_date' => '2026-04-30',
            'payment_date' => '2026-05-01',
        ]);
        $res3->assertStatus(422)
            ->assertJsonPath('success', false);
    }
}
