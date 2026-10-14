<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserRoleApiTest extends TestCase
{
    use RefreshDatabase;

    private Company $company;
    private User $owner;
    private User $hr;
    private User $employee;

    protected function setUp(): void
    {
        parent::setUp();

        $this->company = Company::create([
            'name' => 'PT Sumber Makmur',
            'email' => 'info@makmur.com',
        ]);

        $this->owner = User::create([
            'id_companies' => $this->company->id_companies,
            'name' => 'Owner Bos',
            'email' => 'owner@makmur.com',
            'password' => bcrypt('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        $this->hr = User::create([
            'id_companies' => $this->company->id_companies,
            'name' => 'HR Staff',
            'email' => 'hr@makmur.com',
            'password' => bcrypt('password123'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        $this->employee = User::create([
            'id_companies' => $this->company->id_companies,
            'name' => 'Budi Staf',
            'email' => 'budi@makmur.com',
            'password' => bcrypt('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);
    }

    public function test_owner_can_list_users(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->getJson('/api/v1/users');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(3, 'data');
    }

    public function test_employee_cannot_list_users(): void
    {
        $response = $this->actingAs($this->employee, 'sanctum')
            ->getJson('/api/v1/users');

        $response->assertStatus(403);
    }

    public function test_owner_can_update_user_role_to_manager(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->putJson("/api/v1/users/{$this->employee->id_users}/role", [
                'role' => 'manager',
            ]);

        $response->assertOk()
            ->assertJsonPath('data.role', 'manager');

        $this->assertDatabaseHas('users', [
            'id_users' => $this->employee->id_users,
            'role' => 'manager',
        ]);
    }

    public function test_user_cannot_change_own_role(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->putJson("/api/v1/users/{$this->owner->id_users}/role", [
                'role' => 'employee',
            ]);

        $response->assertStatus(422);
    }

    public function test_owner_can_toggle_user_status(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->putJson("/api/v1/users/{$this->employee->id_users}/status");

        $response->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('users', [
            'id_users' => $this->employee->id_users,
            'is_active' => false,
        ]);
    }

    public function test_owner_can_get_roles_configuration_and_available_permissions(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->getJson('/api/v1/roles');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'roles' => [
                        '*' => ['key', 'label', 'badgeClass', 'description', 'is_system', 'permissions', 'user_count']
                    ],
                    'available_permissions' => [
                        '*' => ['category', 'permissions' => ['*' => ['key', 'label', 'description']]]
                    ]
                ]
            ]);
    }

    public function test_owner_can_create_custom_role(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->postJson('/api/v1/roles', [
                'name' => 'Finance & Accounting',
                'key' => 'finance',
                'description' => 'Pengelola kompensasi dan verifikasi payroll',
                'badgeClass' => 'bg-emerald-50 text-emerald-700 border-emerald-200/80',
                'permissions' => ['payroll.view', 'payroll.manage', 'dashboard.view'],
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.key', 'finance')
            ->assertJsonPath('data.label', 'Finance & Accounting')
            ->assertJsonPath('data.is_system', false);

        // Verify company now contains finance in role configurations
        $this->company->refresh();
        $this->assertContains('finance', $this->company->getRoleKeys());
    }

    public function test_owner_can_assign_custom_role_to_user(): void
    {
        // First create the custom role
        $this->actingAs($this->owner, 'sanctum')
            ->postJson('/api/v1/roles', [
                'name' => 'Supervisor Lapangan',
                'key' => 'field_supervisor',
                'description' => 'Supervisor lapangan',
                'permissions' => ['attendance.view', 'leave.approve'],
            ]);

        // Assign to employee
        $response = $this->actingAs($this->owner, 'sanctum')
            ->putJson("/api/v1/users/{$this->employee->id_users}/role", [
                'role' => 'field_supervisor',
            ]);

        $response->assertOk()
            ->assertJsonPath('data.role', 'field_supervisor');

        $this->assertDatabaseHas('users', [
            'id_users' => $this->employee->id_users,
            'role' => 'field_supervisor',
        ]);
    }

    public function test_owner_can_update_role_configuration(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->putJson('/api/v1/roles/manager', [
                'label' => 'Head of Department',
                'description' => 'Kepala departemen operasional',
                'badgeClass' => 'bg-amber-50 text-amber-700 border-amber-200/80',
                'permissions' => ['dashboard.view', 'employees.view', 'attendance.view', 'leave.approve', 'payroll.view'],
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.label', 'Head of Department');

        $this->company->refresh();
        $roles = $this->company->getRoleConfigurations();
        $managerRole = collect($roles)->firstWhere('key', 'manager');
        $this->assertEquals('Head of Department', $managerRole['label']);
        $this->assertContains('payroll.view', $managerRole['permissions']);
    }

    public function test_cannot_delete_system_role(): void
    {
        $response = $this->actingAs($this->owner, 'sanctum')
            ->deleteJson('/api/v1/roles/hr');

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_cannot_delete_custom_role_with_assigned_users(): void
    {
        // Create custom role
        $this->actingAs($this->owner, 'sanctum')
            ->postJson('/api/v1/roles', [
                'name' => 'Auditor',
                'key' => 'auditor',
                'description' => 'Internal auditor',
                'permissions' => ['dashboard.view'],
            ]);

        // Assign to employee
        $this->actingAs($this->owner, 'sanctum')
            ->putJson("/api/v1/users/{$this->employee->id_users}/role", [
                'role' => 'auditor',
            ]);

        // Try to delete auditor
        $response = $this->actingAs($this->owner, 'sanctum')
            ->deleteJson('/api/v1/roles/auditor');

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_can_delete_unassigned_custom_role(): void
    {
        // Create custom role
        $this->actingAs($this->owner, 'sanctum')
            ->postJson('/api/v1/roles', [
                'name' => 'Temp Role',
                'key' => 'temp_role',
                'description' => 'Role sementara',
                'permissions' => ['dashboard.view'],
            ]);

        $response = $this->actingAs($this->owner, 'sanctum')
            ->deleteJson('/api/v1/roles/temp_role');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->company->refresh();
        $this->assertNotContains('temp_role', $this->company->getRoleKeys());
    }

    public function test_owner_can_reset_roles(): void
    {
        // Alter manager role
        $this->actingAs($this->owner, 'sanctum')
            ->putJson('/api/v1/roles/manager', [
                'label' => 'Custom Manager Name',
                'description' => 'Custom description',
                'badgeClass' => 'bg-amber-50 text-amber-700 border-amber-200/80',
                'permissions' => ['dashboard.view'],
            ]);

        $response = $this->actingAs($this->owner, 'sanctum')
            ->postJson('/api/v1/roles/reset');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->company->refresh();
        $roles = $this->company->getRoleConfigurations();
        $managerRole = collect($roles)->firstWhere('key', 'manager');
        $this->assertEquals('Manager / Supervisor', $managerRole['label']);
    }
}
