<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EmployeeShift extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'employee_shifts';
    protected $primaryKey = 'id_employee_shifts';

    protected $fillable = [
        'id_companies',
        'id_employees',
        'id_shifts',
        'date',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
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

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class, 'id_shifts', 'id_shifts');
    }
}
