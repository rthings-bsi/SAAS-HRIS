<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Collection;

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
        'criteria_config',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'criteria_config' => 'array',
        ];
    }

    public static function defaultCriteria(): array
    {
        return [
            [
                'id_performance_criteria' => 1,
                'code' => 'K1',
                'name' => 'Pencapaian KPI',
                'type' => 'benefit',
                'weight' => 40.0,
                'c_min' => 0.0,
                'c_max' => 100.0,
                'source_type' => 'manual',
                'is_active' => true,
            ],
            [
                'id_performance_criteria' => 2,
                'code' => 'K2',
                'name' => 'Kehadiran Presensi',
                'type' => 'benefit',
                'weight' => 30.0,
                'c_min' => 0.0,
                'c_max' => 100.0,
                'source_type' => 'attendance',
                'is_active' => true,
            ],
            [
                'id_performance_criteria' => 3,
                'code' => 'K3',
                'name' => 'Kedisiplinan & Sikap Kerja',
                'type' => 'benefit',
                'weight' => 20.0,
                'c_min' => 0.0,
                'c_max' => 100.0,
                'source_type' => 'manual',
                'is_active' => true,
            ],
            [
                'id_performance_criteria' => 4,
                'code' => 'K4',
                'name' => 'Pelanggaran & Surat Peringatan',
                'type' => 'cost',
                'weight' => 10.0,
                'c_min' => 0.0,
                'c_max' => 100.0,
                'source_type' => 'manual',
                'is_active' => true,
            ],
        ];
    }

    public function getCriteriaList(): Collection
    {
        $raw = $this->criteria_config ?? self::defaultCriteria();

        return collect($raw)->map(function ($item, $idx) {
            $obj = (object) $item;
            if (! isset($obj->id_performance_criteria)) {
                $obj->id_performance_criteria = $idx + 1;
            }
            $obj->weight = (float) ($obj->weight ?? 0);
            $obj->c_min = (float) ($obj->c_min ?? 0);
            $obj->c_max = (float) ($obj->c_max ?? 100);
            $obj->is_active = (bool) ($obj->is_active ?? true);

            return $obj;
        });
    }

    public function evaluations(): HasMany
    {
        return $this->hasMany(PerformanceEvaluation::class, 'id_performance_periods', 'id_performance_periods');
    }
}
