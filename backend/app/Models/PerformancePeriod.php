<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PerformancePeriod extends Model
{
    use HasFactory;

    protected $table = 'performance_periods';
    protected $primaryKey = 'id_performance_periods';

    protected $fillable = [
        'name',
        'start_date',
        'end_date',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
        ];
    }

    public function evaluations(): HasMany
    {
        return $this->hasMany(PerformanceEvaluation::class, 'id_performance_periods', 'id_performance_periods');
    }
}
