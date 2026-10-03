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
        'id_payroll_periods',
        'id_employees',
        'basic_salary',
        'allowance_fixed',
        'overtime_pay',
        'deduction_late',
        'deduction_absence',
        'deduction_other',
        'net_salary',
        'pdf_path',
    ];

    protected function casts(): array
    {
        return [
            'basic_salary' => 'decimal:2',
            'allowance_fixed' => 'decimal:2',
            'overtime_pay' => 'decimal:2',
            'deduction_late' => 'decimal:2',
            'deduction_absence' => 'decimal:2',
            'deduction_other' => 'decimal:2',
            'net_salary' => 'decimal:2',
        ];
    }

    public function payrollPeriod(): BelongsTo
    {
        return $this->belongsTo(PayrollPeriod::class, 'id_payroll_periods', 'id_payroll_periods');
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'id_employees', 'id_employees');
    }
}
