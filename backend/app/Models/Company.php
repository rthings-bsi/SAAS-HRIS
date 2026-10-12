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
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'radius_meters' => 'integer',
    ];

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
