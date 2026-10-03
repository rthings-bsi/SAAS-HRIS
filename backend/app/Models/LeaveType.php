<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LeaveType extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'leave_types';
    protected $primaryKey = 'id_leave_types';

    protected $fillable = [
        'id_companies',
        'name',
        'quota_days',
        'is_paid',
    ];

    protected function casts(): array
    {
        return [
            'quota_days' => 'integer',
            'is_paid' => 'boolean',
        ];
    }

    public function leaveRequests(): HasMany
    {
        return $this->hasMany(LeaveRequest::class, 'id_leave_types', 'id_leave_types');
    }
}
