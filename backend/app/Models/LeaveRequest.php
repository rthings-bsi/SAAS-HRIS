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
        'leave_type',
        'is_paid',
        'start_date',
        'end_date',
        'total_days',
        'reason',
        'attachment_url',
        'status',
        'approved_by',
        'rejected_reason',
    ];

    protected $appends = [
        'leave_type_obj',
        'request_number',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date:Y-m-d',
            'end_date' => 'date:Y-m-d',
            'total_days' => 'integer',
            'is_paid' => 'boolean',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }

    public function getRequestNumberAttribute(): string
    {
        $ym = now()->format('Ym');
        if ($this->created_at) {
            $ym = $this->created_at->format('Ym');
        } elseif (! empty($this->start_date)) {
            $ym = \Carbon\Carbon::parse($this->start_date)->format('Ym');
        }

        $seq = str_pad((string) ((int) ($this->id_leave_requests ?? 0)), 6, '0', STR_PAD_LEFT);

        return "LVR-{$ym}-{$seq}";
    }

    public function getLeaveTypeObjAttribute(): ?object
    {
        return (object) [
            'id_leave_types' => 1,
            'name' => $this->leave_type ?? 'Cuti Tahunan',
            'is_paid' => (bool) $this->is_paid,
        ];
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by', 'id_users');
    }
}
