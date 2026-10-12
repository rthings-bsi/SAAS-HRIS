<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EndToEndHrisFlowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_full_hris_lifecycle_from_registration_to_payroll_slip_download(): void
    {
        // 1. Setup Company & Owner User di database (Single Company Non-SaaS)
        $company = Company::create([
            'name' => 'PT Solusi Digital Maju',
            'email' => 'info@solusidigital.test',
        ]);

        User::create([
            'id_companies' => $company->id_companies,
            'name' => 'Hendro Wijaya',
            'email' => 'hendro@solusidigital.test',
            'password' => Hash::make('Rahasia123#'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        // Verifikasi endpoint registrasi publik sudah dihapus (404)
        $this->postJson('/api/v1/auth/register-company', [
            'company_name' => 'PT Coba',
        ])->assertStatus(404);

        // 2. Owner Login ulang untuk verifikasi kredensial
        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => 'hendro@solusidigital.test',
            'password' => 'Rahasia123#',
        ]);

        $loginResponse->assertStatus(200);
        $ownerUser = User::find($loginResponse->json('data.user.id_users'));
        Sanctum::actingAs($ownerUser);

        // 3. Setup Struktur Organisasi: Cabang Kantor Pusat
        $branchResponse = $this->postJson('/api/v1/branches', [
            'name' => 'Kantor Pusat Jakarta',
            'address' => 'Jl. Sudirman No. 45, Jakarta Selatan',
            'latitude' => -6.2088,
            'longitude' => 106.8456,
            'radius_meters' => 100,
            'is_headquarters' => true,
        ]);

        $branchResponse->assertStatus(201);
        $idBranch = $branchResponse->json('data.id_branches');

        // 4. Setup Departemen & Posisi Jabatan
        $deptResponse = $this->postJson('/api/v1/departments', [
            'name' => 'Engineering',
        ]);
        $deptResponse->assertStatus(201);
        $idDept = $deptResponse->json('data.id_departments');

        $posResponse = $this->postJson('/api/v1/job-positions', [
            'name' => 'Backend Developer',
        ]);
        $posResponse->assertStatus(201);
        $idPosition = $posResponse->json('data.id_job_positions');

        // 5. Setup Master Shift Kerja (08:00 - 17:00)
        $shiftResponse = $this->postJson('/api/v1/shifts', [
            'name' => 'Shift Reguler Kantor',
            'start_time' => '08:00',
            'end_time' => '17:00',
            'late_tolerance_minutes' => 15,
        ]);
        $shiftResponse->assertStatus(201);
        $idShift = $shiftResponse->json('data.id_shifts');

        // 6. Buat Data Karyawan (Eko Pratama)
        $employeeResponse = $this->postJson('/api/v1/employees', [
            'name' => 'Eko Pratama',
            'email' => 'eko@solusidigital.test',
            'password' => 'PasswordEko123',
            'nik' => 'SDM-001',
            'gender' => 'male',
            'hire_date' => '2024-01-15',
            'id_branches' => $idBranch,
            'id_departments' => $idDept,
            'id_job_positions' => $idPosition,
            'employment_status' => 'permanent',
            'basic_salary' => 7500000,
            'allowance_fixed' => 1000000,
        ]);

        $employeeResponse->assertStatus(201);
        $idEmployee = $employeeResponse->json('data.id_employees');
        $idUserEmployee = $employeeResponse->json('data.id_users');
        $employeeUser = User::find($idUserEmployee);

        // 7. Jadwalkan Shift Karyawan
        $assignResponse = $this->postJson('/api/v1/employees/assign-shift', [
            'id_employees' => $idEmployee,
            'id_shifts' => $idShift,
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
        ]);
        $assignResponse->assertStatus(200);

        // 8. Karyawan Login ke Sistem Mobile App
        Sanctum::actingAs($employeeUser);

        $todayResponse = $this->getJson('/api/v1/attendance/today');
        $todayResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'shift' => [
                        'name' => 'Shift Reguler Kantor',
                    ],
                ],
            ]);

        // 9. Karyawan Clock In dalam Radius Kantor
        $photoIn = UploadedFile::fake()->image('selfie_in.jpg');
        $clockInResponse = $this->postJson('/api/v1/attendance/clock-in', [
            'latitude' => -6.20882,
            'longitude' => 106.84562,
            'photo' => $photoIn,
            'device_time' => '2026-10-01 08:02:00',
        ]);
        $clockInResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'on_time',
                ],
            ]);

        // 10. Karyawan Clock Out dalam Radius Kantor
        $photoOut = UploadedFile::fake()->image('selfie_out.jpg');
        $clockOutResponse = $this->postJson('/api/v1/attendance/clock-out', [
            'latitude' => -6.20881,
            'longitude' => 106.84561,
            'photo' => $photoOut,
            'device_time' => '2026-10-01 17:05:00',
        ]);
        $clockOutResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        // 11. Buat Master Tipe Cuti & Pengajuan Cuti Karyawan
        Sanctum::actingAs($ownerUser);
        $leaveTypeResponse = $this->postJson('/api/v1/leave/types', [
            'name' => 'Cuti Sakit',
            'quota_days' => 14,
            'is_paid' => true,
        ]);
        $leaveTypeResponse->assertStatus(201);

        Sanctum::actingAs($employeeUser);
        $leaveRequestResponse = $this->postJson('/api/v1/leave/request', [
            'leave_type' => 'Cuti Sakit',
            'start_date' => '2026-10-05',
            'end_date' => '2026-10-06',
            'reason' => 'Demam dan istirahat dokter',
        ]);
        $leaveRequestResponse->assertStatus(201);
        $idLeaveRequest = $leaveRequestResponse->json('data.id_leave_requests');

        // 12. HR / Owner Menyetujui Cuti Karyawan
        Sanctum::actingAs($ownerUser);
        $approveLeave = $this->postJson("/api/v1/leave/approvals/{$idLeaveRequest}/action", [
            'action' => 'approved',
            'notes' => 'Disetujui sesuai surat dokter.',
        ]);
        $approveLeave->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'approved',
                ],
            ]);

        // 13. Owner Membuka Periode Penggajian Bulan Oktober 2026
        $periodResponse = $this->postJson('/api/v1/payroll/periods', [
            'name' => 'Oktober 2026 SDM',
            'start_date' => '2026-10-01',
            'end_date' => '2026-10-31',
            'payment_date' => '2026-11-01',
        ]);
        $periodResponse->assertStatus(201);
        $idPeriod = $periodResponse->json('data.id_payroll_periods');

        // 14. Owner Menjalankan Kalkulasi Penggajian Otomatis
        $calculateResponse = $this->postJson("/api/v1/payroll/periods/{$idPeriod}/calculate");
        $calculateResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slips_calculated' => 1,
                ],
            ]);

        // 15. Owner Memeriksa Rincian Slip Gaji Karyawan
        $slipsResponse = $this->getJson("/api/v1/payroll/periods/{$idPeriod}/slips");
        $slipsResponse->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment([
                'name' => 'Eko Pratama',
                'basic_salary' => 7500000,
                'allowance_fixed' => 1000000,
            ]);

        $idSlip = $slipsResponse->json('data.0.id_payroll_slips');

        // 16. Owner Memfinalisasi Periode & Menghasilkan Slip Gaji PDF
        $finalizeResponse = $this->postJson("/api/v1/payroll/periods/{$idPeriod}/finalize");
        $finalizeResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slips_finalized' => 1,
                ],
            ]);

        // 17. Karyawan Memeriksa Slip Gaji Pribadi di Aplikasi Mobile
        Sanctum::actingAs($employeeUser);
        $mySlipsResponse = $this->getJson('/api/v1/payroll/my-slips');
        $mySlipsResponse->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment([
                'period_name' => 'Oktober 2026 SDM',
                'id_payroll_slips' => $idSlip,
            ]);

        // 18. Karyawan Mengunduh Berkas PDF Slip Gaji
        $downloadResponse = $this->get("/api/v1/payroll/my-slips/{$idSlip}/download");
        $downloadResponse->assertStatus(200)
            ->assertHeader('content-type', 'application/pdf');

        // 19. Uji Keamanan Multi-Tenant (Tenant Lain Tidak Boleh Akses Data Ini)
        $companyOther = Company::create([
            'name' => 'PT Kompetitor Lain',
            'slug' => 'pt-kompetitor-lain',
            'email' => 'other@kompetitor.test',
            'subscription_status' => 'active',
        ]);
        $otherUser = User::create([
            'id_companies' => $companyOther->id_companies,
            'name' => 'Owner Lain',
            'email' => 'owner@kompetitor.test',
            'password' => bcrypt('password123'),
            'role' => 'owner',
            'is_active' => true,
        ]);

        Sanctum::actingAs($otherUser);

        // Cek bahwa data tenant SDM tidak terlihat oleh tenant lain
        $this->getJson("/api/v1/payroll/periods/{$idPeriod}")->assertStatus(404);
        $this->getJson("/api/v1/payroll/periods/{$idPeriod}/slips")->assertStatus(404);
        $this->getJson("/api/v1/branches/999")->assertStatus(404);
        $this->getJson("/api/v1/employees/{$idEmployee}")->assertStatus(404);
    }
}
