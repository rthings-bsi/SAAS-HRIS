<?php

namespace App\Services\Performance;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\PerformanceEvaluation;
use App\Models\PerformancePeriod;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class SmartCalculationService
{
    public function pullAttendancePercentage(Employee $employee, string $startDate, string $endDate): float
    {
        $start = Carbon::parse($startDate)->startOfDay();
        $end = Carbon::parse($endDate)->endOfDay();
        $workDays = max(1, $start->diffInDaysFiltered(fn (Carbon $d) => ! $d->isWeekend(), $end) + 1);

        $attendedDays = Attendance::where('id_employees', $employee->id_employees)
            ->whereBetween('date', [$startDate, $endDate])
            ->whereIn('status', ['on_time', 'late', 'early_leave'])
            ->count();

        return min(100.0, round(($attendedDays / $workDays) * 100, 2));
    }

    public function syncEmployeesForPeriod(PerformancePeriod $period): int
    {
        $employees = Employee::where(function ($q) {
            $q->whereHas('user', fn ($u) => $u->where('is_active', true))
                ->orDoesntHave('user');
        })->get();

        $criteria = $period->getCriteriaList();
        $attendanceCriterion = $criteria->firstWhere('source_type', 'attendance');

        $count = 0;

        DB::transaction(function () use ($employees, $period, $criteria, $attendanceCriterion, &$count) {
            foreach ($employees as $emp) {
                $eval = PerformanceEvaluation::firstOrCreate(
                    [
                        'id_performance_periods' => $period->id_performance_periods,
                        'id_employees' => $emp->id_employees,
                    ]
                );

                $breakdown = $eval->scores_breakdown ?? [];
                $breakdownByCrit = collect($breakdown)->keyBy('id_performance_criteria');

                $newBreakdown = [];
                foreach ($criteria as $c) {
                    $c = (object) $c;
                    $existing = $breakdownByCrit->get($c->id_performance_criteria);
                    $rawScore = $existing ? (float) ($existing['raw_score'] ?? 0) : 0.0;

                    if ($attendanceCriterion && $c->id_performance_criteria === $attendanceCriterion->id_performance_criteria) {
                        $rawScore = $this->pullAttendancePercentage(
                            $emp,
                            $period->start_date->format('Y-m-d'),
                            $period->end_date->format('Y-m-d')
                        );
                    }

                    $newBreakdown[] = [
                        'id_performance_criteria' => $c->id_performance_criteria,
                        'criterion_code' => $c->code,
                        'criterion_name' => $c->name,
                        'type' => $c->type,
                        'weight' => (float) $c->weight,
                        'c_min' => (float) $c->c_min,
                        'c_max' => (float) $c->c_max,
                        'source_type' => $c->source_type,
                        'raw_score' => $rawScore,
                        'normalized_weight' => 0.0,
                        'utility_score' => 0.0,
                        'weighted_score' => 0.0,
                    ];
                }

                $eval->update(['scores_breakdown' => $newBreakdown]);
                $count++;
            }
        });

        return $count;
    }

    public function calculatePeriod(PerformancePeriod $period): array
    {
        if ($period->status === 'finalized') {
            throw new InvalidArgumentException('Periode telah final, tidak dapat dihitung ulang.');
        }

        $criteria = $period->getCriteriaList()->where('is_active', true);
        $sumWeight = (float) $criteria->sum('weight');

        if ($sumWeight <= 0) {
            throw new InvalidArgumentException('Total bobot kriteria harus lebih besar dari 0.');
        }

        $evaluations = PerformanceEvaluation::where('id_performance_periods', $period->id_performance_periods)
            ->with(['employee.user'])
            ->get();

        if ($evaluations->isEmpty()) {
            throw new InvalidArgumentException('Belum ada data evaluasi karyawan pada periode ini.');
        }

        DB::transaction(function () use ($criteria, $sumWeight, $evaluations, $period) {
            $results = [];

            foreach ($evaluations as $eval) {
                $vA = 0.0;
                $currentBreakdown = collect($eval->scores_breakdown ?? [])->keyBy('id_performance_criteria');
                $updatedBreakdown = [];

                foreach ($criteria as $c) {
                    $c = (object) $c;
                    $item = $currentBreakdown->get($c->id_performance_criteria);
                    $cOut = $item ? (float) ($item['raw_score'] ?? 0) : 0.0;
                    $wNorm = (float) ($c->weight / $sumWeight);

                    $span = (float) ($c->c_max - $c->c_min);
                    if ($span <= 0) {
                        $utility = 100.0;
                    } elseif ($c->type === 'cost') {
                        $utility = (($c->c_max - $cOut) / $span) * 100;
                    } else {
                        $utility = (($cOut - $c->c_min) / $span) * 100;
                    }

                    $utility = max(0.0, min(100.0, round($utility, 2)));
                    $weighted = round(($wNorm * $utility), 2);
                    $vA += $weighted;

                    $updatedBreakdown[] = [
                        'id_performance_criteria' => $c->id_performance_criteria,
                        'criterion_code' => $c->code,
                        'criterion_name' => $c->name,
                        'type' => $c->type,
                        'weight' => (float) $c->weight,
                        'c_min' => (float) $c->c_min,
                        'c_max' => (float) $c->c_max,
                        'source_type' => $c->source_type,
                        'raw_score' => $cOut,
                        'normalized_weight' => round($wNorm, 4),
                        'utility_score' => $utility,
                        'weighted_score' => $weighted,
                    ];
                }

                $finalScore = min(100.0, round($vA, 2));
                [$grade, $recommendation] = $this->resolveGradeAndRecommendation($finalScore);

                $eval->update([
                    'final_score' => $finalScore,
                    'grade' => $grade,
                    'recommendation' => $recommendation,
                    'scores_breakdown' => $updatedBreakdown,
                ]);

                $results[] = $eval;
            }

            // Assign ranks descending by final_score
            usort($results, fn ($a, $b) => ($b->final_score <=> $a->final_score) ?: ($a->id_employees <=> $b->id_employees));

            foreach ($results as $index => $eval) {
                $eval->update(['rank' => $index + 1]);
            }

            $period->update(['status' => 'calculated']);
        });

        return PerformanceEvaluation::where('id_performance_periods', $period->id_performance_periods)
            ->with(['employee.user'])
            ->orderBy('rank', 'asc')
            ->get()
            ->toArray();
    }

    public function resolveGradeAndRecommendation(float $score): array
    {
        return match (true) {
            $score >= 85.0 => ['Sangat Baik', 'Rekomendasi Kenaikan Gaji / Promosi'],
            $score >= 70.0 => ['Baik', 'Memenuhi Standar Perusahaan'],
            $score >= 55.0 => ['Cukup', 'Perlu Pembinaan / Monitoring'],
            default => ['Kurang', 'Diberikan Peringatan / Evaluasi Ulang'],
        };
    }
}
