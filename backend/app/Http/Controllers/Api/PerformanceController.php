<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PerformanceCriterion;
use App\Models\PerformanceEvaluation;
use App\Models\PerformanceEvaluationDetail;
use App\Models\PerformancePeriod;
use App\Services\Performance\SmartCalculationService;
use Barryvdh\DomPDF\Facade\Pdf;
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
        if (PerformanceCriterion::count() === 0) {
            PerformanceCriterion::seedDefaults();
        }

        $criteria = PerformanceCriterion::orderBy('code', 'asc')->get();

        return $this->successResponse($criteria, 'Daftar kriteria penilaian kinerja berhasil diambil.');
    }

    public function storeCriterion(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|max:20|unique:performance_criteria,code',
            'name' => 'required|string|max:100',
            'type' => 'required|in:benefit,cost',
            'weight' => 'required|numeric|min:0.01|max:100',
            'c_min' => 'required|numeric',
            'c_max' => 'required|numeric|gt:c_min',
            'source_type' => 'nullable|in:manual,attendance',
        ], [
            'code.required' => 'Kode kriteria wajib diisi.',
            'code.unique' => 'Kode kriteria sudah digunakan.',
            'name.required' => 'Nama kriteria wajib diisi.',
            'weight.required' => 'Bobot kriteria wajib diisi.',
            'c_max.gt' => 'Nilai C_max harus lebih besar dari C_min.',
        ]);

        $criterion = PerformanceCriterion::create($validated);

        return $this->successResponse($criterion, 'Kriteria berhasil ditambahkan.', 201);
    }

    public function updateCriterion(Request $request, int $id): JsonResponse
    {
        $criterion = PerformanceCriterion::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:100',
            'type' => 'sometimes|in:benefit,cost',
            'weight' => 'sometimes|numeric|min:0.01|max:100',
            'c_min' => 'sometimes|numeric',
            'c_max' => 'sometimes|numeric',
            'is_active' => 'sometimes|boolean',
        ]);

        $criterion->update($validated);

        return $this->successResponse($criterion, 'Kriteria berhasil diperbarui.');
    }

    public function resetDefaultCriteria(): JsonResponse
    {
        PerformanceCriterion::seedDefaults();
        $criteria = PerformanceCriterion::orderBy('code', 'asc')->get();

        return $this->successResponse($criteria, 'Kriteria berhasil direset ke standar default.');
    }

    public function periods(): JsonResponse
    {
        $periods = PerformancePeriod::withCount('evaluations')
            ->orderBy('start_date', 'desc')
            ->get();

        return $this->successResponse($periods, 'Daftar periode penilaian berhasil diambil.');
    }

    public function storePeriod(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ], [
            'name.required' => 'Nama periode wajib diisi.',
            'start_date.required' => 'Tanggal mulai wajib diisi.',
            'end_date.required' => 'Tanggal akhir wajib diisi.',
            'end_date.after_or_equal' => 'Tanggal akhir harus sama atau setelah tanggal mulai.',
        ]);

        $period = PerformancePeriod::create($validated);

        // Auto-seed default criteria if not yet present
        if (PerformanceCriterion::count() === 0) {
            PerformanceCriterion::seedDefaults();
        }

        // Auto-sync active employees into the period
        $this->smartService->syncEmployeesForPeriod($period);

        return $this->successResponse($period, 'Periode penilaian berhasil dibuat dan pegawai telah disinkronkan.', 201);
    }

    public function showPeriod(int $id): JsonResponse
    {
        $period = PerformancePeriod::withCount('evaluations')->findOrFail($id);
        $criteria = PerformanceCriterion::where('is_active', true)->orderBy('code', 'asc')->get();

        $evaluations = PerformanceEvaluation::where('id_performance_periods', $period->id_performance_periods)
            ->with(['employee.user', 'employee.department', 'employee.jobPosition', 'details.criterion'])
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
            'scores.*.id_performance_criteria' => 'required|exists:performance_criteria,id_performance_criteria',
            'scores.*.raw_score' => 'required|numeric|min:0',
        ]);

        DB::transaction(function () use ($validated) {
            foreach ($validated['scores'] as $item) {
                PerformanceEvaluationDetail::updateOrCreate(
                    [
                        'id_performance_evaluations' => $item['id_performance_evaluations'],
                        'id_performance_criteria' => $item['id_performance_criteria'],
                    ],
                    [
                        'raw_score' => $item['raw_score'],
                    ]
                );
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
        $criteria = PerformanceCriterion::where('is_active', true)->orderBy('code', 'asc')->get();

        $evaluations = PerformanceEvaluation::where('id_performance_periods', $period->id_performance_periods)
            ->with(['employee.user', 'employee.department', 'employee.jobPosition', 'details.criterion'])
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
