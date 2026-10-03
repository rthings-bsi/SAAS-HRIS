<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Payroll\StorePayrollPeriodRequest;
use App\Models\PayrollPeriod;
use App\Models\PayrollSlip;
use App\Models\User;
use App\Services\Payroll\PayrollCalculationService;
use App\Services\Payroll\PayrollPdfService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class PayrollController extends Controller
{
    public function __construct(
        protected PayrollCalculationService $calculationService,
        protected PayrollPdfService $pdfService
    ) {}

    /**
     * Tampilkan daftar seluruh periode penggajian dalam perusahaan.
     */
    public function periods(): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat mengelola periode penggajian.', null, 403);
        }

        $periods = PayrollPeriod::where('id_companies', $user->id_companies)
            ->withCount('payrollSlips')
            ->orderBy('start_date', 'desc')
            ->get()
            ->map(function ($period) {
                $totalNet = (float) PayrollSlip::where('id_payroll_periods', $period->id_payroll_periods)->sum('net_salary');

                return [
                    'id_payroll_periods' => $period->id_payroll_periods,
                    'name' => $period->name,
                    'start_date' => $period->start_date?->format('Y-m-d'),
                    'end_date' => $period->end_date?->format('Y-m-d'),
                    'payment_date' => $period->payment_date?->format('Y-m-d'),
                    'status' => $period->status,
                    'total_slips' => $period->payroll_slips_count,
                    'total_net_salary' => $totalNet,
                    'created_at' => $period->created_at?->toIso8601String(),
                ];
            });

        return $this->successResponse($periods, 'Daftar periode penggajian berhasil diambil.');
    }

    /**
     * Buka periode penggajian baru.
     */
    public function storePeriod(StorePayrollPeriodRequest $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat membuat periode penggajian.', null, 403);
        }

        $period = PayrollPeriod::create([
            'id_companies' => $user->id_companies,
            'name' => $request->validated('name'),
            'start_date' => $request->validated('start_date'),
            'end_date' => $request->validated('end_date'),
            'payment_date' => $request->validated('payment_date'),
            'status' => 'draft',
        ]);

        return $this->successResponse($period, 'Periode penggajian berhasil dibuka.', 201);
    }

    /**
     * Tampilkan detail satu periode penggajian.
     */
    public function showPeriod(int $id): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat melihat detail periode.', null, 403);
        }

        $period = PayrollPeriod::where('id_companies', $user->id_companies)
            ->where('id_payroll_periods', $id)
            ->first();

        if (! $period) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $slipsCount = PayrollSlip::where('id_payroll_periods', $id)->count();
        $totalGross = (float) PayrollSlip::where('id_payroll_periods', $id)
            ->selectRaw('SUM(basic_salary + allowance_fixed + overtime_pay) as gross')
            ->value('gross');
        $totalDeductions = (float) PayrollSlip::where('id_payroll_periods', $id)
            ->selectRaw('SUM(deduction_late + deduction_absence + deduction_other) as deductions')
            ->value('deductions');
        $totalNet = (float) PayrollSlip::where('id_payroll_periods', $id)->sum('net_salary');

        $data = [
            'id_payroll_periods' => $period->id_payroll_periods,
            'name' => $period->name,
            'start_date' => $period->start_date?->format('Y-m-d'),
            'end_date' => $period->end_date?->format('Y-m-d'),
            'payment_date' => $period->payment_date?->format('Y-m-d'),
            'status' => $period->status,
            'total_slips' => $slipsCount,
            'total_gross' => $totalGross,
            'total_deductions' => $totalDeductions,
            'total_net_salary' => $totalNet,
            'created_at' => $period->created_at?->toIso8601String(),
        ];

        return $this->successResponse($data, 'Detail periode penggajian berhasil diambil.');
    }

    /**
     * Jalankan kalkulasi gaji otomatis dari data absensi.
     */
    public function calculate(int $id): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat menjalankan kalkulasi.', null, 403);
        }

        $period = PayrollPeriod::where('id_companies', $user->id_companies)
            ->where('id_payroll_periods', $id)
            ->first();

        if (! $period) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $slips = $this->calculationService->calculate($period);

        return $this->successResponse([
            'period' => $period->fresh(),
            'slips_calculated' => $slips->count(),
            'total_net_salary' => (float) $slips->sum('net_salary'),
        ], 'Kalkulasi penggajian berhasil dilakukan.');
    }

    /**
     * Tampilkan seluruh slip gaji dalam suatu periode.
     */
    public function slips(int $id): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat meninjau rincian slip.', null, 403);
        }

        $period = PayrollPeriod::where('id_companies', $user->id_companies)
            ->where('id_payroll_periods', $id)
            ->first();

        if (! $period) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $slips = PayrollSlip::where('id_payroll_periods', $period->id_payroll_periods)
            ->with([
                'employee.user',
                'employee.department',
                'employee.jobPosition',
            ])
            ->get()
            ->map(function ($slip) {
                return [
                    'id_payroll_slips' => $slip->id_payroll_slips,
                    'id_payroll_periods' => $slip->id_payroll_periods,
                    'id_employees' => $slip->id_employees,
                    'employee' => [
                        'id_employees' => $slip->employee?->id_employees,
                        'name' => $slip->employee?->user?->name,
                        'nik' => $slip->employee?->nik,
                        'department' => $slip->employee?->department?->name,
                        'job_position' => $slip->employee?->jobPosition?->name,
                    ],
                    'basic_salary' => (float) $slip->basic_salary,
                    'allowance_fixed' => (float) $slip->allowance_fixed,
                    'overtime_pay' => (float) $slip->overtime_pay,
                    'deduction_late' => (float) $slip->deduction_late,
                    'deduction_absence' => (float) $slip->deduction_absence,
                    'deduction_other' => (float) $slip->deduction_other,
                    'net_salary' => (float) $slip->net_salary,
                    'pdf_path' => $slip->pdf_path,
                    'has_pdf' => ! empty($slip->pdf_path),
                ];
            });

        return $this->successResponse($slips, 'Rincian slip gaji berhasil diambil.');
    }

    /**
     * Finalisasi periode penggajian dan hasilkan seluruh berkas PDF.
     */
    public function finalize(int $id): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat memfinalisasi periode.', null, 403);
        }

        $period = PayrollPeriod::where('id_companies', $user->id_companies)
            ->where('id_payroll_periods', $id)
            ->first();

        if (! $period) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $count = $this->pdfService->finalizePeriod($period);

        return $this->successResponse([
            'period' => $period->fresh(),
            'slips_finalized' => $count,
        ], 'Periode penggajian berhasil dikunci dan slip PDF telah dibuat.');
    }

    /**
     * Daftar slip gaji milik karyawan yang sedang login (Mobile App).
     */
    public function mySlips(): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        $employee = $user->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $slips = PayrollSlip::where('id_employees', $employee->id_employees)
            ->with('payrollPeriod')
            ->orderBy('id_payroll_slips', 'desc')
            ->get()
            ->map(function ($slip) {
                return [
                    'id_payroll_slips' => $slip->id_payroll_slips,
                    'id_payroll_periods' => $slip->id_payroll_periods,
                    'period_name' => $slip->payrollPeriod?->name,
                    'payment_date' => $slip->payrollPeriod?->payment_date?->format('Y-m-d'),
                    'basic_salary' => (float) $slip->basic_salary,
                    'allowance_fixed' => (float) $slip->allowance_fixed,
                    'overtime_pay' => (float) $slip->overtime_pay,
                    'deduction_late' => (float) $slip->deduction_late,
                    'deduction_absence' => (float) $slip->deduction_absence,
                    'deduction_other' => (float) $slip->deduction_other,
                    'net_salary' => (float) $slip->net_salary,
                    'pdf_path' => $slip->pdf_path,
                    'status' => $slip->payrollPeriod?->status,
                ];
            });

        return $this->successResponse($slips, 'Daftar slip gaji berhasil diambil.');
    }

    /**
     * Unduh slip gaji milik karyawan yang sedang login.
     */
    public function downloadMySlip(int $id): BinaryFileResponse|JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        $employee = $user->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $slip = PayrollSlip::where('id_employees', $employee->id_employees)
            ->where('id_payroll_slips', $id)
            ->first();

        if (! $slip) {
            return $this->errorResponse('Slip gaji tidak ditemukan.', null, 404);
        }

        return $this->serveSlipPdf($slip);
    }

    /**
     * Unduh slip gaji oleh HR atau Owner.
     */
    public function downloadSlip(int $id): BinaryFileResponse|JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat mengunduh berkas slip gaji ini.', null, 403);
        }

        $slip = PayrollSlip::where('id_companies', $user->id_companies)
            ->where('id_payroll_slips', $id)
            ->first();

        if (! $slip) {
            return $this->errorResponse('Slip gaji tidak ditemukan.', null, 404);
        }

        return $this->serveSlipPdf($slip);
    }

    /**
     * Helper untuk melayani berkas PDF slip gaji (menghasilkan berkas jika belum ada).
     */
    protected function serveSlipPdf(PayrollSlip $slip): BinaryFileResponse|JsonResponse
    {
        if (empty($slip->pdf_path) || ! Storage::disk('public')->exists($slip->pdf_path)) {
            $this->pdfService->generateSlipPdf($slip);
            $slip->refresh();
        }

        $filePath = Storage::disk('public')->path($slip->pdf_path);

        if (! file_exists($filePath)) {
            return $this->errorResponse('Berkas slip gaji tidak ditemukan.', null, 404);
        }

        $periodName = preg_replace('/[^a-zA-Z0-9_-]/', '_', $slip->payrollPeriod?->name ?? 'Gaji');
        $fileName = "Slip_Gaji_{$periodName}_{$slip->id_employees}.pdf";

        return response()->download($filePath, $fileName, [
            'Content-Type' => 'application/pdf',
        ]);
    }
}
