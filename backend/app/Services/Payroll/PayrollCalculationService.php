<?php

namespace App\Services\Payroll;

use App\Exceptions\PayrollException;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\PayrollPeriod;
use App\Models\PayrollSlip;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class PayrollCalculationService
{
    /**
     * Hitung gaji seluruh karyawan aktif dalam satu periode penggajian.
     */
    public function calculate(PayrollPeriod $period): Collection
    {
        if ($period->status === 'finalized') {
            throw new PayrollException('Periode penggajian telah dikunci (final) dan tidak dapat dihitung ulang.', 422);
        }

        $startDate = Carbon::parse($period->start_date)->startOfDay();
        $endDate = Carbon::parse($period->end_date)->endOfDay();

        // Hitung total hari kerja efektif (Senin - Jumat)
        $workDays = $startDate->diffInDaysFiltered(fn (Carbon $date) => ! $date->isWeekend(), $endDate) + 1;
        $workDays = max(1, $workDays);

        $employees = Employee::where('id_companies', $period->id_companies)->get();

        if ($employees->isEmpty()) {
            throw new PayrollException('Tidak ada data karyawan pada perusahaan ini untuk diproses.', 422);
        }

        $slips = collect();

        foreach ($employees as $employee) {
            $basicSalary = (float) ($employee->basic_salary ?? 0);
            $allowanceFixed = (float) ($employee->allowance_fixed ?? 0);

            // Ambil absensi dalam rentang periode
            $attendances = Attendance::where('id_employees', $employee->id_employees)
                ->whereBetween('date', [$period->start_date, $period->end_date])
                ->get();

            // Total menit keterlambatan (potongan Rp 1.000 / menit)
            $totalLateMinutes = (int) $attendances->sum('late_duration_minutes');
            $deductionLate = (float) ($totalLateMinutes * 1000);

            // Jumlah hari hadir
            $attendedDays = $attendances->whereIn('status', ['on_time', 'late', 'early_leave'])->count();

            // Jumlah hari cuti berbayar yang telah disetujui
            $paidLeaveDays = (int) LeaveRequest::where('id_employees', $employee->id_employees)
                ->where('status', 'approved')
                ->whereHas('leaveType', fn ($q) => $q->where('is_paid', true))
                ->where(function ($q) use ($period) {
                    $q->whereBetween('start_date', [$period->start_date, $period->end_date])
                        ->orWhereBetween('end_date', [$period->start_date, $period->end_date]);
                })
                ->sum('total_days');

            // Absensi tanpa keterangan (Alpha)
            $unexcusedAbsences = max(0, $workDays - ($attendedDays + $paidLeaveDays));
            $dailyRate = $basicSalary / $workDays;
            $deductionAbsence = round($dailyRate * $unexcusedAbsences, 2);

            $overtimePay = 0.0;
            $deductionOther = 0.0;

            $grossSalary = $basicSalary + $allowanceFixed + $overtimePay;
            $totalDeductions = $deductionLate + $deductionAbsence + $deductionOther;
            $netSalary = max(0.0, round($grossSalary - $totalDeductions, 2));

            $slip = PayrollSlip::updateOrCreate(
                [
                    'id_payroll_periods' => $period->id_payroll_periods,
                    'id_employees' => $employee->id_employees,
                ],
                [
                    'id_companies' => $period->id_companies,
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

        $period->update(['status' => 'calculated']);

        return $slips;
    }
}
