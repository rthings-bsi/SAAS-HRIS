<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class JobPosition extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'job_positions';
    protected $primaryKey = 'id_job_positions';

    protected $fillable = [
        'id_companies',
        'name',
    ];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'id_job_positions', 'id_job_positions');
    }
}
