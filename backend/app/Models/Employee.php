<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Employee extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'employees';
    protected $primaryKey = 'id_employees';

    protected $fillable = [
        'id_companies',
        'id_users',
        'department_name',
        'job_position_name',
        'id_shifts',
        'annual_leave_quota',
        'nik',
        'phone',
        'gender',
        'birth_date',
        'hire_date',
        'employment_status',
        'basic_salary',
        'allowance_fixed',
        'bank_name',
        'bank_account_number',
        'bank_account_holder',
    ];

    protected $appends = [
        'branch',
        'department',
        'job_position',
        'jobPosition',
        'id_branches',
        'id_departments',
        'id_job_positions',
    ];

    protected function casts(): array
    {
        return [
            'birth_date' => 'date',
            'hire_date' => 'date',
            'basic_salary' => 'decimal:2',
            'allowance_fixed' => 'decimal:2',
            'annual_leave_quota' => 'integer',
        ];
    }

    public function setBirthDateAttribute($value): void
    {
        $this->attributes['birth_date'] = $value ? \Carbon\Carbon::parse($value)->format('Y-m-d') : null;
    }

    public function setHireDateAttribute($value): void
    {
        $this->attributes['hire_date'] = $value ? \Carbon\Carbon::parse($value)->format('Y-m-d') : null;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_users', 'id_users');
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class, 'id_shifts', 'id_shifts');
    }

    public function getBranchAttribute(): ?object
    {
        $company = $this->company;
        if (!$company || $company->latitude === null || $company->longitude === null) {
            return null;
        }
        return (object) [
            'id_branches' => 1,
            'name' => $company->name,
            'address' => $company->address,
            'latitude' => (float) $company->latitude,
            'longitude' => (float) $company->longitude,
            'radius_meters' => (int) ($company->radius_meters ?: 100),
        ];
    }

    public function getDepartmentAttribute(): ?object
    {
        return $this->department_name ? (object) ['id_departments' => $this->id_departments ?? 1, 'name' => $this->department_name] : null;
    }

    public function getJobPositionAttribute(): ?object
    {
        return $this->job_position_name ? (object) ['id_job_positions' => $this->id_job_positions ?? 1, 'name' => $this->job_position_name] : null;
    }

    public function getIdBranchesAttribute(): int
    {
        return 1;
    }

    public function getIdDepartmentsAttribute(): ?int
    {
        if (!$this->department_name) {
            return null;
        }
        $map = [
            'Teknologi Informasi' => 1,
            'Sumber Daya Manusia' => 2,
            'Operasional & Produksi' => 3,
            'Keuangan & Akuntansi' => 4,
            'Pemasaran & Penjualan' => 5,
        ];
        return $map[$this->department_name] ?? 1;
    }

    public function getIdJobPositionsAttribute(): ?int
    {
        if (!$this->job_position_name) {
            return null;
        }
        $map = [
            'Direktur Utama' => 1,
            'Manajer HRD' => 2,
            'Software Engineer' => 3,
            'Staff Administrasi' => 4,
            'Operator Mesin' => 5,
        ];
        return $map[$this->job_position_name] ?? 3;
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class, 'id_employees', 'id_employees');
    }

    public function leaveRequests(): HasMany
    {
        return $this->hasMany(LeaveRequest::class, 'id_employees', 'id_employees');
    }

    public function payrollSlips(): HasMany
    {
        return $this->hasMany(PayrollSlip::class, 'id_employees', 'id_employees');
    }

    public function overtimeRequests(): HasMany
    {
        return $this->hasMany(OvertimeRequest::class, 'id_employees', 'id_employees');
    }
}
