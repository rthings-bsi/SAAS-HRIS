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
    ];

    public function branches(): HasMany
    {
        return $this->hasMany(Branch::class, 'id_companies', 'id_companies');
    }

    public function departments(): HasMany
    {
        return $this->hasMany(Department::class, 'id_companies', 'id_companies');
    }

    public function jobPositions(): HasMany
    {
        return $this->hasMany(JobPosition::class, 'id_companies', 'id_companies');
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

    public function employeeShifts(): HasMany
    {
        return $this->hasMany(EmployeeShift::class, 'id_companies', 'id_companies');
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class, 'id_companies', 'id_companies');
    }

    public function leaveTypes(): HasMany
    {
        return $this->hasMany(LeaveType::class, 'id_companies', 'id_companies');
    }

    public function leaveRequests(): HasMany
    {
        return $this->hasMany(LeaveRequest::class, 'id_companies', 'id_companies');
    }

    public function payrollPeriods(): HasMany
    {
        return $this->hasMany(PayrollPeriod::class, 'id_companies', 'id_companies');
    }

    public function payrollSlips(): HasMany
    {
        return $this->hasMany(PayrollSlip::class, 'id_companies', 'id_companies');
    }
}
