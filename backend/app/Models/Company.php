<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Company extends Model
{
    use HasFactory;

    protected $table = 'companies';
    protected $primaryKey = 'id_companies';

    protected $fillable = [
        'name',
        'industry',
        'email',
        'website',
        'phone',
        'address',
        'logo_url',
        'director_name',
        'hr_manager_name',
        'latitude',
        'longitude',
        'radius_meters',
        'role_configurations',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'radius_meters' => 'integer',
        'role_configurations' => 'array',
    ];

    /**
     * Default system roles configuration
     */
    public static function getDefaultRoleConfigurations(): array
    {
        return [
            [
                'key' => 'superadmin',
                'label' => 'Super Admin',
                'badgeClass' => 'bg-purple-50 text-purple-700 border-purple-200/80',
                'description' => 'Administrator tertinggi dengan hak akses mutlak dan wewenang penuh di seluruh modul sistem.',
                'is_system' => true,
                'permissions' => [
                    'dashboard.view',
                    'employees.view',
                    'employees.manage',
                    'attendance.view',
                    'attendance.manage',
                    'leave.view',
                    'leave.approve',
                    'overtime.view',
                    'overtime.approve',
                    'payroll.view',
                    'payroll.manage',
                    'performance.view',
                    'performance.manage',
                    'organization.manage',
                    'roles.manage',
                    'self.attendance',
                    'self.leave',
                    'self.overtime',
                    'self.payroll',
                ],
            ],
            [
                'key' => 'hr',
                'label' => 'HR Administrator',
                'badgeClass' => 'bg-indigo-50 text-indigo-700 border-indigo-200/80',
                'description' => 'Pengelola operasional kepegawaian, kompensasi gaji, dan jadwal kerja.',
                'is_system' => true,
                'permissions' => [
                    'dashboard.view',
                    'employees.view',
                    'employees.manage',
                    'attendance.view',
                    'attendance.manage',
                    'leave.view',
                    'leave.approve',
                    'overtime.view',
                    'overtime.approve',
                    'payroll.view',
                    'payroll.manage',
                    'performance.view',
                    'performance.manage',
                    'organization.manage',
                    'roles.manage',
                    'self.attendance',
                    'self.leave',
                    'self.overtime',
                    'self.payroll',
                ],
            ],
            [
                'key' => 'manager',
                'label' => 'Manager / Supervisor',
                'badgeClass' => 'bg-amber-50 text-amber-700 border-amber-200/80',
                'description' => 'Atasan operasional unit kerja yang menyetujui permohonan cuti dan memantau tim.',
                'is_system' => true,
                'permissions' => [
                    'dashboard.view',
                    'employees.view',
                    'attendance.view',
                    'leave.view',
                    'leave.approve',
                    'overtime.view',
                    'overtime.approve',
                    'performance.view',
                    'self.attendance',
                    'self.leave',
                    'self.overtime',
                    'self.payroll',
                ],
            ],
            [
                'key' => 'employee',
                'label' => 'Karyawan (Staf)',
                'badgeClass' => 'bg-slate-100/90 text-slate-700 border-slate-200/80',
                'description' => 'Staf operasional pengguna mobile attendance dan portal mandiri karyawan.',
                'is_system' => true,
                'permissions' => [
                    'self.attendance',
                    'self.leave',
                    'self.overtime',
                    'self.payroll',
                ],
            ],
        ];
    }

    /**
     * Get active role configurations merged with defaults
     */
    public function getRoleConfigurations(): array
    {
        $stored = $this->role_configurations;
        if (empty($stored) || !is_array($stored)) {
            return self::getDefaultRoleConfigurations();
        }

        $defaultRoles = self::getDefaultRoleConfigurations();
        $defaultMap = [];
        foreach ($defaultRoles as $def) {
            $defaultMap[$def['key']] = $def;
        }

        $result = [];
        $processedKeys = [];

        foreach ($stored as $item) {
            if (!isset($item['key'])) continue;
            $key = $item['key'];
            if ($key === 'owner') {
                $key = 'superadmin';
            }
            $isSystem = in_array($key, ['superadmin', 'owner', 'hr', 'manager', 'employee']);

            $result[] = [
                'key' => $key,
                'label' => ($key === 'superadmin' && in_array($item['label'] ?? '', ['Owner (Pemilik)', 'owner', 'Owner']))
                    ? 'Super Admin'
                    : ($item['label'] ?? ($defaultMap[$key]['label'] ?? ucfirst($key))),
                'badgeClass' => $item['badgeClass'] ?? ($defaultMap[$key]['badgeClass'] ?? 'bg-purple-50 text-purple-700 border-purple-200/80'),
                'description' => ($key === 'superadmin' && str_contains($item['description'] ?? '', 'Pemilik akun organisasi'))
                    ? 'Administrator tertinggi dengan hak akses mutlak dan wewenang penuh di seluruh modul sistem.'
                    : ($item['description'] ?? ($defaultMap[$key]['description'] ?? '')),
                'is_system' => $isSystem,
                'permissions' => is_array($item['permissions'] ?? null) ? $item['permissions'] : ($defaultMap[$key]['permissions'] ?? []),
            ];
            $processedKeys[] = $key;
            if ($key === 'superadmin') {
                $processedKeys[] = 'owner';
            }
        }

        // Ensure missing system roles are retained
        foreach ($defaultRoles as $def) {
            if (!in_array($def['key'], $processedKeys)) {
                $result[] = $def;
            }
        }

        return $result;
    }

    /**
     * Get all recognized role keys
     */
    public function getRoleKeys(): array
    {
        $roles = $this->getRoleConfigurations();
        $keys = array_column($roles, 'key');
        $baseKeys = ['owner', 'hr', 'manager', 'employee', 'superadmin'];
        return array_values(array_unique(array_merge($baseKeys, $keys)));
    }

    /**
     * Available system permissions catalog
     */
    public static function getAvailablePermissions(): array
    {
        return [
            [
                'category' => 'Dashboard & Analitik',
                'permissions' => [
                    [
                        'key' => 'dashboard.view',
                        'label' => 'Lihat Dashboard & Ringkasan Metrik',
                        'description' => 'Melihat ringkasan data kehadiran, payroll, dan karyawan.',
                    ],
                ],
            ],
            [
                'category' => 'Data Karyawan & Organisasi',
                'permissions' => [
                    [
                        'key' => 'employees.view',
                        'label' => 'Lihat Direktori Karyawan',
                        'description' => 'Melihat daftar profil pegawai, jabatan, dan departemen.',
                    ],
                    [
                        'key' => 'employees.manage',
                        'label' => 'Kelola Data Karyawan',
                        'description' => 'Menambah, mengubah profil pegawai, gaji pokok, dan arsip.',
                    ],
                    [
                        'key' => 'organization.manage',
                        'label' => 'Kelola Profil Perusahaan',
                        'description' => 'Mengatur alamat kantor, radius geofence, dan jam kerja umum.',
                    ],
                ],
            ],
            [
                'category' => 'Presensi & Jadwal Kerja',
                'permissions' => [
                    [
                        'key' => 'attendance.view',
                        'label' => 'Lihat Rekap Presensi',
                        'description' => 'Melihat rekap presensi harian, log jam, dan titik koordinat GPS.',
                    ],
                    [
                        'key' => 'attendance.manage',
                        'label' => 'Kelola Koreksi Presensi & Shift',
                        'description' => 'Koreksi log presensi dan mengatur master shift karyawan.',
                    ],
                ],
            ],
            [
                'category' => 'Pengajuan Cuti & Lembur',
                'permissions' => [
                    [
                        'key' => 'leave.view',
                        'label' => 'Lihat Daftar Permohonan Cuti',
                        'description' => 'Melihat seluruh riwayat pengajuan cuti, izin, dan sakit.',
                    ],
                    [
                        'key' => 'leave.approve',
                        'label' => 'Persetujuan & Penolakan Cuti',
                        'description' => 'Wewenang menyetujui atau menolak permohonan cuti karyawan.',
                    ],
                    [
                        'key' => 'overtime.view',
                        'label' => 'Lihat Daftar Pengajuan Lembur',
                        'description' => 'Melihat riwayat pengajuan jam kerja lembur.',
                    ],
                    [
                        'key' => 'overtime.approve',
                        'label' => 'Persetujuan & Penolakan Lembur',
                        'description' => 'Wewenang menyetujui atau menolak permohonan lembur.',
                    ],
                ],
            ],
            [
                'category' => 'Penggajian & Kompensasi (Payroll)',
                'permissions' => [
                    [
                        'key' => 'payroll.view',
                        'label' => 'Lihat Rekapitulasi Payroll',
                        'description' => 'Melihat ringkasan total beban gaji, tunjangan, dan potongan.',
                    ],
                    [
                        'key' => 'payroll.manage',
                        'label' => 'Hitung & Finalisasi Payroll',
                        'description' => 'Membuat periode gaji, hitung otomatis, dan cetak slip.',
                    ],
                ],
            ],
            [
                'category' => 'Evaluasi Kinerja (SPK SMART)',
                'permissions' => [
                    [
                        'key' => 'performance.view',
                        'label' => 'Lihat Hasil Penilaian Kinerja',
                        'description' => 'Melihat perangkingan SMART dan rekomendasi berkala.',
                    ],
                    [
                        'key' => 'performance.manage',
                        'label' => 'Kelola Kriteria & Input Penilaian',
                        'description' => 'Mengatur bobot kriteria SMART dan menginput nilai pegawai.',
                    ],
                ],
            ],
            [
                'category' => 'Manajemen Hak Akses & Pengguna',
                'permissions' => [
                    [
                        'key' => 'roles.manage',
                        'label' => 'Atur Konfigurasi Role & Wewenang',
                        'description' => 'Membuat role baru dan mengatur konfigurasi hak akses.',
                    ],
                ],
            ],
            [
                'category' => 'Portal Mandiri Karyawan (Mobile / Web)',
                'permissions' => [
                    [
                        'key' => 'self.attendance',
                        'label' => 'Presensi Mandiri (Clock In / Out)',
                        'description' => 'Melakukan presensi mandiri verifikasi GPS dan swafoto.',
                    ],
                    [
                        'key' => 'self.leave',
                        'label' => 'Pengajuan Cuti Mandiri',
                        'description' => 'Mengajukan permohonan cuti dan melihat sisa kuota.',
                    ],
                    [
                        'key' => 'self.overtime',
                        'label' => 'Pengajuan Lembur Mandiri',
                        'description' => 'Mengajukan permohonan jam kerja lembur mandiri.',
                    ],
                    [
                        'key' => 'self.payroll',
                        'label' => 'Akses Slip Gaji Pribadi',
                        'description' => 'Melihat dan mengunduh slip gaji bulanan pribadi.',
                    ],
                ],
            ],
        ];
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'id_companies', 'id_companies');
    }

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'id_companies', 'id_companies');
    }

    public function shifts(): HasMany
    {
        return $this->hasMany(Shift::class, 'id_companies', 'id_companies');
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class, 'id_companies', 'id_companies');
    }

    public function leaveRequests(): HasMany
    {
        return $this->hasMany(LeaveRequest::class, 'id_companies', 'id_companies');
    }

    public function payrollSlips(): HasMany
    {
        return $this->hasMany(PayrollSlip::class, 'id_companies', 'id_companies');
    }

    public function overtimeRequests(): HasMany
    {
        return $this->hasMany(OvertimeRequest::class, 'id_companies', 'id_companies');
    }
}
