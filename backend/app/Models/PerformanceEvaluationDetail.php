<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PerformanceEvaluationDetail extends Model
{
    use HasFactory;

    protected $table = 'performance_evaluation_details';
    protected $primaryKey = 'id_performance_evaluation_details';

    protected $fillable = [
        'id_performance_evaluations',
        'id_performance_criteria',
        'raw_score',
        'normalized_weight',
        'utility_score',
        'weighted_score',
    ];

    protected function casts(): array
    {
        return [
            'raw_score' => 'decimal:2',
            'normalized_weight' => 'decimal:4',
            'utility_score' => 'decimal:2',
            'weighted_score' => 'decimal:2',
        ];
    }

    public function evaluation(): BelongsTo
    {
        return $this->belongsTo(PerformanceEvaluation::class, 'id_performance_evaluations', 'id_performance_evaluations');
    }

    public function criterion(): BelongsTo
    {
        return $this->belongsTo(PerformanceCriterion::class, 'id_performance_criteria', 'id_performance_criteria');
    }
}
