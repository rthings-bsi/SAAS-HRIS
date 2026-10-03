<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Department extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'departments';
    protected $primaryKey = 'id_departments';

    protected $fillable = [
        'id_companies',
        'name',
    ];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'id_departments', 'id_departments');
    }
}
