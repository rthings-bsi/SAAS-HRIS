<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\PerformancePeriod;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PerformanceApiTest extends TestCase
{
    use RefreshDatabase;

    protected Company $company;
    protected User $hrUser;
    protected User $employeeUser;

    protected function setUp(): void
    {
        parent::setUp();

        $this->company = Company::create([
            'name' => 'PT Cipta Kreasi',
            'slug' => 'pt-cipta-kreasi',
            'email' => 'info@cipta.test',
            'subscription_status' => 'active',
        ]);

        $this->hrUser = User::create([
            'id_companies' => $this->company->id_companies,
            'name' => 'HR Manager',
            'email' => 'hr@cipta.test',
            'password' => bcrypt('password123'),
            'role' => 'hr',
            'is_active' => true,
        ]);

        $this->employeeUser = User::create([
            'id_companies' => $this->company->id_companies,
            'name' => 'Staff Regular',
            'email' => 'staff@cipta.test',
            'password' => bcrypt('password123'),
            'role' => 'employee',
            'is_active' => true,
        ]);
    }

    public function test_can_create_performance_period(): void
    {
        Sanctum::actingAs($this->hrUser);

        $response = $this->postJson('/api/v1/performance/periods', [
            'name' => 'Penilaian Kinerja Semester I 2026',
            'start_date' => '2026-01-01',
            'end_date' => '2026-06-30',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Penilaian Kinerja Semester I 2026');

        $this->assertDatabaseHas('performance_periods', [
            'name' => 'Penilaian Kinerja Semester I 2026',
            'start_date' => '2026-01-01 00:00:00',
            'end_date' => '2026-06-30 00:00:00',
            'status' => 'draft',
        ]);
    }

    public function test_cannot_create_performance_period_with_duplicate_name(): void
    {
        Sanctum::actingAs($this->hrUser);

        PerformancePeriod::create([
            'name' => 'Penilaian Kinerja Semester I 2026',
            'start_date' => '2026-01-01',
            'end_date' => '2026-06-30',
            'status' => 'draft',
        ]);

        // Attempt with same name (case-insensitive) but different dates
        $response = $this->postJson('/api/v1/performance/periods', [
            'name' => 'penilaian kinerja semester i 2026',
            'start_date' => '2026-07-01',
            'end_date' => '2026-12-31',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['name']]);
    }

    public function test_cannot_create_performance_period_with_exact_same_dates(): void
    {
        Sanctum::actingAs($this->hrUser);

        PerformancePeriod::create([
            'name' => 'Penilaian Kinerja Sesi A',
            'start_date' => '2026-01-01',
            'end_date' => '2026-06-30',
            'status' => 'draft',
        ]);

        // Attempt with different name but exact same dates
        $response = $this->postJson('/api/v1/performance/periods', [
            'name' => 'Penilaian Kinerja Sesi B',
            'start_date' => '2026-01-01',
            'end_date' => '2026-06-30',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['start_date', 'end_date']]);
    }

    public function test_cannot_create_performance_period_with_overlapping_dates(): void
    {
        Sanctum::actingAs($this->hrUser);

        PerformancePeriod::create([
            'name' => 'Penilaian Kinerja Q1 2026',
            'start_date' => '2026-01-01',
            'end_date' => '2026-03-31',
            'status' => 'draft',
        ]);

        // Attempt with overlapping date: 2026-02-15 to 2026-05-31
        $response = $this->postJson('/api/v1/performance/periods', [
            'name' => 'Penilaian Kinerja Q2 2026',
            'start_date' => '2026-02-15',
            'end_date' => '2026-05-31',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['start_date', 'end_date']]);
    }

    public function test_regular_employee_cannot_create_performance_period(): void
    {
        Sanctum::actingAs($this->employeeUser);

        $response = $this->postJson('/api/v1/performance/periods', [
            'name' => 'Periode Ilegal',
            'start_date' => '2026-01-01',
            'end_date' => '2026-06-30',
        ]);

        $response->assertStatus(403);
    }

    public function test_can_delete_draft_performance_period(): void
    {
        Sanctum::actingAs($this->hrUser);

        $period = PerformancePeriod::create([
            'name' => 'Periode Draft Dihapus',
            'start_date' => '2026-01-01',
            'end_date' => '2026-06-30',
            'status' => 'draft',
        ]);

        $response = $this->deleteJson("/api/v1/performance/periods/{$period->id_performance_periods}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('performance_periods', [
            'id_performance_periods' => $period->id_performance_periods,
        ]);
    }

    public function test_cannot_delete_finalized_performance_period(): void
    {
        Sanctum::actingAs($this->hrUser);

        $period = PerformancePeriod::create([
            'name' => 'Periode Finalized',
            'start_date' => '2026-01-01',
            'end_date' => '2026-06-30',
            'status' => 'finalized',
        ]);

        $response = $this->deleteJson("/api/v1/performance/periods/{$period->id_performance_periods}");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('performance_periods', [
            'id_performance_periods' => $period->id_performance_periods,
        ]);
    }
}
