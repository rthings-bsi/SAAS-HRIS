<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Payroll\StorePayrollPeriodRequest;
use App\Models\Employee;
use App\Models\PayrollSlip;
use App\Services\Payroll\PayrollCalculationService;
use App\Services\Payroll\PayrollPdfService;
use Carbon\Carbon;
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

        $periods = PayrollSlip::where('id_companies', $user->id_companies)
            ->select('period_name', 'start_date', 'end_date', 'payment_date', 'status')
            ->selectRaw('MIN(id_payroll_slips) as id_payroll_periods')
            ->selectRaw('COUNT(*) as total_slips')
            ->selectRaw('SUM(net_salary) as total_net_salary')
            ->selectRaw('MAX(created_at) as created_at')
            ->groupBy('period_name', 'start_date', 'end_date', 'payment_date', 'status')
            ->orderByDesc('start_date')
            ->get()
            ->map(function ($period) {
                return [
                    'id_payroll_periods' => (int) $period->id_payroll_periods,
                    'name' => $period->period_name,
                    'start_date' => $period->start_date ? Carbon::parse($period->start_date)->format('Y-m-d') : null,
                    'end_date' => $period->end_date ? Carbon::parse($period->end_date)->format('Y-m-d') : null,
                    'payment_date' => $period->payment_date ? Carbon::parse($period->payment_date)->format('Y-m-d') : null,
                    'status' => $period->status,
                    'total_slips' => (int) $period->total_slips,
                    'total_net_salary' => (float) $period->total_net_salary,
                    'created_at' => $period->created_at ? Carbon::parse($period->created_at)->toIso8601String() : null,
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

        $employees = Employee::where('id_companies', $user->id_companies)->get();
        $name = $request->validated('name');
        $startDate = $request->validated('start_date');
        $endDate = $request->validated('end_date');
        $paymentDate = $request->validated('payment_date');

        $firstSlip = null;
        foreach ($employees as $employee) {
            $basicSalary = (float) ($employee->basic_salary ?? 0);
            $allowanceFixed = (float) ($employee->allowance_fixed ?? 0);
            $netSalary = $basicSalary + $allowanceFixed;

            $slip = PayrollSlip::create([
                'id_companies' => $user->id_companies,
                'id_employees' => $employee->id_employees,
                'period_name' => $name,
                'start_date' => $startDate,
                'end_date' => $endDate,
                'payment_date' => $paymentDate,
                'status' => 'draft',
                'basic_salary' => $basicSalary,
                'allowance_fixed' => $allowanceFixed,
                'overtime_pay' => 0,
                'deduction_late' => 0,
                'deduction_absence' => 0,
                'deduction_other' => 0,
                'net_salary' => $netSalary,
            ]);

            if (! $firstSlip) {
                $firstSlip = $slip;
            }
        }

        $periodData = [
            'id_payroll_periods' => $firstSlip ? $firstSlip->id_payroll_slips : 1,
            'name' => $name,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'payment_date' => $paymentDate,
            'status' => 'draft',
        ];

        return $this->successResponse($periodData, 'Periode penggajian berhasil dibuka.', 201);
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

        $refSlip = PayrollSlip::where('id_companies', $user->id_companies)->find($id);

        if (! $refSlip) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $periodQuery = PayrollSlip::where('id_companies', $user->id_companies)
            ->where('period_name', $refSlip->period_name);

        $slipsCount = (clone $periodQuery)->count();
        $totalGross = (float) (clone $periodQuery)->selectRaw('SUM(basic_salary + allowance_fixed + overtime_pay) as gross')->value('gross');
        $totalDeductions = (float) (clone $periodQuery)->selectRaw('SUM(deduction_late + deduction_absence + deduction_other) as deductions')->value('deductions');
        $totalNet = (float) (clone $periodQuery)->sum('net_salary');

        $data = [
            'id_payroll_periods' => $refSlip->id_payroll_slips,
            'name' => $refSlip->period_name,
            'start_date' => $refSlip->start_date ? $refSlip->start_date->format('Y-m-d') : null,
            'end_date' => $refSlip->end_date ? $refSlip->end_date->format('Y-m-d') : null,
            'payment_date' => $refSlip->payment_date ? $refSlip->payment_date->format('Y-m-d') : null,
            'status' => $refSlip->status,
            'total_slips' => $slipsCount,
            'total_gross' => $totalGross,
            'total_deductions' => $totalDeductions,
            'total_net_salary' => $totalNet,
            'created_at' => $refSlip->created_at ? $refSlip->created_at->toIso8601String() : null,
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

        $refSlip = PayrollSlip::where('id_companies', $user->id_companies)->find($id);

        if (! $refSlip) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $slips = $this->calculationService->calculate($refSlip);

        $periodData = [
            'id_payroll_periods' => $refSlip->id_payroll_slips,
            'name' => $refSlip->period_name,
            'start_date' => $refSlip->start_date ? $refSlip->start_date->format('Y-m-d') : null,
            'end_date' => $refSlip->end_date ? $refSlip->end_date->format('Y-m-d') : null,
            'payment_date' => $refSlip->payment_date ? $refSlip->payment_date->format('Y-m-d') : null,
            'status' => 'calculated',
        ];

        return $this->successResponse([
            'period' => $periodData,
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

        $refSlip = PayrollSlip::where('id_companies', $user->id_companies)->find($id);

        if (! $refSlip) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $slips = PayrollSlip::where('id_companies', $user->id_companies)
            ->where('period_name', $refSlip->period_name)
            ->with(['employee.user'])
            ->get()
            ->map(function ($slip) {
                return [
                    'id_payroll_slips' => $slip->id_payroll_slips,
                    'id_payroll_periods' => $slip->id_payroll_slips,
                    'id_employees' => $slip->id_employees,
                    'employee' => [
                        'id_employees' => $slip->employee?->id_employees,
                        'name' => $slip->employee?->user?->name,
                        'nik' => $slip->employee?->nik,
                        'department' => $slip->employee?->department_name,
                        'job_position' => $slip->employee?->job_position_name,
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

        $refSlip = PayrollSlip::where('id_companies', $user->id_companies)->find($id);

        if (! $refSlip) {
            return $this->errorResponse('Periode penggajian tidak ditemukan.', null, 404);
        }

        $count = $this->pdfService->finalizePeriod($refSlip);

        $periodData = [
            'id_payroll_periods' => $refSlip->id_payroll_slips,
            'name' => $refSlip->period_name,
            'start_date' => $refSlip->start_date ? $refSlip->start_date->format('Y-m-d') : null,
            'end_date' => $refSlip->end_date ? $refSlip->end_date->format('Y-m-d') : null,
            'payment_date' => $refSlip->payment_date ? $refSlip->payment_date->format('Y-m-d') : null,
            'status' => 'finalized',
        ];

        return $this->successResponse([
            'period' => $periodData,
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
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $slips = PayrollSlip::where('id_employees', $employee->id_employees)
            ->orderBy('id_payroll_slips', 'desc')
            ->get()
            ->map(function ($slip) {
                return [
                    'id_payroll_slips' => $slip->id_payroll_slips,
                    'id_payroll_periods' => $slip->id_payroll_slips,
                    'period_name' => $slip->period_name,
                    'payment_date' => $slip->payment_date ? $slip->payment_date->format('Y-m-d') : null,
                    'basic_salary' => (float) $slip->basic_salary,
                    'allowance_fixed' => (float) $slip->allowance_fixed,
                    'overtime_pay' => (float) $slip->overtime_pay,
                    'deduction_late' => (float) $slip->deduction_late,
                    'deduction_absence' => (float) $slip->deduction_absence,
                    'deduction_other' => (float) $slip->deduction_other,
                    'net_salary' => (float) $slip->net_salary,
                    'pdf_path' => $slip->pdf_path,
                    'status' => $slip->status,
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
        $employee = $user?->employee;

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

        $periodName = preg_replace('/[^a-zA-Z0-9_-]/', '_', $slip->period_name ?? 'Gaji');
        $fileName = "Slip_Gaji_{$periodName}_{$slip->id_employees}.pdf";

        return response()->download($filePath, $fileName, [
            'Content-Type' => 'application/pdf',
        ]);
    }
}
