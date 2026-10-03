<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PayrollPeriod extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'payroll_periods';
    protected $primaryKey = 'id_payroll_periods';

    protected $fillable = [
        'id_companies',
        'name',
        'start_date',
        'end_date',
        'payment_date',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'payment_date' => 'date',
        ];
    }

    public function payrollSlips(): HasMany
    {
        return $this->hasMany(PayrollSlip::class, 'id_payroll_periods', 'id_payroll_periods');
    }
}
