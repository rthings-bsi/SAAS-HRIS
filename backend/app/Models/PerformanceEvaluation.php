<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Collection;

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
        'scores_breakdown',
    ];

    protected $appends = [
        'details',
    ];

    protected function casts(): array
    {
        return [
            'final_score' => 'decimal:2',
            'rank' => 'integer',
            'scores_breakdown' => 'array',
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

    public function getDetailsAttribute(): Collection
    {
        $breakdown = $this->scores_breakdown ?? [];

        return collect($breakdown)->map(function ($item, $idx) {
            $itemObj = (object) $item;
            $critId = $itemObj->id_performance_criteria ?? ($idx + 1);

            $criterionObj = (object) [
                'id_performance_criteria' => $critId,
                'code' => $itemObj->criterion_code ?? ('K' . ($idx + 1)),
                'name' => $itemObj->criterion_name ?? '',
                'type' => $itemObj->type ?? 'benefit',
                'weight' => (float) ($itemObj->weight ?? 0),
                'c_min' => (float) ($itemObj->c_min ?? 0),
                'c_max' => (float) ($itemObj->c_max ?? 100),
                'source_type' => $itemObj->source_type ?? 'manual',
            ];

            $itemObj->id_performance_criteria = $critId;
            $itemObj->raw_score = (float) ($itemObj->raw_score ?? 0);
            $itemObj->normalized_weight = (float) ($itemObj->normalized_weight ?? 0);
            $itemObj->utility_score = (float) ($itemObj->utility_score ?? 0);
            $itemObj->weighted_score = (float) ($itemObj->weighted_score ?? 0);
            $itemObj->criterion = $criterionObj;

            return $itemObj;
        });
    }
}
