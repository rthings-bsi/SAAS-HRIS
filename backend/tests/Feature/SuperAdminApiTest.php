<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SuperAdminApiTest extends TestCase
{
    use RefreshDatabase;

    private User $superadmin;
    private User $owner;
    private Company $company;

    protected function setUp(): void
    {
        parent::setUp();

        $this->superadmin = User::create([
            'id_companies' => null,
            'name' => 'Platform Superadmin',
            'email' => 'superadmin@hris-saas.com',
            'password' => 'password',
            'role' => 'superadmin',
            'is_active' => true,
        ]);

        $this->company = Company::create([
            'name' => 'PT Mitra Sejahtera',
            'slug' => 'pt-mitra-sejahtera',
            'email' => 'admin@mitra.co.id',
            'phone' => '021-998877',
            'subscription_status' => 'trial',
        ]);

        $this->owner = User::create([
            'id_companies' => $this->company->id_companies,
            'name' => 'Owner Mitra',
            'email' => 'owner@mitra.co.id',
            'password' => 'password',
            'role' => 'owner',
            'is_active' => true,
        ]);
    }

    public function test_non_superadmin_forbidden(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson('/api/v1/superadmin/stats');

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Akses ditolak. Hanya Superadmin platform yang diizinkan.',
            ]);
    }

    public function test_superadmin_can_get_stats(): void
    {
        $response = $this->actingAs($this->superadmin)
            ->getJson('/api/v1/superadmin/stats');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'total_companies' => 1,
                    'trial_companies' => 1,
                ],
            ]);
    }

    public function test_superadmin_can_list_companies(): void
    {
        $response = $this->actingAs($this->superadmin)
            ->getJson('/api/v1/superadmin/companies');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'data' => [
                        '*' => [
                            'id_companies',
                            'name',
                            'subscription_status',
                            'users_count',
                            'employees_count',
                            'branches_count',
                        ],
                    ],
                ],
            ]);
    }

    public function test_superadmin_can_show_company(): void
    {
        $response = $this->actingAs($this->superadmin)
            ->getJson("/api/v1/superadmin/companies/{$this->company->id_companies}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id_companies' => $this->company->id_companies,
                    'name' => 'PT Mitra Sejahtera',
                ],
            ]);
    }

    public function test_superadmin_can_update_company_subscription(): void
    {
        $response = $this->actingAs($this->superadmin)
            ->putJson("/api/v1/superadmin/companies/{$this->company->id_companies}", [
                'subscription_status' => 'active',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'subscription_status' => 'active',
                ],
            ]);

        $this->assertDatabaseHas('companies', [
            'id_companies' => $this->company->id_companies,
            'subscription_status' => 'active',
        ]);
    }

    public function test_superadmin_can_delete_company(): void
    {
        $response = $this->actingAs($this->superadmin)
            ->deleteJson("/api/v1/superadmin/companies/{$this->company->id_companies}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseMissing('companies', [
            'id_companies' => $this->company->id_companies,
        ]);
    }
}
