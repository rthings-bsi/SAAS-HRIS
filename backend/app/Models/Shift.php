<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Shift extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'shifts';
    protected $primaryKey = 'id_shifts';

    protected $fillable = [
        'id_companies',
        'name',
        'start_time',
        'end_time',
        'late_tolerance_minutes',
    ];

    protected function casts(): array
    {
        return [
            'late_tolerance_minutes' => 'integer',
        ];
    }

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'id_shifts', 'id_shifts');
    }
}
