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
        'id_branches',
        'id_departments',
        'id_job_positions',
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

    protected function casts(): array
    {
        return [
            'birth_date' => 'date',
            'hire_date' => 'date',
            'basic_salary' => 'decimal:2',
            'allowance_fixed' => 'decimal:2',
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

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class, 'id_branches', 'id_branches');
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class, 'id_departments', 'id_departments');
    }

    public function jobPosition(): BelongsTo
    {
        return $this->belongsTo(JobPosition::class, 'id_job_positions', 'id_job_positions');
    }

    public function employeeShifts(): HasMany
    {
        return $this->hasMany(EmployeeShift::class, 'id_employees', 'id_employees');
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
