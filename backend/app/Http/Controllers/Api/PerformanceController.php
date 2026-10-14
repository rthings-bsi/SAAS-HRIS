<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Performance\StorePerformancePeriodRequest;
use App\Models\PerformanceEvaluation;
use App\Models\PerformancePeriod;
use App\Services\Performance\SmartCalculationService;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Throwable;

class PerformanceController extends Controller
{
    public function __construct(
        protected SmartCalculationService $smartService
    ) {}

    public function criteria(): JsonResponse
    {
        $latestPeriod = PerformancePeriod::orderBy('id_performance_periods', 'desc')->first();
        $criteria = $latestPeriod ? $latestPeriod->getCriteriaList() : collect(PerformancePeriod::defaultCriteria());

        return $this->successResponse($criteria, 'Daftar kriteria penilaian kinerja berhasil diambil.');
    }

    public function storeCriterion(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|max:20',
            'name' => 'required|string|max:100',
            'type' => 'required|in:benefit,cost',
            'weight' => 'required|numeric|min:0.01|max:100',
            'c_min' => 'required|numeric',
            'c_max' => 'required|numeric|gt:c_min',
            'source_type' => 'nullable|in:manual,attendance',
        ]);

        $period = PerformancePeriod::orderBy('id_performance_periods', 'desc')->first();
        if ($period) {
            $criteria = $period->getCriteriaList()->toArray();
            $maxId = collect($criteria)->max('id_performance_criteria') ?? 0;
            $validated['id_performance_criteria'] = $maxId + 1;
            $validated['is_active'] = true;
            $criteria[] = $validated;
            $period->update(['criteria_config' => $criteria]);
        }

        return $this->successResponse($validated, 'Kriteria berhasil ditambahkan.', 201);
    }

    public function updateCriterion(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:100',
            'type' => 'sometimes|in:benefit,cost',
            'weight' => 'sometimes|numeric|min:0.01|max:100',
            'c_min' => 'sometimes|numeric',
            'c_max' => 'sometimes|numeric',
            'is_active' => 'sometimes|boolean',
        ]);

        $period = PerformancePeriod::orderBy('id_performance_periods', 'desc')->first();
        if ($period) {
            $criteria = $period->getCriteriaList()->map(function ($c) use ($id, $validated) {
                if ($c->id_performance_criteria == $id) {
                    return array_merge((array) $c, $validated);
                }

                return (array) $c;
            })->toArray();

            $period->update(['criteria_config' => $criteria]);
        }

        return $this->successResponse($validated, 'Kriteria berhasil diperbarui.');
    }

    public function resetDefaultCriteria(): JsonResponse
    {
        $default = PerformancePeriod::defaultCriteria();
        $period = PerformancePeriod::orderBy('id_performance_periods', 'desc')->first();
        if ($period) {
            $period->update(['criteria_config' => $default]);
        }

        return $this->successResponse($default, 'Kriteria berhasil direset ke standar default.');
    }

    public function periods(): JsonResponse
    {
        $periods = PerformancePeriod::withCount('evaluations')
            ->orderBy('start_date', 'desc')
            ->get();

        return $this->successResponse($periods, 'Daftar periode penilaian berhasil diambil.');
    }

    public function storePeriod(StorePerformancePeriodRequest $request): JsonResponse
    {
        $user = $request->user();
        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin', 'super_admin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin untuk membuka periode penilaian.', null, 403);
        }

        $name = trim($request->validated('name'));
        $startDate = $request->validated('start_date');
        $endDate = $request->validated('end_date');

        // Validasi 1: Cegah pembuatan periode dengan nama yang sama persis
        $nameExists = PerformancePeriod::whereRaw('LOWER(name) = ?', [strtolower($name)])->exists();
        if ($nameExists) {
            return $this->errorResponse("Nama periode '{$name}' sudah digunakan. Silakan gunakan nama periode yang berbeda.", [
                'name' => ["Nama periode '{$name}' sudah digunakan."],
            ], 422);
        }

        // Validasi 2: Cegah pembuatan periode pada tanggal yang sama atau saling tumpang tindih (overlap)
        $overlapPeriod = PerformancePeriod::where(function ($q) use ($startDate, $endDate) {
            $q->where('start_date', '<=', $endDate)
              ->where('end_date', '>=', $startDate);
        })->first();

        if ($overlapPeriod) {
            $overlapStart = Carbon::parse($overlapPeriod->start_date)->translatedFormat('d F Y');
            $overlapEnd = Carbon::parse($overlapPeriod->end_date)->translatedFormat('d F Y');

            return $this->errorResponse(
                "Rentang tanggal bertabrakan dengan periode '{$overlapPeriod->name}' ({$overlapStart} - {$overlapEnd}). Periode penilaian kinerja tidak boleh berada pada tanggal yang sama.",
                [
                    'start_date' => ["Rentang tanggal bertabrakan dengan periode '{$overlapPeriod->name}' ({$overlapStart} - {$overlapEnd})."],
                    'end_date' => ["Rentang tanggal bertabrakan dengan periode '{$overlapPeriod->name}' ({$overlapStart} - {$overlapEnd})."],
                ],
                422
            );
        }

        $validated = $request->validated();
        $validated['name'] = $name;
        $validated['criteria_config'] = PerformancePeriod::defaultCriteria();
        $validated['status'] = 'draft';

        $period = PerformancePeriod::create($validated);

        // Auto-sync active employees into the period
        $this->smartService->syncEmployeesForPeriod($period);

        return $this->successResponse($period, 'Periode penilaian berhasil dibuat dan pegawai telah disinkronkan.', 201);
    }

    public function destroyPeriod(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin', 'super_admin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin menghapus periode penilaian.', null, 403);
        }

        $period = PerformancePeriod::findOrFail($id);

        if ($period->status === 'finalized') {
            return $this->errorResponse('Periode yang telah disahkan (finalized) tidak dapat dihapus.', null, 422);
        }

        $period->delete();

        return $this->successResponse(null, 'Periode penilaian kinerja berhasil dihapus.');
    }

    public function showPeriod(int $id): JsonResponse
    {
        $period = PerformancePeriod::withCount('evaluations')->findOrFail($id);
        $criteria = $period->getCriteriaList()->where('is_active', true)->values();

        $evaluations = PerformanceEvaluation::where('id_performance_periods', $period->id_performance_periods)
            ->with(['employee.user'])
            ->orderByRaw('CASE WHEN `rank` IS NULL THEN 1 ELSE 0 END, `rank` ASC, id_performance_evaluations ASC')
            ->get();

        return $this->successResponse([
            'period' => $period,
            'criteria' => $criteria,
            'evaluations' => $evaluations,
        ], 'Detail periode evaluasi berhasil diambil.');
    }

    public function syncEmployees(int $id): JsonResponse
    {
        $period = PerformancePeriod::findOrFail($id);

        if ($period->status === 'finalized') {
            return $this->errorResponse('Periode telah terkunci (finalized), tidak dapat disinkronkan lagi.', null, 422);
        }

        $count = $this->smartService->syncEmployeesForPeriod($period);

        return $this->successResponse(['synced_count' => $count], "Berhasil mensinkronkan {$count} pegawai dan data presensi.");
    }

    public function saveScores(Request $request, int $id): JsonResponse
    {
        $period = PerformancePeriod::findOrFail($id);

        if ($period->status === 'finalized') {
            return $this->errorResponse('Periode telah final, tidak dapat mengubah nilai.', null, 422);
        }

        $validated = $request->validate([
            'scores' => 'required|array',
            'scores.*.id_performance_evaluations' => 'required|exists:performance_evaluations,id_performance_evaluations',
            'scores.*.id_performance_criteria' => 'required',
            'scores.*.raw_score' => 'required|numeric|min:0',
        ]);

        DB::transaction(function () use ($validated) {
            $scoresByEval = collect($validated['scores'])->groupBy('id_performance_evaluations');

            foreach ($scoresByEval as $evalId => $items) {
                $eval = PerformanceEvaluation::find($evalId);
                if (! $eval) {
                    continue;
                }

                $breakdown = $eval->scores_breakdown ?? [];
                $breakdownKeyed = collect($breakdown)->keyBy('id_performance_criteria');

                foreach ($items as $item) {
                    $critId = $item['id_performance_criteria'];
                    $rawScore = (float) $item['raw_score'];

                    if ($breakdownKeyed->has($critId)) {
                        $entry = $breakdownKeyed->get($critId);
                        $entry['raw_score'] = $rawScore;
                        $breakdownKeyed->put($critId, $entry);
                    } else {
                        $breakdownKeyed->put($critId, [
                            'id_performance_criteria' => $critId,
                            'criterion_code' => 'K' . $critId,
                            'criterion_name' => 'Kriteria ' . $critId,
                            'type' => 'benefit',
                            'weight' => 25.0,
                            'c_min' => 0.0,
                            'c_max' => 100.0,
                            'source_type' => 'manual',
                            'raw_score' => $rawScore,
                            'normalized_weight' => 0.0,
                            'utility_score' => 0.0,
                            'weighted_score' => 0.0,
                        ]);
                    }
                }

                $eval->update(['scores_breakdown' => $breakdownKeyed->values()->toArray()]);
            }
        });

        return $this->successResponse(null, 'Nilai evaluasi berhasil disimpan.');
    }

    public function calculate(int $id): JsonResponse
    {
        $period = PerformancePeriod::findOrFail($id);

        try {
            $results = $this->smartService->calculatePeriod($period);

            return $this->successResponse($results, 'Kalkulasi metode SMART berhasil dijalankan.');
        } catch (Throwable $e) {
            return $this->errorResponse($e->getMessage(), null, 422);
        }
    }

    public function finalize(int $id): JsonResponse
    {
        $period = PerformancePeriod::findOrFail($id);

        if ($period->status !== 'calculated') {
            return $this->errorResponse('Periode harus dihitung (calculated) terlebih dahulu sebelum dapat difinalisasi.', null, 422);
        }

        $period->update(['status' => 'finalized']);

        return $this->successResponse($period, 'Periode evaluasi berhasil difinalisasi dan dikunci.');
    }

    public function exportPdf(int $id)
    {
        $period = PerformancePeriod::findOrFail($id);
        $criteria = $period->getCriteriaList()->where('is_active', true)->values();

        $evaluations = PerformanceEvaluation::where('id_performance_periods', $period->id_performance_periods)
            ->with(['employee.user'])
            ->orderByRaw('CASE WHEN `rank` IS NULL THEN 1 ELSE 0 END, `rank` ASC, id_performance_evaluations ASC')
            ->get();

        $pdf = Pdf::loadView('pdf.performance_report', [
            'period' => $period,
            'criteria' => $criteria,
            'evaluations' => $evaluations,
            'generated_at' => now()->translatedFormat('d F Y H:i'),
        ])->setPaper('a4', 'landscape');

        $fileName = 'Laporan_SPK_SMART_' . str_replace(' ', '_', $period->name) . '.pdf';

        return $pdf->stream($fileName);
    }
}
