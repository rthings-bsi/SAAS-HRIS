<?php

namespace App\Services\Payroll;

use App\Exceptions\PayrollException;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\OvertimeRequest;
use App\Models\PayrollSlip;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class PayrollCalculationService
{
    /**
     * Hitung gaji seluruh karyawan aktif dalam satu periode penggajian.
     */
    public function calculate(object $period): Collection
    {
        $status = $period->status ?? 'draft';
        if ($status === 'finalized') {
            throw new PayrollException('Periode penggajian telah dikunci (final) dan tidak dapat dihitung ulang.', 422);
        }

        $startDate = Carbon::parse($period->start_date)->startOfDay();
        $endDate = Carbon::parse($period->end_date)->endOfDay();
        $paymentDate = ! empty($period->payment_date) ? Carbon::parse($period->payment_date)->toDateString() : Carbon::now()->toDateString();
        $periodName = $period->period_name ?? $period->name ?? ('Periode ' . $startDate->isoFormat('MMMM Y'));
        $companyId = (int) $period->id_companies;

        // Hitung total hari kerja efektif (Senin - Jumat)
        $workDays = $startDate->diffInDaysFiltered(fn (Carbon $date) => ! $date->isWeekend(), $endDate) + 1;
        $workDays = max(1, $workDays);

        $employees = Employee::where('id_companies', $companyId)->get();

        if ($employees->isEmpty()) {
            throw new PayrollException('Tidak ada data karyawan pada perusahaan ini untuk diproses.', 422);
        }

        $slips = collect();

        foreach ($employees as $employee) {
            $basicSalary = (float) ($employee->basic_salary ?? 0);
            $allowanceFixed = (float) ($employee->allowance_fixed ?? 0);

            // Ambil absensi dalam rentang periode
            $attendances = Attendance::where('id_employees', $employee->id_employees)
                ->whereBetween('date', [$startDate->toDateString(), $endDate->toDateString()])
                ->get();

            // Total menit keterlambatan (potongan Rp 1.000 / menit)
            $totalLateMinutes = (int) $attendances->sum('late_duration_minutes');
            $deductionLate = (float) ($totalLateMinutes * 1000);

            // Jumlah hari hadir
            $attendedDays = $attendances->whereIn('status', ['on_time', 'late', 'early_leave'])->count();

            // Jumlah hari cuti berbayar yang telah disetujui
            $paidLeaveDays = (int) LeaveRequest::where('id_employees', $employee->id_employees)
                ->where('status', 'approved')
                ->where('is_paid', true)
                ->where(function ($q) use ($startDate, $endDate) {
                    $q->whereBetween('start_date', [$startDate->toDateString(), $endDate->toDateString()])
                        ->orWhereBetween('end_date', [$startDate->toDateString(), $endDate->toDateString()]);
                })
                ->sum('total_days');

            // Absensi tanpa keterangan (Alpha)
            $unexcusedAbsences = max(0, $workDays - ($attendedDays + $paidLeaveDays));
            $dailyRate = $basicSalary / $workDays;
            $deductionAbsence = round($dailyRate * $unexcusedAbsences, 2);

            // Upah Lembur disetujui
            $approvedOvertimeHours = (float) OvertimeRequest::where('id_employees', $employee->id_employees)
                ->where('status', 'approved')
                ->whereBetween('date', [$startDate->toDateString(), $endDate->toDateString()])
                ->sum('duration_hours');

            // Formula standar upah lembur per jam (PP 35/2021): 1/173 x (Gaji Pokok + Tunjangan Tetap)
            $hourlyRate = ($basicSalary + $allowanceFixed) > 0 ? round(($basicSalary + $allowanceFixed) / 173, 2) : 0.0;
            $overtimePay = round($hourlyRate * $approvedOvertimeHours, 2);

            $deductionOther = 0.0;

            $grossSalary = $basicSalary + $allowanceFixed + $overtimePay;
            $totalDeductions = $deductionLate + $deductionAbsence + $deductionOther;
            $netSalary = max(0.0, round($grossSalary - $totalDeductions, 2));

            $slip = PayrollSlip::updateOrCreate(
                [
                    'id_companies' => $companyId,
                    'id_employees' => $employee->id_employees,
                    'period_name' => $periodName,
                ],
                [
                    'start_date' => $startDate->toDateString(),
                    'end_date' => $endDate->toDateString(),
                    'payment_date' => $paymentDate,
                    'status' => 'calculated',
                    'basic_salary' => $basicSalary,
                    'allowance_fixed' => $allowanceFixed,
                    'overtime_pay' => $overtimePay,
                    'deduction_late' => $deductionLate,
                    'deduction_absence' => $deductionAbsence,
                    'deduction_other' => $deductionOther,
                    'net_salary' => $netSalary,
                ]
            );

            $slips->push($slip);
        }

        return $slips;
    }
}
