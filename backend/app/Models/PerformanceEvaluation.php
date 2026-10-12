<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PerformanceEvaluation extends Model
{
    use HasFactory;

    protected $table = 'performance_evaluations';
    protected $primaryKey = 'id_performance_evaluations';

    protected $fillable = [
        'id_performance_periods',
        'id_employees',
        'final_score',
        'rank',
        'grade',
        'recommendation',
        'notes',
        'evaluated_by',
    ];

    protected function casts(): array
    {
        return [
            'final_score' => 'decimal:2',
            'rank' => 'integer',
        ];
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(PerformancePeriod::class, 'id_performance_periods', 'id_performance_periods');
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }

    public function evaluator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'evaluated_by', 'id_users');
    }

    public function details(): HasMany
    {
        return $this->hasMany(PerformanceEvaluationDetail::class, 'id_performance_evaluations', 'id_performance_evaluations');
    }
}
