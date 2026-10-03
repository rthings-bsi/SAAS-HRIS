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

class MultiTenancyIsolationTest extends TestCase
{
    use RefreshDatabase;

    protected Company $companyA;
    protected Company $companyB;
    protected User $userA;
    protected User $userB;
    protected User $superadmin;

    protected function setUp(): void
    {
        parent::setUp();

        // Setup Company A
        $this->companyA = Company::create([
            'name' => 'Company A',
            'slug' => 'company-a',
            'email' => 'corp-a@test.com',
            'subscription_status' => 'active',
        ]);

        $this->userA = User::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'User Company A',
            'email' => 'usera@companya.com',
            'password' => Hash::make('password'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        // Setup Company B
        $this->companyB = Company::create([
            'name' => 'Company B',
            'slug' => 'company-b',
            'email' => 'corp-b@test.com',
            'subscription_status' => 'active',
        ]);

        $this->userB = User::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'User Company B',
            'email' => 'userb@companyb.com',
            'password' => Hash::make('password'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        // Setup Superadmin (without id_companies)
        $this->superadmin = User::create([
            'id_companies' => null,
            'name' => 'Super Admin',
            'email' => 'superadmin@saas.com',
            'password' => Hash::make('password'),
            'role' => 'superadmin',
            'is_active' => true,
        ]);
    }

    public function test_tenant_can_only_see_their_own_departments(): void
    {
        $deptA = Department::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Dept Alpha (Company A)',
        ]);

        $deptB = Department::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Dept Beta (Company B)',
        ]);

        $this->actingAs($this->userA);

        $departments = Department::all();

        $this->assertCount(1, $departments);
        $this->assertTrue($departments->contains('id_departments', $deptA->id_departments));
        $this->assertFalse($departments->contains('id_departments', $deptB->id_departments));
        $this->assertNull(Department::find($deptB->id_departments));
    }

    public function test_tenant_can_only_see_their_own_branches(): void
    {
        $branchA = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Branch Jakarta',
            'address' => 'Jl. Sudirman',
            'latitude' => -6.200000,
            'longitude' => 106.816666,
            'radius_meters' => 50,
        ]);

        $branchB = Branch::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Branch Surabaya',
            'address' => 'Jl. Pemuda',
            'latitude' => -7.250445,
            'longitude' => 112.768845,
            'radius_meters' => 100,
        ]);

        $this->actingAs($this->userA);

        $branches = Branch::all();

        $this->assertCount(1, $branches);
        $this->assertTrue($branches->contains('id_branches', $branchA->id_branches));
        $this->assertFalse($branches->contains('id_branches', $branchB->id_branches));
        $this->assertNull(Branch::find($branchB->id_branches));
    }

    public function test_tenant_can_only_see_their_own_employees(): void
    {
        $branchA = Branch::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Branch Jakarta',
            'address' => 'Jl. Sudirman',
            'latitude' => -6.2,
            'longitude' => 106.8,
        ]);

        $branchB = Branch::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Branch Surabaya',
            'address' => 'Jl. Pemuda',
            'latitude' => -7.2,
            'longitude' => 112.7,
        ]);

        $empA = Employee::create([
            'id_companies' => $this->companyA->id_companies,
            'id_users' => $this->userA->id_users,
            'id_branches' => $branchA->id_branches,
            'nik' => 'NIK-A',
            'gender' => 'male',
            'hire_date' => '2023-01-01',
        ]);

        $empB = Employee::create([
            'id_companies' => $this->companyB->id_companies,
            'id_users' => $this->userB->id_users,
            'id_branches' => $branchB->id_branches,
            'nik' => 'NIK-B',
            'gender' => 'female',
            'hire_date' => '2023-02-01',
        ]);

        $this->actingAs($this->userA);

        $employees = Employee::all();

        $this->assertCount(1, $employees);
        $this->assertTrue($employees->contains('id_employees', $empA->id_employees));
        $this->assertFalse($employees->contains('id_employees', $empB->id_employees));
    }

    public function test_model_automatically_sets_id_companies_on_creation_for_authenticated_user(): void
    {
        $this->actingAs($this->userA);

        // Created without specifying id_companies
        $createdDept = Department::create([
            'name' => 'Auto-Assigned Department',
        ]);

        $this->assertNotNull($createdDept->id_companies);
        $this->assertEquals($this->companyA->id_companies, $createdDept->id_companies);
    }

    public function test_cross_tenant_isolation_when_switching_users(): void
    {
        $deptA = Department::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Dept Alpha (Company A)',
        ]);

        $deptB = Department::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Dept Beta (Company B)',
        ]);

        // Login as User B
        $this->actingAs($this->userB);

        $departments = Department::all();

        $this->assertCount(1, $departments);
        $this->assertTrue($departments->contains('id_departments', $deptB->id_departments));
        $this->assertFalse($departments->contains('id_departments', $deptA->id_departments));
        $this->assertNull(Department::find($deptA->id_departments));
    }

    public function test_superadmin_without_company_id_can_see_all_tenant_data(): void
    {
        $deptA = Department::create([
            'id_companies' => $this->companyA->id_companies,
            'name' => 'Dept Alpha (Company A)',
        ]);

        $deptB = Department::create([
            'id_companies' => $this->companyB->id_companies,
            'name' => 'Dept Beta (Company B)',
        ]);

        $this->actingAs($this->superadmin);

        $departments = Department::all();

        $this->assertCount(2, $departments);
        $this->assertTrue($departments->contains('id_departments', $deptA->id_departments));
        $this->assertTrue($departments->contains('id_departments', $deptB->id_departments));
    }
}
