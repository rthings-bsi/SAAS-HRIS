<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PerformanceCriterion extends Model
{
    use HasFactory;

    protected $table = 'performance_criteria';
    protected $primaryKey = 'id_performance_criteria';

    protected $fillable = [
        'code',
        'name',
        'type',
        'weight',
        'c_min',
        'c_max',
        'source_type',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'weight' => 'decimal:2',
            'c_min' => 'decimal:2',
            'c_max' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function evaluationDetails(): HasMany
    {
        return $this->hasMany(PerformanceEvaluationDetail::class, 'id_performance_criteria', 'id_performance_criteria');
    }

    public static function seedDefaults(): void
    {
        $defaults = [
            [
                'code' => 'K1',
                'name' => 'Pencapaian KPI / Target Kerja',
                'type' => 'benefit',
                'weight' => 40.00,
                'c_min' => 0.00,
                'c_max' => 100.00,
                'source_type' => 'manual',
                'is_active' => true,
            ],
            [
                'code' => 'K2',
                'name' => 'Kehadiran / Persentase Presensi',
                'type' => 'benefit',
                'weight' => 30.00,
                'c_min' => 0.00,
                'c_max' => 100.00,
                'source_type' => 'attendance',
                'is_active' => true,
            ],
            [
                'code' => 'K3',
                'name' => 'Attitude & Kerjasama Tim',
                'type' => 'benefit',
                'weight' => 20.00,
                'c_min' => 0.00,
                'c_max' => 100.00,
                'source_type' => 'manual',
                'is_active' => true,
            ],
            [
                'code' => 'K4',
                'name' => 'Jumlah SP / Pelanggaran',
                'type' => 'cost',
                'weight' => 10.00,
                'c_min' => 0.00,
                'c_max' => 3.00,
                'source_type' => 'manual',
                'is_active' => true,
            ],
        ];

        foreach ($defaults as $item) {
            static::updateOrCreate(['code' => $item['code']], $item);
        }
    }
}
