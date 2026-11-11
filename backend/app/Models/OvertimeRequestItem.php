<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OvertimeRequestItem extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'overtime_request_items';
    protected $primaryKey = 'id_overtime_request_items';

    protected $fillable = [
        'id_companies',
        'id_overtime_requests',
        'date',
        'end_date',
        'start_time',
        'end_time',
        'duration_hours',
    ];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'end_date' => 'date:Y-m-d',
        'duration_hours' => 'float',
    ];

    public function overtimeRequest(): BelongsTo
    {
        return $this->belongsTo(
            OvertimeRequest::class,
            'id_overtime_requests',
            'id_overtime_requests'
        );
    }
}
