<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OvertimeRequest extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'overtime_requests';
    protected $primaryKey = 'id_overtime_requests';

    protected $fillable = [
        'id_companies',
        'id_employees',
        'date',
        'start_time',
        'end_time',
        'duration_hours',
        'reason',
        'status',
        'approved_by',
        'rejected_reason',
    ];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'duration_hours' => 'float',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by', 'id_users');
    }
}
