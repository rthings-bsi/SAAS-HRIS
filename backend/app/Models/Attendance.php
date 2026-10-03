<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Attendance extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'attendances';
    protected $primaryKey = 'id_attendances';

    protected $fillable = [
        'id_companies',
        'id_employees',
        'date',
        'clock_in_time',
        'clock_in_latitude',
        'clock_in_longitude',
        'clock_in_photo_path',
        'clock_in_distance_meters',
        'clock_out_time',
        'clock_out_latitude',
        'clock_out_longitude',
        'clock_out_photo_path',
        'clock_out_distance_meters',
        'status',
        'late_duration_minutes',
        'early_leave_minutes',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date:Y-m-d',
            'clock_in_latitude' => 'float',
            'clock_in_longitude' => 'float',
            'clock_out_latitude' => 'float',
            'clock_out_longitude' => 'float',
            'clock_in_distance_meters' => 'integer',
            'clock_out_distance_meters' => 'integer',
            'late_duration_minutes' => 'integer',
            'early_leave_minutes' => 'integer',
        ];
    }

    public function setDateAttribute($value): void
    {
        $this->attributes['date'] = $value ? \Carbon\Carbon::parse($value)->format('Y-m-d') : null;
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }
}
