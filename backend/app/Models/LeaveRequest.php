<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LeaveRequest extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'leave_requests';
    protected $primaryKey = 'id_leave_requests';

    protected $fillable = [
        'id_companies',
        'id_employees',
        'id_leave_types',
        'start_date',
        'end_date',
        'total_days',
        'reason',
        'attachment_url',
        'status',
        'approved_by',
        'rejected_reason',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date:Y-m-d',
            'end_date' => 'date:Y-m-d',
            'total_days' => 'integer',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }

    public function leaveType(): BelongsTo
    {
        return $this->belongsTo(LeaveType::class, 'id_leave_types', 'id_leave_types');
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by', 'id_users');
    }
}
