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
            'slug' => 'pt-sumber-makmur',
            'email' => 'info@makmur.com',
            'subscription_status' => 'active',
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
}
