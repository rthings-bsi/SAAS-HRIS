<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PayrollSlip extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'payroll_slips';
    protected $primaryKey = 'id_payroll_slips';

    protected $fillable = [
        'id_companies',
        'id_employees',
        'period_name',
        'start_date',
        'end_date',
        'payment_date',
        'status',
        'basic_salary',
        'allowance_fixed',
        'overtime_pay',
        'deduction_late',
        'deduction_absence',
        'deduction_other',
        'net_salary',
        'pdf_path',
    ];

    protected $appends = [
        'payroll_period',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'payment_date' => 'date',
            'basic_salary' => 'decimal:2',
            'allowance_fixed' => 'decimal:2',
            'overtime_pay' => 'decimal:2',
            'deduction_late' => 'decimal:2',
            'deduction_absence' => 'decimal:2',
            'deduction_other' => 'decimal:2',
            'net_salary' => 'decimal:2',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }

    public function getPayrollPeriodAttribute(): object
    {
        return (object) [
            'id_payroll_periods' => $this->id_payroll_slips,
            'name' => $this->period_name ?? 'Periode Penggajian',
            'start_date' => $this->start_date ? $this->start_date->format('Y-m-d') : null,
            'end_date' => $this->end_date ? $this->end_date->format('Y-m-d') : null,
            'payment_date' => $this->payment_date ? $this->payment_date->format('Y-m-d') : null,
            'status' => $this->status ?? 'paid',
        ];
    }
}
