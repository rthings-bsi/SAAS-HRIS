<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OvertimeRequest extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'overtime_requests';
    protected $primaryKey = 'id_overtime_requests';

    protected $fillable = [
        'id_companies',
        'id_employees',
        'date',
        'end_date',
        'start_time',
        'end_time',
        'duration_hours',
        'overtime_type',
        'reason_category',
        'reason',
        'attachment_path',
        'status',
        'approved_by',
        'rejected_reason',
    ];

    protected $appends = [
        'attachment_url',
        'request_number',
    ];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'end_date' => 'date:Y-m-d',
        'duration_hours' => 'float',
    ];

    public function getRequestNumberAttribute(): string
    {
        $ym = now()->format('Ym');
        if ($this->created_at) {
            $ym = $this->created_at->format('Ym');
        } elseif (! empty($this->date)) {
            $ym = \Carbon\Carbon::parse($this->date)->format('Ym');
        }

        $seq = str_pad((string) ((int) ($this->id_overtime_requests ?? 0)), 6, '0', STR_PAD_LEFT);

        return "OVR-{$ym}-{$seq}";
    }

    public function getAttachmentUrlAttribute(): ?string
    {
        if (empty($this->attachment_path)) {
            return null;
        }

        if (str_starts_with($this->attachment_path, 'http')) {
            return $this->attachment_path;
        }

        return url('/storage/' . ltrim($this->attachment_path, '/'));
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by', 'id_users');
    }

    public function items(): HasMany
    {
        return $this->hasMany(
            OvertimeRequestItem::class,
            'id_overtime_requests',
            'id_overtime_requests'
        )->orderBy('date')->orderBy('start_time')->orderBy('id_overtime_request_items');
    }
}
