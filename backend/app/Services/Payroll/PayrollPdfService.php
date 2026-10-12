<?php

namespace App\Services\Payroll;

use App\Exceptions\PayrollException;
use App\Models\PayrollSlip;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Storage;

class PayrollPdfService
{
    /**
     * Generate PDF untuk satu slip gaji dan simpan ke disk tenant.
     */
    public function generateSlipPdf(PayrollSlip $slip): string
    {
        $slip->loadMissing([
            'employee.user',
            'company',
        ]);

        $company = $slip->company;
        $period = $slip->payroll_period;
        $employee = $slip->employee;

        $pdf = Pdf::loadView('pdf.payslip', [
            'slip' => $slip,
            'company' => $company,
            'period' => $period,
            'employee' => $employee,
        ]);

        $pdf->setPaper('a4', 'portrait');

        $directory = "{$slip->id_companies}/payroll/{$slip->id_payroll_slips}";
        $filename = "slip_{$slip->id_employees}.pdf";
        $relativePath = "{$directory}/{$filename}";

        Storage::disk('public')->put($relativePath, $pdf->output());

        $slip->update(['pdf_path' => $relativePath]);

        return $relativePath;
    }

    /**
     * Finalisasi periode penggajian: generate PDF seluruh slip dan kunci status ke 'finalized'.
     */
    public function finalizePeriod(object $period): int
    {
        $status = $period->status ?? 'calculated';
        if ($status === 'finalized') {
            throw new PayrollException('Periode penggajian sudah difinalisasi sebelumnya.', 422);
        }

        $periodName = $period->period_name ?? $period->name ?? '';
        $companyId = (int) $period->id_companies;

        $slips = PayrollSlip::where('id_companies', $companyId)
            ->when($periodName, fn ($q) => $q->where('period_name', $periodName))
            ->get();

        if ($slips->isEmpty()) {
            throw new PayrollException('Tidak ada slip gaji dalam periode ini. Jalankan kalkulasi terlebih dahulu.', 422);
        }

        $count = 0;
        foreach ($slips as $slip) {
            $this->generateSlipPdf($slip);
            $slip->update(['status' => 'finalized']);
            $count++;
        }

        return $count;
    }
}
